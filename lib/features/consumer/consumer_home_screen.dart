import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/consumer_service.dart';
import '../../services/farm_browse_service.dart';
import '../../services/cart_service.dart';
import '../../models/farm_summary.dart';
import '../auth/login_screen.dart';
import 'cart_screen.dart';
import 'farm_products_screen.dart';

class ConsumerHomeScreen extends StatefulWidget {
  const ConsumerHomeScreen({super.key});

  @override
  State<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends State<ConsumerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  late final String _consumerId;
  late final Future<Map<String, dynamic>?> _consumerProfileFuture;

  // Pagination
  static const int _itemsPerPage = 5;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    _consumerId = AuthService().currentUser!.uid;

    _consumerProfileFuture =
        ConsumerService().getConsumerProfile(_consumerId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(),
      ),
      (route) => false,
    );
  }

  void _updateSearch(String value) {
    setState(() {
      _searchQuery = value;

      // Return to first page whenever the search changes.
      _currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Farmlink",
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CartScreen(),
                    ),
                  );

                  if (mounted) {
                    setState(() {});
                  }
                },
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.black,
                ),
              ),

              if (CartService().itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${CartService().itemCount}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(
              Icons.logout,
              color: Colors.black,
            ),
          ),
        ],
      ),

      body: FutureBuilder<Map<String, dynamic>?>(
        future: _consumerProfileFuture,
        builder: (context, profileSnapshot) {
          final consumerData = profileSnapshot.data;

          final consumerLat =
              (consumerData?['latitude'] as num?)?.toDouble();

          final consumerLng =
              (consumerData?['longitude'] as num?)?.toDouble();

          return Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Farms near you",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (consumerLat == null || consumerLng == null) ...[
                  const SizedBox(height: 8),

                  const Text(
                    "Your location isn't set, so distances can't be shown. "
                    "Ask support to update your location.",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 13,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                TextField(
                  controller: _searchController,

                  onChanged: _updateSearch,

                  decoration: InputDecoration(
                    hintText: "Search farms...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: StreamBuilder<List<FarmSummary>>(
                    stream: FarmBrowseService().nearbyFarmsStream(
                      consumerLat: consumerLat,
                      consumerLng: consumerLng,
                    ),

                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Could not load farms.\n${snapshot.error}",
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final allFarms = snapshot.data ?? [];

                      final filtered = _searchQuery.isEmpty
                          ? allFarms
                          : allFarms
                              .where(
                                (f) => f.farmName
                                    .toLowerCase()
                                    .contains(
                                      _searchQuery.toLowerCase(),
                                    ),
                              )
                              .toList();

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text(
                            "No farms with products available right now.",
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      // Calculate total pages.
                      final totalPages =
                          (filtered.length / _itemsPerPage).ceil();

                      // Make sure the current page is valid.
                      if (_currentPage >= totalPages) {
                        _currentPage = totalPages - 1;
                      }

                      // Start and end positions for this page.
                      final startIndex =
                          _currentPage * _itemsPerPage;

                      final endIndex = (startIndex + _itemsPerPage)
                          .clamp(0, filtered.length);

                      final pageFarms =
                          filtered.sublist(startIndex, endIndex);

                      return Column(
                        children: [
                          // FARM CARDS
                          Expanded(
                            child: ListView.builder(
                              itemCount: pageFarms.length,

                              itemBuilder: (context, index) {
                                final farm = pageFarms[index];

                                return Card(
                                  margin: const EdgeInsets.only(
                                    bottom: 12,
                                  ),

                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.all(12),

                                    leading: CircleAvatar(
                                      radius: 26,

                                      backgroundColor:
                                          Colors.green.withValues(
                                        alpha: 0.15,
                                      ),

                                      child: const Icon(
                                        Icons.agriculture,
                                        color: Colors.green,
                                      ),
                                    ),

                                    title: Text(
                                      farm.farmName,

                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    subtitle: Text(
                                      farm.distanceKm != null
                                          ? "${farm.distanceKm!.toStringAsFixed(1)} km away · "
                                            "${farm.productCount} products"
                                          : "Distance unknown · "
                                            "${farm.productCount} products",
                                    ),

                                    trailing: const Icon(
                                      Icons.chevron_right,
                                    ),

                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              FarmProductsScreen(
                                            farmerId:
                                                farm.farmerId,
                                            farmName:
                                                farm.farmName,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 10),

                          // PAGINATION CONTROLS
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              // PREVIOUS BUTTON
                              IconButton(
                                onPressed: _currentPage > 0
                                    ? () {
                                        setState(() {
                                          _currentPage--;
                                        });
                                      }
                                    : null,

                                icon: const Icon(
                                  Icons.chevron_left,
                                ),

                                tooltip: "Previous page",
                              ),

                              const SizedBox(width: 10),

                              // PAGE NUMBER
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),

                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),

                                child: Text(
                                  "Page ${_currentPage + 1} of $totalPages",

                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              // NEXT BUTTON
                              IconButton(
                                onPressed:
                                    _currentPage < totalPages - 1
                                        ? () {
                                            setState(() {
                                              _currentPage++;
                                            });
                                          }
                                        : null,

                                icon: const Icon(
                                  Icons.chevron_right,
                                ),

                                tooltip: "Next page",
                              ),
                            ],
                          ),

                          const SizedBox(height: 5),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
