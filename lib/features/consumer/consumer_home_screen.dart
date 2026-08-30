import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/consumer_service.dart';
import '../../services/farm_browse_service.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../services/rider_service.dart';
import '../../models/farm_summary.dart';
import '../../models/order_model.dart';
import '../auth/login_screen.dart';
import 'cart_screen.dart';
import 'farm_products_screen.dart';
import 'consumer_orders_screen.dart';

class ConsumerHomeScreen extends StatefulWidget {
  const ConsumerHomeScreen({
    super.key,
  });

  @override
  State<ConsumerHomeScreen> createState() =>
      _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState
    extends State<ConsumerHomeScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  late final String _consumerId;

  late final Future<Map<String, dynamic>?>
      _consumerProfileFuture;

  StreamSubscription<List<FarmOrder>>?
      _orderSub;

  StreamSubscription<void>? _cartSub;

  final Map<String, OrderStatus>
      _previousStatus = {};

  bool _firstOrderLoad = true;

  // ================================================================
  // INIT
  // ================================================================

  @override
  void initState() {
    super.initState();

    final currentUser =
        AuthService().currentUser;

    if (currentUser == null) {
      return;
    }

    _consumerId = currentUser.uid;

    _consumerProfileFuture =
        ConsumerService()
            .getConsumerProfile(
      _consumerId,
    );

    // ==============================================================
    // ORDER LISTENER
    // ==============================================================

    _orderSub = OrderService()
        .consumerOrdersStream(
      _consumerId,
    )
        .listen(
      _handleOrderUpdates,
    );

    // ==============================================================
    // CART LISTENER
    // ==============================================================

    _cartSub = CartService()
        .changes
        .listen((_) {
      if (!mounted) return;

      setState(() {});
    });
  }

  // ================================================================
  // ORDER UPDATES
  // ================================================================

  void _handleOrderUpdates(
    List<FarmOrder> orders,
  ) {
    for (final order in orders) {
      final previous =
          _previousStatus[order.id];

      if (!_firstOrderLoad &&
          previous != null &&
          previous != order.status) {
        if (order.status ==
                OrderStatus.accepted &&
            order.riderId != null) {
          _showRiderAssignedDialog(order);
        } else if (order.status ==
            OrderStatus.delivered) {
          _showDeliveredDialog();
        }
      }

      _previousStatus[order.id] =
          order.status;
    }

    _firstOrderLoad = false;
  }

  // ================================================================
  // RIDER ASSIGNED
  // ================================================================

  Future<void> _showRiderAssignedDialog(
    FarmOrder order,
  ) async {
    final riderProfile =
        await RiderService()
            .getRiderProfile(
      order.riderId!,
    );

    final riderName =
        riderProfile?['fullName'] ??
            'A rider';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Rider Assigned!",
        ),
        content: Text(
          "$riderName has accepted your delivery "
          "and is on the way soon.",
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DELIVERED
  // ================================================================

  void _showDeliveredDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Order Delivered!",
        ),
        content: const Text(
          "Your order has been marked as delivered. "
          "Enjoy!",
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // LOGOUT
  // ================================================================

  Future<void> _logout(
    BuildContext context,
  ) async {
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

  // ================================================================
  // DISPOSE
  // ================================================================

  @override
  void dispose() {
    _orderSub?.cancel();
    _cartSub?.cancel();
    _searchController.dispose();

    super.dispose();
  }

  // ================================================================
  // DASHBOARD
  // ================================================================

  Widget _buildDashboard(
    List<FarmOrder> orders,
    int farmCount,
  ) {
    final activeOrders =
        orders.where(
      (order) =>
          order.status ==
              OrderStatus.pending ||
          order.status ==
              OrderStatus.accepted ||
          order.status ==
              OrderStatus.inTransit,
    ).length;

    final deliveredOrders =
        orders.where(
      (order) =>
          order.status ==
          OrderStatus.delivered,
    ).length;

    final cartItems =
        CartService().itemCount;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          "Your Dashboard",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            _ConsumerDashboardCard(
              title: "Active Orders",
              value: "$activeOrders",
              subtitle: "In progress",
              icon:
                  Icons.local_shipping_outlined,
              color: Colors.orange,
            ),

            _ConsumerDashboardCard(
              title: "Delivered",
              value: "$deliveredOrders",
              subtitle: "Completed orders",
              icon:
                  Icons.check_circle_outline,
              color: Colors.green,
            ),

            _ConsumerDashboardCard(
              title: "Farms Available",
              value: "$farmCount",
              subtitle: "Ready to shop",
              icon: Icons.agriculture,
              color: Colors.blue,
            ),

            _ConsumerDashboardCard(
              title: "Cart Items",
              value: "$cartItems",
              subtitle: "Ready to checkout",
              icon:
                  Icons.shopping_cart_outlined,
              color: Colors.purple,
            ),
          ],
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final cartCount =
        CartService().itemCount;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F5F5),

      // ============================================================
      // APP BAR
      // ============================================================

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
          // ========================================================
          // ORDERS
          // ========================================================

          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ConsumerOrdersScreen(
                    consumerId:
                        _consumerId,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.receipt_long,
              color: Colors.black,
            ),
          ),

          // ========================================================
          // CART
          // ========================================================

          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const CartScreen(),
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

              // ====================================================
              // CART BADGE
              // ====================================================

              if (cartCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    constraints:
                        const BoxConstraints(
                      minWidth: 19,
                      minHeight: 19,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration:
                        const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        cartCount > 99
                            ? "99+"
                            : "$cartCount",
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ========================================================
          // LOGOUT
          // ========================================================

          IconButton(
            onPressed: () =>
                _logout(context),
            icon: const Icon(
              Icons.logout,
              color: Colors.black,
            ),
          ),
        ],
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: FutureBuilder<
          Map<String, dynamic>?>(
        future:
            _consumerProfileFuture,
        builder: (
          context,
          profileSnapshot,
        ) {
          final consumerData =
              profileSnapshot.data;

          // ========================================================
          // GET USERNAME
          // ========================================================

          final username =
              consumerData?['fullName'] ??
                  consumerData?['name'] ??
                  consumerData?['username'] ??
                  'there';

          final consumerLat =
              (consumerData?['latitude']
                      as num?)
                  ?.toDouble();

          final consumerLng =
              (consumerData?['longitude']
                      as num?)
                  ?.toDouble();

          return StreamBuilder<
              List<FarmOrder>>(
            stream: OrderService()
                .consumerOrdersStream(
              _consumerId,
            ),
            builder: (
              context,
              orderSnapshot,
            ) {
              final orders =
                  orderSnapshot.data ??
                      <FarmOrder>[];

              return Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // =================================================
                    // WELCOME
                    // =================================================

                    Text(
                      "Welcome, $username 👋",
                      style:
                          const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // =================================================
                    // FARMS STREAM
                    // =================================================

                    Expanded(
                      child: StreamBuilder<
                          List<FarmSummary>>(
                        stream:
                            FarmBrowseService()
                                .nearbyFarmsStream(
                          consumerLat:
                              consumerLat,
                          consumerLng:
                              consumerLng,
                        ),
                        builder: (
                          context,
                          snapshot,
                        ) {
                          if (snapshot
                                  .connectionState ==
                              ConnectionState
                                  .waiting) {
                            return const Center(
                              child:
                                  CircularProgressIndicator(),
                            );
                          }

                          final allFarms =
                              snapshot.data ??
                                  <FarmSummary>[];

                          final filtered =
                              _searchQuery
                                      .isEmpty
                                  ? allFarms
                                  : allFarms
                                      .where(
                                      (farm) {
                                        return farm
                                            .farmName
                                            .toLowerCase()
                                            .contains(
                                              _searchQuery
                                                  .toLowerCase(),
                                            );
                                      },
                                    )
                                      .toList();

                          return ListView(
                            children: [
                              // =================================================
                              // DASHBOARD
                              // =================================================

                              _buildDashboard(
                                orders,
                                allFarms.length,
                              ),

                              // =================================================
                              // LOCATION WARNING
                              // =================================================

                              if (consumerLat ==
                                      null ||
                                  consumerLng ==
                                      null) ...[
                                Container(
                                  padding:
                                      const EdgeInsets
                                          .all(12),
                                  decoration:
                                      BoxDecoration(
                                    color: Colors
                                        .orange
                                        .withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      12,
                                    ),
                                  ),
                                  child:
                                      const Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Icon(
                                        Icons
                                            .location_off,
                                        color: Colors
                                            .orange,
                                        size: 20,
                                      ),
                                      SizedBox(
                                        width: 8,
                                      ),
                                      Expanded(
                                        child:
                                            Text(
                                          "Your location isn't set, so distances can't be shown. "
                                          "Ask support to update your location.",
                                          style:
                                              TextStyle(
                                            color: Colors
                                                .orange,
                                            fontSize:
                                                13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(
                                  height: 16,
                                ),
                              ],

                              // =================================================
                              // FARMS HEADER
                              // =================================================

                              const Text(
                                "Farms Near You",
                                style:
                                    TextStyle(
                                  fontSize: 22,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              // =================================================
                              // SEARCH
                              // =================================================

                              TextField(
                                controller:
                                    _searchController,
                                onChanged:
                                    (value) {
                                  setState(() {
                                    _searchQuery =
                                        value;
                                  });
                                },
                                decoration:
                                    InputDecoration(
                                  hintText:
                                      "Search farms...",
                                  prefixIcon:
                                      const Icon(
                                    Icons.search,
                                  ),
                                  filled: true,
                                  fillColor:
                                      Colors.white,
                                  border:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      12,
                                    ),
                                    borderSide:
                                        BorderSide
                                            .none,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 16,
                              ),

                              // =================================================
                              // NO FARMS
                              // =================================================

                              if (filtered.isEmpty)
                                const Padding(
                                  padding:
                                      EdgeInsets.only(
                                    top: 40,
                                  ),
                                  child: Center(
                                    child: Text(
                                      "No farms with products available right now.",
                                      textAlign:
                                          TextAlign
                                              .center,
                                      style:
                                          TextStyle(
                                        color:
                                            Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),

                              // =================================================
                              // FARM LIST
                              // =================================================

                              ...filtered.map(
                                (farm) {
                                  return Card(
                                    margin:
                                        const EdgeInsets
                                            .only(
                                      bottom: 12,
                                    ),
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        14,
                                      ),
                                    ),
                                    child:
                                        ListTile(
                                      contentPadding:
                                          const EdgeInsets
                                              .all(
                                        14,
                                      ),
                                      leading:
                                          Container(
                                        width: 48,
                                        height: 48,
                                        decoration:
                                            BoxDecoration(
                                          color: Colors
                                              .green
                                              .withValues(
                                            alpha:
                                                0.12,
                                          ),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            12,
                                          ),
                                        ),
                                        child:
                                            const Icon(
                                          Icons
                                              .agriculture,
                                          color: Colors
                                              .green,
                                          size: 26,
                                        ),
                                      ),
                                      title: Text(
                                        farm.farmName,
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          fontSize:
                                              16,
                                        ),
                                      ),
                                      subtitle:
                                          Padding(
                                        padding:
                                            const EdgeInsets
                                                .only(
                                          top: 4,
                                        ),
                                        child:
                                            Text(
                                          farm.distanceKm !=
                                                  null
                                              ? "${farm.distanceKm!.toStringAsFixed(1)} km away · ${farm.productCount} products"
                                              : "${farm.productCount} products available",
                                        ),
                                      ),
                                      trailing:
                                          Container(
                                        width: 36,
                                        height: 36,
                                        decoration:
                                            BoxDecoration(
                                          color: AppColors
                                              .primary
                                              .withValues(
                                            alpha:
                                                0.1,
                                          ),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            10,
                                          ),
                                        ),
                                        child:
                                            const Icon(
                                          Icons
                                              .chevron_right,
                                          color: AppColors
                                              .primary,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator
                                            .push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
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
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ====================================================================
// CONSUMER DASHBOARD CARD
// ====================================================================

class _ConsumerDashboardCard
    extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ConsumerDashboardCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 8,
            offset:
                const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color:
                  color.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 23,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
