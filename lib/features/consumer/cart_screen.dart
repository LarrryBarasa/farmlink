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

  // ================================================================
  // LOAD FARM NAMES
  // ================================================================

  Future<void> _loadFarmerNames() async {
    final farmerIds = CartService().farmerIds;
    final names = <String, String>{};

    for (final id in farmerIds) {
      final profile =
          await FarmerService().getFarmerProfile(id);

      names[id] =
          profile?['farmName'] ?? 'Farm';
    }

    if (!mounted) return;

    setState(() {
      _farmerNames = names;
      _loadingNames = false;
    });
  }

  // ================================================================
  // DELETE INDIVIDUAL ITEM
  // ================================================================

  Future<void> _deleteItem(
    String productId,
    String productName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Remove Item?"),
          content: Text(
            'Are you sure you want to remove "$productName" '
            'from your cart?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text("Remove"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    CartService().removeProduct(productId);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"$productName" removed from your cart',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ================================================================
  // CLEAR CART
  // ================================================================

  Future<void> _clearCart() async {
    if (CartService().items.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Clear Cart?"),
          content: const Text(
            "Are you sure you want to remove all items "
            "from your cart?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text("Clear Cart"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    CartService().clear();

    if (!mounted) return;

    setState(() {
      _farmerNames.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Cart cleared"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ================================================================
  // EDIT QUANTITY
  // ================================================================

  Future<void> _editQuantityDialog(
    String productId,
    int currentQuantity,
  ) async {
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        // IMPORTANT:
        // The controller belongs to this dialog.
        // Flutter will dispose it with the dialog.
        final controller =
            TextEditingController(
          text: "$currentQuantity",
        );

        return AlertDialog(
          title: const Text("Enter Quantity"),

          content: TextField(
            controller: controller,
            keyboardType:
                TextInputType.number,
            autofocus: true,
            decoration:
                const InputDecoration(
              hintText: "e.g. 100",
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text("Cancel"),
            ),

            TextButton(
              onPressed: () {
                final value =
                    int.tryParse(
                  controller.text.trim(),
                );

                Navigator.of(
                  dialogContext,
                ).pop(value);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    // ==============================================================
    // DIALOG HAS COMPLETELY CLOSED
    // ==============================================================

    if (!mounted || result == null) {
      return;
    }

    // ==============================================================
    // FIND ITEM
    // ==============================================================

    final matchingItems =
        CartService()
            .items
            .where(
              (item) =>
                  item.product.id ==
                  productId,
            )
            .toList();

    if (matchingItems.isEmpty) {
      return;
    }

    final item = matchingItems.first;

    // ==============================================================
    // REMOVE IF ZERO
    // ==============================================================

    if (result <= 0) {
      CartService().updateQuantity(
        productId,
        0,
      );

      if (mounted) {
        setState(() {});
      }

      return;
    }

    // ==============================================================
    // CHECK STOCK
    // ==============================================================

    final maxStock =
        item.product.stockQuantity;

    if (result > maxStock) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Only $maxStock "
            "${item.product.unit} available",
          ),
        ),
      );

      CartService().updateQuantity(
        productId,
        maxStock,
      );
    } else {
      CartService().updateQuantity(
        productId,
        result,
      );
    }

    // ==============================================================
    // REFRESH CART
    // ==============================================================

    if (mounted) {
      setState(() {});
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final grouped =
        CartService().itemsByFarmer;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart"),

        actions: [
          if (grouped.isNotEmpty)
            TextButton.icon(
              onPressed: _clearCart,
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: Colors.red,
              ),
              label: const Text(
                "Clear",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
        ],
      ),

      // ============================================================
      // EMPTY CART
      // ============================================================

      body: grouped.isEmpty
          ? Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons
                          .shopping_cart_outlined,
                      size: 90,
                      color:
                          AppColors.primary,
                    ),

                    const SizedBox(
                        height: 20),

                    const Text(
                      "Your cart is empty",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppColors.dark,
                      ),
                    ),

                    const SizedBox(
                        height: 10),

                    const Text(
                      "Products you add to your "
                      "cart will appear here.",
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(
                        height: 30),

                    ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pop(
                        context,
                      ),
                      icon: const Icon(
                        Icons
                            .shopping_bag_outlined,
                      ),
                      label: const Text(
                        "Continue Shopping",
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primary,
                        foregroundColor:
                            Colors.white,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )

          // ==========================================================
          // LOADING
          // ==========================================================

          : _loadingNames
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )

              // ======================================================
              // CART CONTENT
              // ======================================================

              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding:
                            const EdgeInsets.all(
                          16,
                        ),
                        children:
                            grouped.entries
                                .map(
                          (entry) {
                            final farmerId =
                                entry.key;

                            final items =
                                entry.value;

                            final farmName =
                                _farmerNames[
                                        farmerId] ??
                                    "Farm";

                            final farmSubtotal =
                                items.fold<double>(
                              0,
                              (
                                sum,
                                item,
                              ) =>
                                  sum +
                                  item.subtotal,
                            );

                            return Card(
                              margin:
                                  const EdgeInsets
                                      .only(
                                bottom: 16,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets
                                        .all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    // =================================
                                    // FARM HEADER
                                    // =================================

                                    Row(
                                      children: [
                                        const Icon(
                                          Icons
                                              .agriculture,
                                          color:
                                              AppColors
                                                  .primary,
                                          size: 20,
                                        ),

                                        const SizedBox(
                                            width: 6),

                                        Expanded(
                                          child:
                                              Text(
                                            farmName,
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                              fontSize:
                                                  16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const Divider(),

                                    // =================================
                                    // PRODUCTS
                                    // =================================

                                    ...items.map(
                                      (
                                        item,
                                      ) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            vertical:
                                                8,
                                          ),
                                          child:
                                              Row(
                                            children: [
                                              // ========================
                                              // PRODUCT
                                              // ========================

                                              Expanded(
                                                child:
                                                    Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    Text(
                                                      item
                                                          .product
                                                          .name,
                                                      maxLines:
                                                          2,
                                                      overflow:
                                                          TextOverflow
                                                              .ellipsis,
                                                      style:
                                                          const TextStyle(
                                                        fontWeight:
                                                            FontWeight
                                                                .w600,
                                                      ),
                                                    ),

                                                    const SizedBox(
                                                      height:
                                                          3,
                                                    ),

                                                    Text(
                                                      "KES ${item.product.consumerPrice.toStringAsFixed(0)} / ${item.product.unit}",
                                                      style:
                                                          const TextStyle(
                                                        fontSize:
                                                            12,
                                                        color:
                                                            Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // ========================
                                              // QUANTITY
                                              // ========================

                                              Row(
                                                mainAxisSize:
                                                    MainAxisSize
                                                        .min,
                                                children: [
                                                  IconButton(
                                                    icon:
                                                        const Icon(
                                                      Icons
                                                          .remove_circle_outline,
                                                      size:
                                                          22,
                                                    ),
                                                    onPressed:
                                                        () {
                                                      CartService()
                                                          .updateQuantity(
                                                        item
                                                            .product
                                                            .id,
                                                        item
                                                                .quantity -
                                                            1,
                                                      );

                                                      if (mounted) {
                                                        setState(
                                                          () {},
                                                        );
                                                      }
                                                    },
                                                  ),

                                                  GestureDetector(
                                                    onTap:
                                                        () =>
                                                            _editQuantityDialog(
                                                      item
                                                          .product
                                                          .id,
                                                      item
                                                          .quantity,
                                                    ),
                                                    child:
                                                        Container(
                                                      constraints:
                                                          const BoxConstraints(
                                                        minWidth:
                                                            32,
                                                      ),
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal:
                                                            8,
                                                        vertical:
                                                            4,
                                                      ),
                                                      decoration:
                                                          BoxDecoration(
                                                        border:
                                                            Border.all(
                                                          color:
                                                              Colors.grey.withValues(
                                                            alpha:
                                                                0.4,
                                                          ),
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                          6,
                                                        ),
                                                      ),
                                                      child:
                                                          Text(
                                                        "${item.quantity}",
                                                        textAlign:
                                                            TextAlign.center,
                                                        style:
                                                            const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  IconButton(
                                                    icon:
                                                        const Icon(
                                                      Icons
                                                          .add_circle_outline,
                                                      size:
                                                          22,
                                                    ),
                                                    onPressed:
                                                        () {
                                                      if (item
                                                              .quantity >=
                                                          item
                                                              .product
                                                              .stockQuantity) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content:
                                                                Text(
                                                              "Only ${item.product.stockQuantity} ${item.product.unit} available",
                                                            ),
                                                          ),
                                                        );

                                                        return;
                                                      }

                                                      CartService()
                                                          .updateQuantity(
                                                        item
                                                            .product
                                                            .id,
                                                        item
                                                                .quantity +
                                                            1,
                                                      );

                                                      if (mounted) {
                                                        setState(
                                                          () {},
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),

                                              // ========================
                                              // SUBTOTAL
                                              // ========================

                                              SizedBox(
                                                width:
                                                    75,
                                                child:
                                                    Text(
                                                  "KES ${item.subtotal.toStringAsFixed(0)}",
                                                  textAlign:
                                                      TextAlign.right,
                                                  style:
                                                      const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ),

                                              // ========================
                                              // DELETE
                                              // ========================

                                              IconButton(
                                                tooltip:
                                                    "Remove item",
                                                icon:
                                                    const Icon(
                                                  Icons
                                                      .delete_outline,
                                                  color:
                                                      Colors.red,
                                                  size:
                                                      22,
                                                ),
                                                onPressed:
                                                    () =>
                                                        _deleteItem(
                                                  item
                                                      .product
                                                      .id,
                                                  item
                                                      .product
                                                      .name,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),

                                    const Divider(),

                                    // =================================
                                    // FARM SUBTOTAL
                                    // =================================

                                    Align(
                                      alignment:
                                          Alignment
                                              .centerRight,
                                      child:
                                          Text(
                                        "Subtotal: KES ${farmSubtotal.toStringAsFixed(0)}",
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          color:
                                              AppColors
                                                  .primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ),

                    // ==================================================
                    // BOTTOM TOTAL
                    // ==================================================

                    Container(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(
                              alpha: 0.05,
                            ),
                            blurRadius: 8,
                            offset:
                                const Offset(
                              0,
                              -2,
                            ),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                              children: [
                                const Text(
                                  "Items Total",
                                  style:
                                      TextStyle(
                                    fontSize: 16,
                                  ),
                                ),

                                Text(
                                  "KES ${CartService().subtotal.toStringAsFixed(0)}",
                                  style:
                                      const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                                height: 4),

                            const Text(
                              "Delivery fee calculated "
                              "at checkout",
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Colors.grey,
                              ),
                            ),

                            const SizedBox(
                                height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child:
                                      OutlinedButton(
                                    onPressed: () =>
                                        Navigator.pop(
                                      context,
                                    ),
                                    child:
                                        const Text(
                                      "Continue Shopping",
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                    width: 12),

                                Expanded(
                                  child:
                                      ElevatedButton(
                                    style:
                                        ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppColors
                                              .primary,
                                      foregroundColor:
                                          Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) =>
                                                  const CheckoutScreen(),
                                        ),
                                      );
                                    },
                                    child:
                                        const Text(
                                      "Checkout",
                                    ),
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
