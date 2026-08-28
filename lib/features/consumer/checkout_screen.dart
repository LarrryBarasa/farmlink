import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/consumer_service.dart';
import '../../services/farmer_service.dart';
import '../../services/delivery_calculator_service.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import 'consumer_home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _loading = true;
  bool _placingOrder = false;
  String? _error;

  DeliveryPlan? _plan;
  Map<String, double> _chargePerFarmer = {};
  Map<String, String> _farmerNames = {};
  double _consumerLat = 0;
  double _consumerLng = 0;

  @override
  void initState() {
    super.initState();
    _prepareCheckout();
  }

  Future<void> _prepareCheckout() async {
    try {
      final consumerId = AuthService().currentUser!.uid;
      final consumerProfile =
          await ConsumerService().getConsumerProfile(consumerId);

      final lat = (consumerProfile?['latitude'] as num?)?.toDouble();
      final lng = (consumerProfile?['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) {
        setState(() {
          _error = "Your location isn't set, so delivery can't be calculated. "
              "Please contact support to update your location.";
          _loading = false;
        });
        return;
      }

      _consumerLat = lat;
      _consumerLng = lng;

      final farmerIds = CartService().farmerIds;
      final farms = <FarmLocation>[];
      final names = <String, String>{};

      for (final id in farmerIds) {
        final profile = await FarmerService().getFarmerProfile(id);
        final fLat = (profile?['latitude'] as num?)?.toDouble();
        final fLng = (profile?['longitude'] as num?)?.toDouble();
        names[id] = profile?['farmName'] ?? 'Farm';

        if (fLat != null && fLng != null) {
          farms.add(FarmLocation(farmerId: id, latitude: fLat, longitude: fLng));
        }
      }

      if (farms.length != farmerIds.length) {
        setState(() {
          _error = "One or more farms in your cart don't have a location set. "
              "Delivery can't be calculated right now.";
          _loading = false;
        });
        return;
      }

      final plan = DeliveryCalculatorService().calculate(
        consumerLat: lat,
        consumerLng: lng,
        farms: farms,
      );

      final chargeMap = <String, double>{};
      for (final group in plan.groups) {
        final perFarmer = group.charge / group.farmerIds.length;
        for (final id in group.farmerIds) {
          chargeMap[id] = perFarmer;
        }
      }

      setState(() {
        _plan = plan;
        _chargePerFarmer = chargeMap;
        _farmerNames = names;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Could not prepare checkout: $e";
        _loading = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    setState(() => _placingOrder = true);

    try {
      final consumerId = AuthService().currentUser!.uid;
      final consumerProfile =
          await ConsumerService().getConsumerProfile(consumerId);

      final grouped = CartService().itemsByFarmer;

      for (final entry in grouped.entries) {
        final farmerId = entry.key;
        final cartItems = entry.value;

        final orderItems = cartItems
            .map((c) => OrderItem(
                  productId: c.product.id,
                  name: c.product.name,
                  unit: c.product.unit,
                  quantity: c.quantity,
                  consumerUnitPrice: c.product.consumerPrice,
                  farmerUnitPrice: c.product.farmerPrice,
                ))
            .toList();

        final order = FarmOrder(
          id: '',
          farmerId: farmerId,
          consumerId: consumerId,
          consumerName: consumerProfile?['fullName'] ?? '',
          consumerPhone: consumerProfile?['phone'] ?? '',
          items: orderItems,
          deliveryCharge: _chargePerFarmer[farmerId] ?? 0,
          deliveryMode: 'platformDelivery',
          status: OrderStatus.pending,
        );

        await OrderService().createOrder(order);
      }

      CartService().clear();

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Order Placed"),
          content: const Text(
            "Your order has been placed successfully. "
            "Payment collection isn't wired up yet — this is a test order.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const ConsumerHomeScreen()),
                  (route) => false,
                );
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not place order: $e")),
      );
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : _buildSummary(),
    );
  }

  Widget _buildSummary() {
    final grouped = CartService().itemsByFarmer;
    final itemsTotal = CartService().subtotal;
    final deliveryTotal =
        _chargePerFarmer.values.fold<double>(0, (sum, c) => sum + c);
    final grandTotal = itemsTotal + deliveryTotal;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_plan?.isSplit == true)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "These farms are far apart, so your items will arrive as "
                    "separate deliveries.",
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else if (_plan != null && _plan!.groups.first.farmerIds.length > 1)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "These farms are close together, so one rider will collect "
                    "and deliver everything together (a small extra fee applies).",
                    style: TextStyle(color: AppColors.primary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

        ...grouped.entries.map((entry) {
          final farmerId = entry.key;
          final items = entry.value;
          final farmSubtotal =
              items.fold<double>(0, (sum, item) => sum + item.subtotal);
          final farmDelivery = _chargePerFarmer[farmerId] ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _farmerNames[farmerId] ?? 'Farm',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(),
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${item.product.name} × ${item.quantity}"),
                            Text("KES ${item.subtotal.toStringAsFixed(0)}"),
                          ],
                        ),
                      )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Items subtotal"),
                      Text("KES ${farmSubtotal.toStringAsFixed(0)}"),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Delivery"),
                      Text("KES ${farmDelivery.toStringAsFixed(0)}"),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Items Total",
                      style: TextStyle(color: Colors.white70)),
                  Text("KES ${itemsTotal.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Delivery Total",
                      style: TextStyle(color: Colors.white70)),
                  Text("KES ${deliveryTotal.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
              const Divider(color: Colors.white54),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total to Pay",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  Text("KES ${grandTotal.toStringAsFixed(0)}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _placingOrder ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: _placingOrder
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text("Place Order", style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}