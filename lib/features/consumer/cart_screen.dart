import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/cart_service.dart';
import '../../services/farmer_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, String> _farmerNames = {};
  bool _loadingNames = true;

  @override
  void initState() {
    super.initState();
    _loadFarmerNames();
  }

  Future<void> _loadFarmerNames() async {
    final farmerIds = CartService().farmerIds;
    final names = <String, String>{};

    for (final id in farmerIds) {
      final profile = await FarmerService().getFarmerProfile(id);
      names[id] = profile?['farmName'] ?? 'Farm';
    }

    if (mounted) {
      setState(() {
        _farmerNames = names;
        _loadingNames = false;
      });
    }
  }

  Future<void> _editQuantityDialog(String productId, int currentQuantity) async {
    final controller = TextEditingController(text: "$currentQuantity");

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Quantity"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(hintText: "e.g. 100"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                Navigator.pop(context, value);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (result != null && result > 0) {
      setState(() {
        CartService().updateQuantity(productId, result);
      });
    } else if (result != null && result <= 0) {
      setState(() {
        CartService().updateQuantity(productId, 0); // removes item
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = CartService().itemsByFarmer;

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: grouped.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 90,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Products you add to your cart will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Continue Shopping'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _loadingNames
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: grouped.entries.map((entry) {
                          final farmerId = entry.key;
                          final items = entry.value;
                          final farmName = _farmerNames[farmerId] ?? 'Farm';
                          final farmSubtotal = items.fold<double>(
                            0,
                            (sum, item) => sum + item.subtotal,
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.agriculture,
                                          color: AppColors.primary, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        farmName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  ...items.map((item) => Padding(
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.product.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    "KES ${item.product.consumerPrice.toStringAsFixed(0)} / ${item.product.unit}",
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.remove_circle_outline,
                                                    size: 22,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      CartService().updateQuantity(
                                                        item.product.id,
                                                        item.quantity - 1,
                                                      );
                                                    });
                                                  },
                                                ),
                                                GestureDetector(
                                                  onTap: () => _editQuantityDialog(
                                                    item.product.id,
                                                    item.quantity,
                                                  ),
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: Colors.grey
                                                            .withValues(alpha: 0.4),
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      "${item.quantity}",
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.add_circle_outline,
                                                    size: 22,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      CartService().updateQuantity(
                                                        item.product.id,
                                                        item.quantity + 1,
                                                      );
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              width: 70,
                                              child: Text(
                                                "KES ${item.subtotal.toStringAsFixed(0)}",
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                  const Divider(),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      "Subtotal: KES ${farmSubtotal.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Items Total",
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  "KES ${CartService().subtotal.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Delivery fee calculated at checkout",
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Continue Shopping"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const CheckoutScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text("Checkout"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}