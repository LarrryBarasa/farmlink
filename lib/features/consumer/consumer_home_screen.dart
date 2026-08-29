import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/consumer_service.dart';
import '../../services/farm_browse_service.dart';
import '../../services/cart_service.dart';

import '../../models/farm_summary.dart';

import '../auth/login_screen.dart';

import 'cart_screen.dart';
import 'farm_products_screen.dart';
import 'consumer_orders_screen.dart';

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

  // ------------------------------------------------------------
  // PAGINATION
  // ------------------------------------------------------------

  static const int _itemsPerPage = 5;

  int _currentPage = 0;

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _consumerId = AuthService().currentUser!.uid;

    _consumerProfileFuture =
        ConsumerService().getConsumerProfile(_consumerId);
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------------

  void _updateSearch(String value) {
    setState(() {
      _searchQuery = value;

      // Whenever the search changes,
      // return to the first page.
      _currentPage = 0;
    });
  }

  // ------------------------------------------------------------
  // OPEN ORDERS
  // ------------------------------------------------------------

  void _openOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsumerOrdersScreen(
          consumerId: _consumerId,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // OPEN CART
  // ------------------------------------------------------------

  Future<void> _openCart() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CartScreen(),
      ),
    );

    // Refresh cart badge when returning.
    if (mounted) {
      setState(() {});
    }
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // ==========================================================
      // APP BAR
      // ==========================================================

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
          // ======================================================
          // ORDERS BUTTON
          // ======================================================

          IconButton(
            onPressed: _openOrders,
            icon: const Icon(
              Icons.receipt_long,
              color: Colors.black,
            ),
            tooltip: "My Orders",
          ),

          // ======================================================
          // CART BUTTON
          // ======================================================

          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: _openCart,
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.black,
                ),
                tooltip: "Cart",
              ),

              // Cart item count badge
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ======================================================
          // LOGOUT BUTTON
          // ======================================================

          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(
              Icons.logout,
              color: Colors.black,
            ),
            tooltip: "Logout",
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: FutureBuilder<Map<String, dynamic>?>(
        future: _consumerProfileFuture,

        builder: (context, profileSnapshot) {
          final consumerData = profileSnapshot.data;

          // Get consumer latitude.
          final consumerLat =
              (consumerData?['latitude'] as num?)?.toDouble();

          // Get consumer longitude.
          final consumerLng =
              (consumerData?['longitude'] as num?)?.toDouble();

          return Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==================================================
                // PAGE TITLE
                // ==================================================

                const Text(
                  "Farms near you",

                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // ==================================================
                // LOCATION WARNING
                // ==================================================

                if (consumerLat == null || consumerLng == null) ...[
                  const SizedBox(height: 8),

                  const Text(
                    "Your location isn't set, so distances can't be "
                    "shown. Ask support to update your location.",

                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 13,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // ==================================================
                // SEARCH BAR
                // ==================================================

                TextField(
                  controller: _searchController,

                  onChanged: _updateSearch,

                  decoration: InputDecoration(
                    hintText: "Search farms...",

                    prefixIcon: const Icon(
                      Icons.search,
                    ),

                    filled: true,

                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),

                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // FARMS
                // ==================================================

                Expanded(
                  child: StreamBuilder<List<FarmSummary>>(
                    stream: FarmBrowseService().nearbyFarmsStream(
                      consumerLat: consumerLat,
                      consumerLng: consumerLng,
                    ),

                    builder: (context, snapshot) {
                      // ------------------------------------------------
                      // LOADING
                      // ------------------------------------------------

                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      // ------------------------------------------------
                      // ERROR
                      // ------------------------------------------------

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),

                            child: Text(
                              "Could not load farms.\n\n"
                              "${snapshot.error}",

                              textAlign: TextAlign.center,

                              style: const TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        );
                      }

                      // ------------------------------------------------
                      // ALL FARMS
                      // ------------------------------------------------

                      final allFarms = snapshot.data ?? [];

                      // ------------------------------------------------
                      // FILTER FARMS BY SEARCH
                      // ------------------------------------------------

                      final filtered = _searchQuery.isEmpty
                          ? allFarms
                          : allFarms
                              .where(
                                (farm) => farm.farmName
                                    .toLowerCase()
                                    .contains(
                                      _searchQuery.toLowerCase(),
                                    ),
                              )
                              .toList();

                      // ------------------------------------------------
                      // NO FARMS
                      // ------------------------------------------------

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

                      // ------------------------------------------------
                      // TOTAL PAGES
                      // ------------------------------------------------

                      final totalPages =
                          (filtered.length / _itemsPerPage).ceil();

                      // Make sure current page remains valid.
                      if (_currentPage >= totalPages) {
                        _currentPage = totalPages - 1;
                      }

                      // ------------------------------------------------
                      // PAGE START
                      // ------------------------------------------------

                      final startIndex =
                          _currentPage * _itemsPerPage;

                      // ------------------------------------------------
                      // PAGE END
                      // ------------------------------------------------

                      final endIndex =
                          (startIndex + _itemsPerPage)
                              .clamp(0, filtered.length);

                      // ------------------------------------------------
                      // FARMS FOR CURRENT PAGE
                      // ------------------------------------------------

                      final pageFarms = filtered.sublist(
                        startIndex,
                        endIndex,
                      );

                      // =================================================
                      // PAGE CONTENT
                      // =================================================

                      return Column(
                        children: [
                          // =============================================
                          // FARM CARDS
                          // =============================================

                          Expanded(
                            child: ListView.builder(
                              itemCount: pageFarms.length,

                              itemBuilder: (context, index) {
                                final farm = pageFarms[index];

                                return Card(
                                  margin: const EdgeInsets.only(
                                    bottom: 12,
                                  ),

                                  elevation: 1,

                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),

                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.all(12),

                                    // ---------------------------------
                                    // FARM ICON
                                    // ---------------------------------

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

                                    // ---------------------------------
                                    // FARM NAME
                                    // ---------------------------------

                                    title: Text(
                                      farm.farmName,

                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),

                                    // ---------------------------------
                                    // FARM DISTANCE + PRODUCTS
                                    // ---------------------------------

                                    subtitle: Padding(
                                      padding:
                                          const EdgeInsets.only(top: 5),

                                      child: Text(
                                        farm.distanceKm != null
                                            ? "${farm.distanceKm!.toStringAsFixed(1)} "
                                              "km away · "
                                              "${farm.productCount} products"
                                            : "Distance unknown · "
                                              "${farm.productCount} products",
                                      ),
                                    ),

                                    // ---------------------------------
                                    // ARROW
                                    // ---------------------------------

                                    trailing: const Icon(
                                      Icons.chevron_right,
                                    ),

                                    // ---------------------------------
                                    // OPEN FARM
                                    // ---------------------------------

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

                          // =============================================
                          // PAGINATION
                          // =============================================

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,

                            children: [
                              // -----------------------------------------
                              // PREVIOUS
                              // -----------------------------------------

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

                              // -----------------------------------------
                              // PAGE NUMBER
                              // -----------------------------------------

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
                                  "Page ${_currentPage + 1} "
                                  "of $totalPages",

                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              // -----------------------------------------
                              // NEXT
                              // -----------------------------------------

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
