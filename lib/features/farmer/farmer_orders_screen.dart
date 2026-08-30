import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/order_service.dart';
import '../../services/rider_service.dart';
import '../../models/order_model.dart';

class FarmerOrdersScreen extends StatefulWidget {
  final String farmerId;

  const FarmerOrdersScreen({
    super.key,
    required this.farmerId,
  });

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen> {
  int _currentPage = 0;
  static const int _perPage = 3;

  final RiderService _riderService = RiderService();

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

  String _statusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return "PENDING";

      case OrderStatus.accepted:
        return "ACCEPTED";

      case OrderStatus.inTransit:
        return "IN TRANSIT";

      case OrderStatus.delivered:
        return "DELIVERED";

      case OrderStatus.cancelled:
        return "CANCELLED";
    }
  }

  Future<Map<String, dynamic>?> _getRiderProfile(
    String? riderId,
  ) async {
    if (riderId == null || riderId.isEmpty) {
      return null;
    }

    try {
      return await _riderService.getRiderProfile(riderId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Orders"),
      ),
      body: StreamBuilder<List<FarmOrder>>(
        stream: OrderService().farmerOrdersStream(widget.farmerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Could not load orders.\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Text(
                "No orders yet.",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            );
          }

          orders.sort(
            (a, b) => (b.createdAt ?? DateTime(0))
                .compareTo(a.createdAt ?? DateTime(0)),
          );

          final totalPages = (orders.length / _perPage).ceil();

          if (_currentPage >= totalPages) {
            _currentPage = totalPages - 1;
          }

          if (_currentPage < 0) {
            _currentPage = 0;
          }

          final startIndex = _currentPage * _perPage;

          final endIndex =
              (startIndex + _perPage) > orders.length
                  ? orders.length
                  : startIndex + _perPage;

          final pageOrders = orders.sublist(
            startIndex,
            endIndex,
          );

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pageOrders.length,
                  itemBuilder: (context, index) {
                    final order = pageOrders[index];

                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // ==============================
                            // CONSUMER
                            // ==============================
                            Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      Color(0xFFE8F5E9),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.green,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Consumer",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        order.consumerName.isNotEmpty
                                            ? order.consumerName
                                            : "Consumer",
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // ORDER STATUS
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      order.status,
                                    ).withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(
                                      20,
                                    ),
                                  ),
                                  child: Text(
                                    _statusText(order.status),
                                    style: TextStyle(
                                      color: _statusColor(
                                        order.status,
                                      ),
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Divider(height: 24),

                            // ==============================
                            // RIDER DETAILS
                            // ==============================
                            if (order.riderId != null &&
                                order.riderId!.isNotEmpty)
                              FutureBuilder<
                                  Map<String, dynamic>?>(
                                future: _getRiderProfile(
                                  order.riderId,
                                ),
                                builder:
                                    (context, riderSnapshot) {
                                  if (riderSnapshot
                                          .connectionState ==
                                      ConnectionState.waiting) {
                                    return Container(
                                      width: double.infinity,
                                      padding:
                                          const EdgeInsets.all(
                                        12,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color: Colors.blue
                                            .withValues(
                                          alpha: 0.06,
                                        ),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          12,
                                        ),
                                      ),
                                      child: const Row(
                                        children: [
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "Loading rider details...",
                                            style: TextStyle(
                                              color:
                                                  Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final rider =
                                      riderSnapshot.data;

                                  if (rider == null) {
                                    return Container(
                                      width: double.infinity,
                                      padding:
                                          const EdgeInsets.all(
                                        12,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color: Colors.grey
                                            .withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          12,
                                        ),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons
                                                .delivery_dining,
                                            color:
                                                Colors.grey,
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              "Rider details unavailable.",
                                              style:
                                                  TextStyle(
                                                color:
                                                    Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final riderName =
                                      rider['fullName'] ??
                                          rider['name'] ??
                                          'Rider';

                                  final riderPhone =
                                      rider['phone'] ??
                                          rider['phoneNumber'] ??
                                          '';

                                  return Container(
                                    width: double.infinity,
                                    padding:
                                        const EdgeInsets.all(
                                      12,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: Colors.blue
                                          .withValues(
                                        alpha: 0.07,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(
                                        12,
                                      ),
                                      border: Border.all(
                                        color: Colors.blue
                                            .withValues(
                                          alpha: 0.15,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons
                                                  .delivery_dining,
                                              color:
                                                  Colors.blue,
                                              size: 22,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "Assigned Rider",
                                              style:
                                                  TextStyle(
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                                color:
                                                    Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(
                                            height: 10),

                                        // Rider name
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.person,
                                              size: 18,
                                              color:
                                                  Colors.grey,
                                            ),
                                            const SizedBox(
                                                width: 8),
                                            Expanded(
                                              child: Text(
                                                riderName
                                                    .toString(),
                                                style:
                                                    const TextStyle(
                                                  fontWeight:
                                                      FontWeight
                                                          .w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Rider phone
                                        if (riderPhone
                                            .toString()
                                            .isNotEmpty) ...[
                                          const SizedBox(
                                              height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.phone,
                                                size: 18,
                                                color:
                                                    Colors.grey,
                                              ),
                                              const SizedBox(
                                                  width: 8),
                                              Text(
                                                riderPhone
                                                    .toString(),
                                                style:
                                                    const TextStyle(
                                                  color:
                                                      Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange
                                      .withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                    12,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .delivery_dining,
                                      color:
                                          Colors.orange,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "No rider assigned yet.",
                                        style: TextStyle(
                                          color:
                                              Colors.orange,
                                          fontWeight:
                                              FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 16),

                            // ==============================
                            // ORDER ITEMS
                            // ==============================
                            const Text(
                              "Order Items",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 8),

                            ConstrainedBox(
                              constraints:
                                  const BoxConstraints(
                                maxHeight: 120,
                              ),
                              child:
                                  SingleChildScrollView(
                                child: Column(
                                  children: order.items
                                      .map(
                                        (item) => Padding(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            vertical: 3,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  "${item.name} × ${item.quantity} ${item.unit}",
                                                  overflow:
                                                      TextOverflow
                                                          .ellipsis,
                                                ),
                                              ),
                                              const SizedBox(
                                                  width: 10),
                                              Text(
                                                "KES ${item.farmerEarnings.toStringAsFixed(0)}",
                                                style:
                                                    const TextStyle(
                                                  fontWeight:
                                                      FontWeight
                                                          .w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),

                            const Divider(height: 20),

                            // ==============================
                            // FARMER EARNINGS
                            // ==============================
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                              children: [
                                const Text(
                                  "You earn",
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "KES ${order.farmerEarnings.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    color:
                                        AppColors.primary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ==============================
              // PAGINATION
              // ==============================
              if (totalPages > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _currentPage > 0
                            ? () => setState(
                                  () => _currentPage--,
                                )
                            : null,
                        icon: const Icon(
                          Icons.chevron_left,
                        ),
                      ),

                      Text(
                        "Page ${_currentPage + 1} of $totalPages",
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      IconButton(
                        onPressed:
                            _currentPage < totalPages - 1
                                ? () => setState(
                                      () => _currentPage++,
                                    )
                                : null,
                        icon: const Icon(
                          Icons.chevron_right,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
