import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/farmer_service.dart';
import '../../models/order_model.dart';

class MyDeliveriesScreen extends StatelessWidget {
  const MyDeliveriesScreen({super.key});

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

  Future<void> _advanceStatus(BuildContext context, FarmOrder order) async {
    OrderStatus next;
    if (order.status == OrderStatus.accepted) {
      next = OrderStatus.inTransit;
    } else if (order.status == OrderStatus.inTransit) {
      next = OrderStatus.delivered;
    } else {
      return;
    }

    try {
      await OrderService().updateOrderStatus(order.id, next);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not update status: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final riderId = AuthService().currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Deliveries")),
      body: StreamBuilder<List<FarmOrder>>(
        stream: OrderService().riderOrdersStream(riderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Text(
                "No deliveries assigned to you yet.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          orders.sort((a, b) =>
              (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              return FutureBuilder<Map<String, dynamic>?>(
                future: FarmerService().getFarmerProfile(order.farmerId),
                builder: (context, farmSnap) {
                  final farmName = farmSnap.data?['farmName'] ?? 'Farm';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Pickup: $farmName",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(order.status)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  order.status.name.toUpperCase(),
                                  style: TextStyle(
                                    color: _statusColor(order.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text("Deliver to: ${order.consumerName}"),
                          Text(order.consumerPhone,
                              style: const TextStyle(color: Colors.grey)),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("You earn"),
                              Text(
                                "KES ${order.deliveryCharge.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          if (order.status == OrderStatus.accepted ||
                              order.status == OrderStatus.inTransit) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _advanceStatus(context, order),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  order.status == OrderStatus.accepted
                                      ? "Start Delivery"
                                      : "Mark Delivered",
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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