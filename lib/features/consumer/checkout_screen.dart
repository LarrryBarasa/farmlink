import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/consumer_service.dart';
import '../../services/farmer_service.dart';
import '../../services/delivery_calculator_service.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../services/location_service.dart';
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

  // Delivery charge for each farmer.
  Map<String, double> _chargePerFarmer = {};

  // Farm names.
  Map<String, String> _farmerNames = {};

  // Farm -> Consumer distance for each farmer.
  //
  // Example:
  // farmer123 -> 13.3
  // farmer456 -> 7.8
  Map<String, double> _distancePerFarmer = {};

  double _consumerLat = 0;
  double _consumerLng = 0;

  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _prepareCheckout();
  }

  // ================================================================
  // PREPARE CHECKOUT
  // ================================================================

  Future<void> _prepareCheckout() async {
    try {
      final currentUser = AuthService().currentUser;

      if (currentUser == null) {
        setState(() {
          _error = "Please log in again.";
          _loading = false;
        });
        return;
      }

      final consumerId = currentUser.uid;

      // ------------------------------------------------------------
      // GET CONSUMER PROFILE
      // ------------------------------------------------------------

      final consumerProfile =
          await ConsumerService().getConsumerProfile(
        consumerId,
      );

      final lat =
          (consumerProfile?['latitude'] as num?)?.toDouble();

      final lng =
          (consumerProfile?['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) {
        setState(() {
          _error =
              "Your location isn't set, so delivery can't be calculated. "
              "Please contact support to update your location.";

          _loading = false;
        });

        return;
      }

      _consumerLat = lat;
      _consumerLng = lng;

      // ------------------------------------------------------------
      // GET FARMS IN CART
      // ------------------------------------------------------------

      final farmerIds = CartService().farmerIds;

      if (farmerIds.isEmpty) {
        setState(() {
          _error = "Your cart is empty.";
          _loading = false;
        });

        return;
      }

      final farms = <FarmLocation>[];

      final names = <String, String>{};

      // This will store:
      //
      // farmerId -> farm -> consumer distance
      //
      final distances = <String, double>{};

      // ------------------------------------------------------------
      // GET FARM LOCATIONS
      // ------------------------------------------------------------

      for (final farmerId in farmerIds) {
        final profile =
            await FarmerService().getFarmerProfile(
          farmerId,
        );

        final farmLat =
            (profile?['latitude'] as num?)?.toDouble();

        final farmLng =
            (profile?['longitude'] as num?)?.toDouble();

        names[farmerId] =
            profile?['farmName']?.toString() ?? 'Farm';

        if (farmLat == null || farmLng == null) {
          continue;
        }

        // ----------------------------------------------------------
        // CALCULATE FARM -> CONSUMER DISTANCE
        // ----------------------------------------------------------

        final distance =
            _locationService.distanceKm(
          farmLat,
          farmLng,
          lat,
          lng,
        );

        distances[farmerId] = distance;

        farms.add(
          FarmLocation(
            farmerId: farmerId,
            latitude: farmLat,
            longitude: farmLng,
          ),
        );
      }

      // ------------------------------------------------------------
      // MAKE SURE EVERY FARM HAS A LOCATION
      // ------------------------------------------------------------

      if (farms.length != farmerIds.length) {
        setState(() {
          _error =
              "One or more farms in your cart don't have a location set. "
              "Delivery can't be calculated right now.";

          _loading = false;
        });

        return;
      }

      // ------------------------------------------------------------
      // CALCULATE DELIVERY PLAN
      // ------------------------------------------------------------

      final plan =
          DeliveryCalculatorService().calculate(
        consumerLat: lat,
        consumerLng: lng,
        farms: farms,
      );

      // ------------------------------------------------------------
      // CALCULATE DELIVERY CHARGE PER FARMER
      // ------------------------------------------------------------

      final chargeMap = <String, double>{};

      for (final group in plan.groups) {
        if (group.farmerIds.isEmpty) {
          continue;
        }

        final perFarmer =
            group.charge / group.farmerIds.length;

        for (final farmerId in group.farmerIds) {
          chargeMap[farmerId] = perFarmer;
        }
      }

      // ------------------------------------------------------------
      // SAVE EVERYTHING IN STATE
      // ------------------------------------------------------------

      setState(() {
        _plan = plan;

        _chargePerFarmer = chargeMap;

        _farmerNames = names;

        _distancePerFarmer = distances;

        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error =
            "Could not prepare checkout: $e";

        _loading = false;
      });
    }
  }

  // ================================================================
  // PLACE ORDER
  // ================================================================

  Future<void> _placeOrder() async {
    if (_placingOrder) {
      return;
    }

    setState(() {
      _placingOrder = true;
    });

    try {
      final currentUser =
          AuthService().currentUser;

      if (currentUser == null) {
        throw Exception(
          "Your session has expired. Please log in again.",
        );
      }

      final consumerId =
          currentUser.uid;

      // ------------------------------------------------------------
      // GET CONSUMER PROFILE
      // ------------------------------------------------------------

      final consumerProfile =
          await ConsumerService()
              .getConsumerProfile(
        consumerId,
      );

      // ------------------------------------------------------------
      // GET CART GROUPED BY FARMER
      // ------------------------------------------------------------

      final grouped =
          CartService().itemsByFarmer;

      if (grouped.isEmpty) {
        throw Exception(
          "Your cart is empty.",
        );
      }

      // ------------------------------------------------------------
      // CREATE ONE ORDER PER FARMER
      // ------------------------------------------------------------

      for (final entry in grouped.entries) {
        final farmerId = entry.key;

        final cartItems = entry.value;

        // ----------------------------------------------------------
        // CREATE ORDER ITEMS
        // ----------------------------------------------------------

        final orderItems = cartItems
            .map(
              (cartItem) => OrderItem(
                productId:
                    cartItem.product.id,

                name:
                    cartItem.product.name,

                unit:
                    cartItem.product.unit,

                quantity:
                    cartItem.quantity,

                consumerUnitPrice:
                    cartItem.product.consumerPrice,

                farmerUnitPrice:
                    cartItem.product.farmerPrice,
              ),
            )
            .toList();

        // ----------------------------------------------------------
        // GET FARM -> CONSUMER DISTANCE
        //
        // THIS IS THE IMPORTANT FIX.
        //
        // Example:
        //
        // Farm -> Consumer = 13.3 km
        //
        // Firebase will save:
        //
        // deliveryDistanceKm: 13.3
        // ----------------------------------------------------------

        final deliveryDistanceKm =
            _distancePerFarmer[farmerId] ?? 0.0;

        // ----------------------------------------------------------
        // GET DELIVERY CHARGE
        // ----------------------------------------------------------

        final deliveryCharge =
            _chargePerFarmer[farmerId] ?? 0.0;

        // ----------------------------------------------------------
        // CREATE ORDER
        // ----------------------------------------------------------

        final order = FarmOrder(
          id: '',

          farmerId:
              farmerId,

          consumerId:
              consumerId,

          consumerName:
              consumerProfile?['fullName']
                      ?.toString() ??
                  '',

          consumerPhone:
              consumerProfile?['phone']
                      ?.toString() ??
                  '',

          items:
              orderItems,

          deliveryCharge:
              deliveryCharge,

          // ========================================================
          // IMPORTANT
          //
          // SAVE THE ACTUAL FARM -> CONSUMER DISTANCE
          // ========================================================

          deliveryDistanceKm:
              deliveryDistanceKm,

          deliveryMode:
              'platformDelivery',

          status:
              OrderStatus.pending,

          pinCode:
              OrderService.generatePin(),
        );

        // ----------------------------------------------------------
        // SAVE ORDER TO FIREBASE
        // ----------------------------------------------------------

        await OrderService()
            .createOrder(order);

        // ----------------------------------------------------------
        // DECREMENT STOCK
        // ----------------------------------------------------------

        for (final cartItem in cartItems) {
          await ProductService()
              .decrementStock(
            cartItem.product.id,
            cartItem.quantity,
          );
        }
      }

      // ------------------------------------------------------------
      // CLEAR CART
      // ------------------------------------------------------------

      CartService().clear();

      if (!mounted) {
        return;
      }

      // ------------------------------------------------------------
      // SUCCESS DIALOG
      // ------------------------------------------------------------

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return AlertDialog(
            title: const Text(
              "Order Placed",
            ),

            content: const Text(
              "Your order has been placed successfully. "
              "Payment collection isn't wired up yet — this is a test order.",
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,

                    MaterialPageRoute(
                      builder: (_) =>
                          const ConsumerHomeScreen(),
                    ),

                    (route) => false,
                  );
                },

                child: const Text(
                  "OK",
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Could not place order: $e",
          ),

          backgroundColor:
              Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _placingOrder = false;
        });
      }
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Checkout",
        ),
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )

          : _error != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(24),

                    child: Text(
                      _error!,

                      textAlign:
                          TextAlign.center,

                      style:
                          const TextStyle(
                        color:
                            Colors.red,
                      ),
                    ),
                  ),
                )

              : _buildSummary(),
    );
  }

  // ================================================================
  // CHECKOUT SUMMARY
  // ================================================================

  Widget _buildSummary() {
    final grouped =
        CartService().itemsByFarmer;

    final itemsTotal =
        CartService().subtotal;

    final deliveryTotal =
        _chargePerFarmer.values
            .fold<double>(
          0,
          (sum, charge) =>
              sum + charge,
        );

    final grandTotal =
        itemsTotal + deliveryTotal;

    return ListView(
      padding:
          const EdgeInsets.all(16),

      children: [
        // ==========================================================
        // SPLIT DELIVERY MESSAGE
        // ==========================================================

        if (_plan?.isSplit == true)
          Container(
            padding:
                const EdgeInsets.all(12),

            margin:
                const EdgeInsets.only(
              bottom: 16,
            ),

            decoration:
                BoxDecoration(
              color:
                  Colors.orange.withValues(
                alpha: 0.1,
              ),

              borderRadius:
                  BorderRadius.circular(
                10,
              ),

              border:
                  Border.all(
                color:
                    Colors.orange.withValues(
                  alpha: 0.3,
                ),
              ),
            ),

            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color:
                      Colors.orange,
                ),

                SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Text(
                    "These farms are far apart, so your items will arrive as separate deliveries.",

                    style:
                        TextStyle(
                      color:
                          Colors.orange,

                      fontSize:
                          13,
                    ),
                  ),
                ),
              ],
            ),
          )

        // ==========================================================
        // COMBINED DELIVERY MESSAGE
        // ==========================================================

        else if (_plan != null &&
            _plan!.groups.isNotEmpty &&
            _plan!.groups.first.farmerIds.length >
                1)
          Container(
            padding:
                const EdgeInsets.all(12),

            margin:
                const EdgeInsets.only(
              bottom: 16,
            ),

            decoration:
                BoxDecoration(
              color:
                  AppColors.primary
                      .withValues(
                alpha: 0.08,
              ),

              borderRadius:
                  BorderRadius.circular(
                10,
              ),

              border:
                  Border.all(
                color:
                    AppColors.primary
                        .withValues(
                  alpha: 0.3,
                ),
              ),
            ),

            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,

                  color:
                      AppColors.primary,
                ),

                SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Text(
                    "These farms are close together, so one rider will collect and deliver everything together (a small extra fee applies).",

                    style:
                        TextStyle(
                      color:
                          AppColors.primary,

                      fontSize:
                          13,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ==========================================================
        // FARM ORDERS
        // ==========================================================

        ...grouped.entries.map(
          (entry) {
            final farmerId =
                entry.key;

            final items =
                entry.value;

            final farmSubtotal =
                items.fold<double>(
              0,

              (sum, item) =>
                  sum + item.subtotal,
            );

            final farmDelivery =
                _chargePerFarmer[
                        farmerId] ??
                    0;

            // ------------------------------------------------------
            // FARM -> CONSUMER DISTANCE
            // ------------------------------------------------------

            final farmDistance =
                _distancePerFarmer[
                        farmerId] ??
                    0.0;

            return Card(
              margin:
                  const EdgeInsets.only(
                bottom: 12,
              ),

              child: Padding(
                padding:
                    const EdgeInsets.all(
                  12,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    // =================================================
                    // FARM NAME
                    // =================================================

                    Text(
                      _farmerNames[
                              farmerId] ??
                          'Farm',

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,

                        fontSize:
                            16,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    // =================================================
                    // DISTANCE
                    // =================================================

                    Row(
                      children: [
                        const Icon(
                          Icons.route,
                          size: 16,
                          color:
                              AppColors.primary,
                        ),

                        const SizedBox(
                          width: 5,
                        ),

                        Text(
                          "${farmDistance.toStringAsFixed(1)} km delivery distance",

                          style:
                              const TextStyle(
                            color:
                                Colors.grey,

                            fontSize:
                                12,
                          ),
                        ),
                      ],
                    ),

                    const Divider(),

                    // =================================================
                    // ITEMS
                    // =================================================

                    ...items.map(
                      (item) {
                        return Padding(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 2,
                          ),

                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,

                            children: [
                              Expanded(
                                child: Text(
                                  "${item.product.name} × ${item.quantity}",
                                ),
                              ),

                              Text(
                                "KES ${item.subtotal.toStringAsFixed(0)}",
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const Divider(),

                    // =================================================
                    // FARM ITEMS SUBTOTAL
                    // =================================================

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,

                      children: [
                        const Text(
                          "Items subtotal",
                        ),

                        Text(
                          "KES ${farmSubtotal.toStringAsFixed(0)}",
                        ),
                      ],
                    ),

                    // =================================================
                    // DELIVERY
                    // =================================================

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,

                      children: [
                        const Text(
                          "Delivery",
                        ),

                        Text(
                          "KES ${farmDelivery.toStringAsFixed(0)}",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(
          height: 8,
        ),

        // ==========================================================
        // TOTAL BOX
        // ==========================================================

        Container(
          padding:
              const EdgeInsets.all(16),

          decoration:
              BoxDecoration(
            color:
                AppColors.primary,

            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),

          child: Column(
            children: [
              // ----------------------------------------------------
              // ITEMS TOTAL
              // ----------------------------------------------------

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [
                  const Text(
                    "Items Total",

                    style:
                        TextStyle(
                      color:
                          Colors.white70,
                    ),
                  ),

                  Text(
                    "KES ${itemsTotal.toStringAsFixed(0)}",

                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 4,
              ),

              // ----------------------------------------------------
              // DELIVERY TOTAL
              // ----------------------------------------------------

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [
                  const Text(
                    "Delivery Total",

                    style:
                        TextStyle(
                      color:
                          Colors.white70,
                    ),
                  ),

                  Text(
                    "KES ${deliveryTotal.toStringAsFixed(0)}",

                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                    ),
                  ),
                ],
              ),

              const Divider(
                color:
                    Colors.white54,
              ),

              // ----------------------------------------------------
              // GRAND TOTAL
              // ----------------------------------------------------

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [
                  const Text(
                    "Total to Pay",

                    style:
                        TextStyle(
                      color:
                          Colors.white,

                      fontWeight:
                          FontWeight.bold,

                      fontSize:
                          18,
                    ),
                  ),

                  Text(
                    "KES ${grandTotal.toStringAsFixed(0)}",

                    style:
                        const TextStyle(
                      color:
                          Colors.white,

                      fontWeight:
                          FontWeight.bold,

                      fontSize:
                          18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        // ==========================================================
        // PLACE ORDER BUTTON
        // ==========================================================

        SizedBox(
          width:
              double.infinity,

          height:
              52,

          child:
              ElevatedButton(
            onPressed:
                _placingOrder
                    ? null
                    : _placeOrder,

            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.primary,

              foregroundColor:
                  Colors.white,
            ),

            child:
                _placingOrder
                    ? const SizedBox(
                        height:
                            20,

                        width:
                            20,

                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,

                          color:
                              Colors.white,
                        ),
                      )

                    : const Text(
                        "Place Order",

                        style:
                            TextStyle(
                          fontSize:
                              16,
                        ),
                      ),
          ),
        ),
      ],
    );
  }
}
