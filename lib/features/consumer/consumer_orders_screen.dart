import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/order_service.dart';
import '../../services/farmer_service.dart';
import '../../services/rider_service.dart';
import '../../models/order_model.dart';

class ConsumerOrdersScreen extends StatefulWidget {
  final String consumerId;

  const ConsumerOrdersScreen({
    super.key,
    required this.consumerId,
  });

  @override
  State<ConsumerOrdersScreen> createState() =>
      _ConsumerOrdersScreenState();
}

class _ConsumerOrdersScreenState
    extends State<ConsumerOrdersScreen> {
  int _currentPage = 0;

  static const int _perPage = 3;

  // ================================================================
  // STATUS COLOR
  // ================================================================

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;

      case OrderStatus.accepted:
        return Colors.blue;

      case OrderStatus.inTransit:
        return Colors.purple;

      case OrderStatus.delivered:
        return Colors.green;

      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  // ================================================================
  // STATUS ICON
  // ================================================================

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_empty;

      case OrderStatus.accepted:
        return Icons.check_circle_outline;

      case OrderStatus.inTransit:
        return Icons.local_shipping_outlined;

      case OrderStatus.delivered:
        return Icons.done_all;

      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  // ================================================================
  // DASHBOARD SUMMARY CARD
  // ================================================================

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 23,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ORDER CARD
  // ================================================================

  Widget _buildOrderCard(FarmOrder order) {
    final statusColor = _statusColor(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========================================================
            // FARM + STATUS
            // ========================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.agriculture,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: FarmerService()
                        .getFarmerProfile(order.farmerId),
                    builder: (context, farmSnap) {
                      final farmName =
                          farmSnap.data?['farmName'] ?? 'Farm';

                      return Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            farmName.toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 3),

                          const Text(
                            "Farm order",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(order.status),
                        color: statusColor,
                        size: 14,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        order.status.name.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            const Divider(height: 1),

            const SizedBox(height: 12),

            // ========================================================
            // ITEMS
            // ========================================================

            const Text(
              "Items",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 8),

            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 120,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: order.items.map(
                    (item) {
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${item.name} × ${item.quantity} ${item.unit}",
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            Text(
                              "KES ${item.subtotal.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Divider(height: 1),

            const SizedBox(height: 10),

            // ========================================================
            // DELIVERY + TOTAL
            // ========================================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Delivery",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                Text(
                  "KES ${order.deliveryCharge.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                Text(
                  "KES ${order.totalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 17,
                  ),
                ),
              ],
            ),

            // ========================================================
            // RIDER INFORMATION
            // ========================================================

            if (order.riderId != null &&
                (order.status == OrderStatus.accepted ||
                    order.status ==
                        OrderStatus.inTransit)) ...[
              const SizedBox(height: 14),

              const Divider(height: 1),

              const SizedBox(height: 12),

              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary
                          .withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delivery_dining,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: FutureBuilder<
                        Map<String, dynamic>?>(
                      future: RiderService()
                          .getRiderProfile(
                              order.riderId!),
                      builder: (
                        context,
                        riderSnap,
                      ) {
                        if (!riderSnap.hasData) {
                          return const Text(
                            "Rider assigned",
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          );
                        }

                        final rider =
                            riderSnap.data;

                        return Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              rider?['fullName'] ??
                                  'Rider assigned',
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              rider?['phone'] ?? '',
                              style:
                                  const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ======================================================
              // PIN CODE
              // ======================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary
                        .withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),

                    const SizedBox(width: 10),

                    const Expanded(
                      child: Text(
                        "Give this code to your rider",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ),

                    Text(
                      order.pinCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // ==============================================================
      // APP BAR
      // ==============================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          "My Orders",
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),

        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),

      // ==============================================================
      // BODY
      // ==============================================================

      body: StreamBuilder<List<FarmOrder>>(
        stream: OrderService()
            .consumerOrdersStream(widget.consumerId),

        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Could not load your orders.\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            );
          }

          final orders =
              List<FarmOrder>.from(
            snapshot.data ?? [],
          );

          // ==========================================================
          // NO ORDERS
          // ==========================================================

          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 12),

                  Text(
                    "No orders yet.",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: 4),

                  Text(
                    "Your orders will appear here.",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          // ==========================================================
          // SORT
          // ==========================================================

          orders.sort(
            (a, b) => (b.createdAt ?? DateTime(0))
                .compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );

          // ==========================================================
          // DASHBOARD COUNTS
          // ==========================================================

          final totalOrders = orders.length;

          final pendingOrders = orders.where(
            (order) =>
                order.status == OrderStatus.pending ||
                order.status == OrderStatus.accepted ||
                order.status == OrderStatus.inTransit,
          ).length;

          final deliveredOrders = orders.where(
            (order) =>
                order.status ==
                OrderStatus.delivered,
          ).length;

          final cancelledOrders = orders.where(
            (order) =>
                order.status ==
                OrderStatus.cancelled,
          ).length;

          // ==========================================================
          // PAGINATION
          // ==========================================================

          final totalPages =
              (orders.length / _perPage).ceil();

          if (_currentPage >= totalPages) {
            _currentPage = totalPages - 1;
          }

          if (_currentPage < 0) {
            _currentPage = 0;
          }

          final startIndex =
              _currentPage * _perPage;

          final endIndex =
              (startIndex + _perPage) >
                      orders.length
                  ? orders.length
                  : startIndex + _perPage;

          final pageOrders =
              orders.sublist(
            startIndex,
            endIndex,
          );

          // ==========================================================
          // CONTENT
          // ==========================================================

          return ListView(
            padding: const EdgeInsets.all(16),

            children: [
              // ========================================================
              // HEADER
              // ========================================================

              const Text(
                "Your Dashboard",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // ========================================================
              // SUMMARY CARDS
              // ========================================================

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,

                children: [
                  _summaryCard(
                    title: "Total Orders",
                    value: "$totalOrders",
                    subtitle: "All orders",
                    icon:
                        Icons.receipt_long_outlined,
                    color: Colors.blue,
                  ),

                  _summaryCard(
                    title: "Active Orders",
                    value: "$pendingOrders",
                    subtitle: "In progress",
                    icon:
                        Icons.local_shipping_outlined,
                    color: Colors.orange,
                  ),

                  _summaryCard(
                    title: "Delivered",
                    value: "$deliveredOrders",
                    subtitle: "Completed",
                    icon:
                        Icons.check_circle_outline,
                    color: Colors.green,
                  ),

                  _summaryCard(
                    title: "Cancelled",
                    value: "$cancelledOrders",
                    subtitle: "Cancelled orders",
                    icon:
                        Icons.cancel_outlined,
                    color: Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ========================================================
              // ORDERS TITLE
              // ========================================================

              const Text(
                "Recent Orders",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // ========================================================
              // ORDERS
              // ========================================================

              ...pageOrders.map(
                (order) => _buildOrderCard(order),
              ),

              // ========================================================
              // PAGINATION
              // ========================================================

              if (totalPages > 1)
                Container(
                  margin:
                      const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed:
                            _currentPage > 0
                                ? () {
                                    setState(() {
                                      _currentPage--;
                                    });
                                  }
                                : null,
                        icon: const Icon(
                          Icons.chevron_left,
                        ),
                      ),

                      Text(
                        "Page ${_currentPage + 1} of $totalPages",
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),

                      IconButton(
                        onPressed:
                            _currentPage <
                                    totalPages - 1
                                ? () {
                                    setState(() {
                                      _currentPage++;
                                    });
                                  }
                                : null,
                        icon: const Icon(
                          Icons.chevron_right,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}
