import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../services/farmer_service.dart';
import '../../services/order_service.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../auth/login_screen.dart';
import 'add_edit_product_screen.dart';
import 'farmer_orders_screen.dart';
import 'dart:async';

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _perPage = 3;

  late final Future<Map<String, dynamic>?> _profileFuture;
  late final Stream<List<Product>> _productsStream;
  late final Stream<List<FarmOrder>> _ordersStream;
  late final String _farmerId;

  // Watches order status changes so the farmer can be notified
  // when one of their orders is delivered.
  StreamSubscription<List<FarmOrder>>? _orderWatcherSub;
  final Map<String, OrderStatus> _previousOrderStatus = {};
  final Map<String, bool> _previousPaidOut = {};
  bool _firstOrderLoad = true;

  @override
  void initState() {
    super.initState();

    _farmerId = AuthService().currentUser!.uid;
    _profileFuture = FarmerService().getFarmerProfile(_farmerId);
    _productsStream = ProductService().farmerProductsStream(_farmerId);
    _ordersStream = OrderService().farmerOrdersStream(_farmerId);

    _orderWatcherSub = OrderService()
        .farmerOrdersStream(_farmerId)
        .listen(_handleOrderUpdates);
  }

  void _handleOrderUpdates(List<FarmOrder> orders) {
    for (final order in orders) {
      final prevStatus = _previousOrderStatus[order.id];
      final prevPaidOut = _previousPaidOut[order.id];

      if (!_firstOrderLoad &&
          prevStatus != null &&
          prevStatus != OrderStatus.delivered &&
          order.status == OrderStatus.delivered) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Order for ${order.consumerName} was delivered! ✅"),
              backgroundColor: Colors.green,
            ),
          );
        });
      }

      if (!_firstOrderLoad && prevPaidOut == false && order.isPaidOut == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Payment submitted by Admin for ${order.consumerName}'s order.",
              ),
              backgroundColor: Colors.blue,
            ),
          );
        });
      }

      _previousOrderStatus[order.id] = order.status;
      _previousPaidOut[order.id] = order.isPaidOut;
    }

    _firstOrderLoad = false;
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _orderWatcherSub?.cancel();
    _searchController.dispose();
    super.dispose();
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
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FarmerOrdersScreen(farmerId: _farmerId),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long, color: Colors.black),
          ),
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.black),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditProductScreen(farmerId: _farmerId),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, profileSnapshot) {
          final profile = profileSnapshot.data;
          final farmerName = profile?['fullName'] ?? '';
          final farmName = profile?['farmName'] ?? '';

          return StreamBuilder<List<FarmOrder>>(
            stream: _ordersStream,
            builder: (context, orderSnapshot) {
              final orders = orderSnapshot.data ?? [];

              final deliveredOrders = orders
                  .where((o) => o.status == OrderStatus.delivered)
                  .toList();

              final uniqueClients = deliveredOrders
                  .map((o) => o.consumerId)
                  .toSet()
                  .length;

              final totalSold = deliveredOrders.fold<double>(
                0,
                (sum, o) => sum + o.farmerEarnings,
              );

              return StreamBuilder<List<Product>>(
                stream: _productsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allProducts = snapshot.data ?? [];
                  final totalProducts = allProducts.length;

                  final totalStock = allProducts.fold<int>(
                    0,
                    (sum, p) => sum + p.stockQuantity,
                  );

                  final activeListings = allProducts
                      .where((p) => p.isActive)
                      .length;

                  final inventoryValue = allProducts.fold<double>(
                    0,
                    (sum, p) => sum + (p.farmerPrice * p.stockQuantity),
                  );

                  final filteredProducts = _searchQuery.isEmpty
                      ? allProducts
                      : allProducts
                            .where(
                              (p) => p.name.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                            )
                            .toList();

                  final totalPages = filteredProducts.isEmpty
                      ? 1
                      : (filteredProducts.length / _perPage).ceil();

                  if (_currentPage >= totalPages) {
                    _currentPage = totalPages - 1;
                  }

                  if (_currentPage < 0) {
                    _currentPage = 0;
                  }

                  final startIndex = _currentPage * _perPage;

                  final endIndex =
                      (startIndex + _perPage) > filteredProducts.length
                      ? filteredProducts.length
                      : startIndex + _perPage;

                  final pageProducts = filteredProducts.sublist(
                    startIndex,
                    endIndex,
                  );

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              farmerName.isNotEmpty
                                  ? "Welcome back, $farmerName 🌱"
                                  : "Welcome back 🌱",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),

                            if (farmName.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                farmName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _StatBlock(
                                  label: "Products",
                                  value: "$totalProducts",
                                ),
                                _StatBlock(
                                  label: "Active",
                                  value: "$activeListings",
                                ),
                                _StatBlock(
                                  label: "Stock",
                                  value: "$totalStock",
                                ),
                                _StatBlock(
                                  label: "Clients",
                                  value: "$uniqueClients",
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Total Sold",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        "KES ${totalSold.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Potential Inventory Value",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        "KES ${inventoryValue.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        "Your Products",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _currentPage = 0;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Search your products...",
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                      _currentPage = 0;
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (filteredProducts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              allProducts.isEmpty
                                  ? "You haven't listed any products yet.\nTap + to add your first one."
                                  : "No products match \"$_searchQuery\".",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else ...[
                        ...pageProducts.map(
                          (product) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.green.withValues(
                                  alpha: 0.15,
                                ),
                                backgroundImage: product.imageUrl != null
                                    ? NetworkImage(product.imageUrl!)
                                    : null,
                                child: product.imageUrl == null
                                    ? const Icon(Icons.eco, color: Colors.green)
                                    : null,
                              ),
                              title: Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                product.stockQuantity <= 0
                                    ? "KES ${product.farmerPrice.toStringAsFixed(0)} / ${product.unit} · OUT OF STOCK"
                                    : "KES ${product.farmerPrice.toStringAsFixed(0)} / ${product.unit} · Stock: ${product.stockQuantity}",
                                style: product.stockQuantity <= 0
                                    ? const TextStyle(color: Colors.red)
                                    : null,
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddEditProductScreen(
                                      farmerId: _farmerId,
                                      existingProduct: product,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        if (totalPages > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: _currentPage > 0
                                    ? () => setState(() => _currentPage--)
                                    : null,
                                icon: const Icon(Icons.chevron_left),
                              ),

                              Text(
                                "Page ${_currentPage + 1} of $totalPages",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              IconButton(
                                onPressed: _currentPage < totalPages - 1
                                    ? () => setState(() => _currentPage++)
                                    : null,
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                      ],
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;

  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
