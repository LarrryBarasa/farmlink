import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/order_service.dart';
import '../../services/farmer_service.dart';
import '../../services/rider_service.dart';
import '../../models/order_model.dart';

class ConsumerOrdersScreen extends StatefulWidget {
  final String consumerId;

  const ConsumerOrdersScreen({super.key, required this.consumerId});

  @override
  State<ConsumerOrdersScreen> createState() => _ConsumerOrdersScreenState();
}

class _ConsumerOrdersScreenState extends State<ConsumerOrdersScreen> {
  final Map<String, OrderStatus> _previousStatus = {};
  bool _firstLoad = true;

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

  void _checkForNewAcceptance(List<FarmOrder> orders) {
    for (final order in orders) {
      final prev = _previousStatus[order.id];

      if (!_firstLoad &&
          prev != null &&
          prev != OrderStatus.accepted &&
          order.status == OrderStatus.accepted &&
          order.riderId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;

          final riderProfile = await RiderService().getRiderProfile(order.riderId!);
          final riderName = riderProfile?['fullName'] ?? 'A rider';

          if (!mounted) return;

          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Rider Assigned!"),
              content: Text("$riderName has accepted your delivery and is on the way soon."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        });
      }

      _previousStatus[order.id] = order.status;
    }

    _firstLoad = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Orders")),
      body: StreamBuilder<List<FarmOrder>>(
        stream: OrderService().consumerOrdersStream(widget.consumerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Text(
                "No orders yet.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          orders.sort((a, b) =>
              (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

          _checkForNewAcceptance(orders);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

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
                          FutureBuilder<Map<String, dynamic>?>(
                            future: FarmerService().getFarmerProfile(order.farmerId),
                            builder: (context, farmSnap) {
                              final farmName =
                                  farmSnap.data?['farmName'] ?? 'Farm';
                              return Text(
                                farmName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              );
                            },
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
                      const Divider(height: 20),
                      ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("${item.name} × ${item.quantity} ${item.unit}"),
                                Text("KES ${item.subtotal.toStringAsFixed(0)}"),
                              ],
                            ),
                          )),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Delivery"),
                          Text("KES ${order.deliveryCharge.toStringAsFixed(0)}"),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            "KES ${order.totalAmount.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (order.riderId != null &&
                          (order.status == OrderStatus.accepted ||
                              order.status == OrderStatus.inTransit ||
                              order.status == OrderStatus.delivered)) ...[
                        const Divider(height: 20),
                        FutureBuilder<Map<String, dynamic>?>(
                          future: RiderService().getRiderProfile(order.riderId!),
                          builder: (context, riderSnap) {
                            if (!riderSnap.hasData) {
                              return const SizedBox.shrink();
                            }
                            final rider = riderSnap.data;
                            return Row(
                              children: [
                                const Icon(Icons.delivery_dining,
                                    color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rider?['fullName'] ?? 'Rider assigned',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        rider?['phone'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}