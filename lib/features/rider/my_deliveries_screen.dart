import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../../services/farmer_service.dart';
import '../../services/location_service.dart';
import '../../services/order_service.dart';

class MyDeliveriesScreen extends StatefulWidget {
  const MyDeliveriesScreen({
    super.key,
  });

  @override
  State<MyDeliveriesScreen> createState() =>
      _MyDeliveriesScreenState();
}

class _MyDeliveriesScreenState
    extends State<MyDeliveriesScreen> {
  StreamSubscription<Position>? _locationSubscription;

  String? _trackingOrderId;

  bool _isTrackingLocation = false;


    StreamSubscription<List<FarmOrder>>? _payoutWatcherSub;
  final Map<String, bool> _previousPaidOut = {};
  bool _firstPayoutLoad = true;

  int _currentPage = 0;

  static const int _perPage = 3;

  // ================================================================
  // DISPOSE
  // ================================================================

   @override
  void initState() {
    super.initState();

    final riderId = AuthService().currentUser?.uid;

    if (riderId != null) {
      _payoutWatcherSub =
          OrderService().riderOrdersStream(riderId).listen(_handlePayoutUpdates);
    }
  }

  void _handlePayoutUpdates(List<FarmOrder> orders) {
    for (final order in orders) {
      final prevPaidOut = _previousPaidOut[order.id];

      if (!_firstPayoutLoad && prevPaidOut == false && order.isPaidOut == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Payment submitted by Admin for order to ${order.consumerName}.",
              ),
              backgroundColor: Colors.blue,
            ),
          );
        });
      }

      _previousPaidOut[order.id] = order.isPaidOut;
    }

    _firstPayoutLoad = false;
  }

  @override
  void dispose() {
    _payoutWatcherSub?.cancel();
    _stopLocationTracking();
    super.dispose();
  }

  // ================================================================
  // STATUS COLOR
  // ================================================================

  Color _statusColor(
    OrderStatus status,
  ) {
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
  // STATUS TEXT
  // ================================================================

  String _statusText(
    OrderStatus status,
  ) {
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

  // ================================================================
  // START DELIVERY
  // ================================================================

  Future<void> _startDelivery(
    FarmOrder order,
  ) async {
    try {
      // First change order status.
      await OrderService().updateOrderStatus(
        order.id,
        OrderStatus.inTransit,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Delivery started! 🚚",
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Start sharing the rider's live location.
      await _startLocationTracking(order);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Could not start delivery: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================================================================
  // START LOCATION TRACKING
  // ================================================================

  Future<void> _startLocationTracking(
    FarmOrder order,
  ) async {
    // Already tracking this order.
    if (_trackingOrderId == order.id &&
        _locationSubscription != null) {
      return;
    }

    // Stop any previous tracking.
    await _stopLocationTracking();

    try {
      final locationService =
          LocationService();

      // ------------------------------------------------------------
      // GET INITIAL LOCATION
      // ------------------------------------------------------------

      final initialPosition =
          await locationService.getCurrentLocation();

      if (initialPosition == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please enable location permission and GPS.",
            ),
            backgroundColor: Colors.orange,
          ),
        );

        return;
      }

      // ------------------------------------------------------------
      // SAVE INITIAL LOCATION
      // ------------------------------------------------------------

      await OrderService().updateRiderLiveLocation(
        order.id,
        initialPosition.latitude,
        initialPosition.longitude,
      );

      if (!mounted) return;

      setState(() {
        _trackingOrderId = order.id;
        _isTrackingLocation = true;
      });

      // ------------------------------------------------------------
      // CONTINUOUS LOCATION UPDATES
      // ------------------------------------------------------------

      _locationSubscription =
          locationService.getLocationStream().listen(
        (position) async {
          // Make sure this is still the active tracking order.
          if (_trackingOrderId != order.id) {
            return;
          }

          try {
            await OrderService().updateRiderLiveLocation(
              order.id,
              position.latitude,
              position.longitude,
            );

            debugPrint(
              "Rider location updated: "
              "${position.latitude}, ${position.longitude}",
            );
          } catch (e) {
            debugPrint(
              "Could not update rider location: $e",
            );
          }
        },
        onError: (error) {
          debugPrint(
            "Rider location stream error: $error",
          );
        },
      );
    } catch (e) {
      debugPrint(
        "Could not start rider location tracking: $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Could not start location tracking: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================================================================
  // STOP LOCATION TRACKING
  // ================================================================

  Future<void> _stopLocationTracking() async {
    await _locationSubscription?.cancel();

    _locationSubscription = null;
    _trackingOrderId = null;

    if (mounted) {
      setState(() {
        _isTrackingLocation = false;
      });
    }
  }

  // ================================================================
  // MARK DELIVERED
  // ================================================================

  Future<void> _markDelivered(
    FarmOrder order,
  ) async {
    final entered = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final controller =
            TextEditingController();

        return AlertDialog(
          title: const Text(
            "Enter Delivery Code",
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Ask the consumer for their 4-digit delivery code.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType:
                    TextInputType.number,
                maxLength: 4,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  hintText: "0000",
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop();
              },
              child: const Text(
                "Cancel",
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final code =
                    controller.text.trim();

                if (code.length != 4) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please enter the 4-digit delivery code.",
                      ),
                    ),
                  );

                  return;
                }

                Navigator.of(dialogContext)
                    .pop(code);
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
                "Confirm",
              ),
            ),
          ],
        );
      },
    );

    // User cancelled.
    if (entered == null ||
        entered.isEmpty) {
      return;
    }

    if (!mounted) return;

    try {
      final success =
          await OrderService()
              .confirmDeliveryWithPin(
        order.id,
        entered,
      );

      if (!mounted) return;

      if (success) {
        // Stop sharing location after delivery.
        await _stopLocationTracking();

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Delivery confirmed! ✅",
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Incorrect code. Please try again.",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Could not confirm delivery: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final currentUser =
        AuthService().currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Please log in to view deliveries.",
          ),
        ),
      );
    }

    final riderId = currentUser.uid;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F5F5),

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Deliveries",
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          if (_isTrackingLocation)
            Padding(
              padding:
                  const EdgeInsets.only(
                right: 12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration:
                        const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "LIVE",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),

      // ==========================================================
      // ORDERS STREAM
      // ==========================================================

      body: StreamBuilder<List<FarmOrder>>(
        stream: OrderService()
            .riderOrdersStream(riderId),

        builder: (
          context,
          snapshot,
        ) {
          // ========================================================
          // LOADING
          // ========================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          // ========================================================
          // ERROR
          // ========================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Text(
                  "Could not load your deliveries.\n${snapshot.error}",
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            );
          }

          final orders =
              snapshot.data ??
                  <FarmOrder>[];

          // ========================================================
          // EMPTY
          // ========================================================

          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    Icons
                        .local_shipping_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "No deliveries assigned to you yet.",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          }

          // ========================================================
          // SORT NEWEST FIRST
          // ========================================================

          orders.sort(
            (a, b) =>
                (b.createdAt ??
                        DateTime(0))
                    .compareTo(
              a.createdAt ??
                  DateTime(0),
            ),
          );

          // ========================================================
          // PAGINATION
          // ========================================================

          final totalPages =
              (orders.length / _perPage)
                  .ceil();

          if (_currentPage >=
              totalPages) {
            _currentPage =
                totalPages - 1;
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

          // ========================================================
          // PAGE
          // ========================================================

          return Column(
            children: [
              // ======================================================
              // ORDER LIST
              // ======================================================

              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  itemCount:
                      pageOrders.length,
                  itemBuilder:
                      (context, index) {
                    final order =
                        pageOrders[index];

                    return FutureBuilder<
                        Map<String, dynamic>?>(
                      future:
                          FarmerService()
                              .getFarmerProfile(
                        order.farmerId,
                      ),
                      builder: (
                        context,
                        farmSnapshot,
                      ) {
                        final farmData =
                            farmSnapshot.data;

                        final farmName =
                            farmData?[
                                    'farmName'] ??
                                'Farm';

                        return Card(
                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 12,
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .all(14),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                // ==================================
                                // PICKUP FARM + STATUS
                                // ==================================

                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    const CircleAvatar(
                                      radius: 22,
                                      backgroundColor:
                                          Color(
                                        0xFFE8F5E9,
                                      ),
                                      child:
                                          Icon(
                                        Icons
                                            .agriculture,
                                        color: Colors
                                            .green,
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 12,
                                    ),

                                    Expanded(
                                      child:
                                          Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          const Text(
                                            "Pickup",
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.grey,
                                              fontSize:
                                                  12,
                                            ),
                                          ),
                                          const SizedBox(
                                            height:
                                                3,
                                          ),
                                          Text(
                                            farmName
                                                .toString(),
                                            overflow:
                                                TextOverflow
                                                    .ellipsis,
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                              fontSize:
                                                  16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 8,
                                    ),

                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal:
                                            10,
                                        vertical:
                                            5,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            _statusColor(
                                          order.status,
                                        ).withValues(
                                          alpha:
                                              0.15,
                                        ),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          20,
                                        ),
                                      ),
                                      child: Text(
                                        _statusText(
                                          order.status,
                                        ),
                                        style:
                                            TextStyle(
                                          color:
                                              _statusColor(
                                            order.status,
                                          ),
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          fontSize:
                                              10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const Divider(
                                  height: 24,
                                ),

                                // ==================================
                                // CONSUMER DETAILS
                                // ==================================

                                Container(
                                  width:
                                      double.infinity,
                                  padding:
                                      const EdgeInsets
                                          .all(12),
                                  decoration:
                                      BoxDecoration(
                                    color: Colors
                                        .green
                                        .withValues(
                                      alpha:
                                          0.06,
                                    ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      12,
                                    ),
                                    border:
                                        Border.all(
                                      color: Colors
                                          .green
                                          .withValues(
                                        alpha:
                                            0.12,
                                      ),
                                    ),
                                  ),
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons
                                                .person_outline,
                                            color:
                                                Colors.green,
                                            size:
                                                21,
                                          ),
                                          SizedBox(
                                            width:
                                                8,
                                          ),
                                          Text(
                                            "Deliver To",
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.green,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height:
                                            10,
                                      ),

                                      // Consumer name
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons
                                                .person,
                                            size:
                                                18,
                                            color:
                                                Colors.grey,
                                          ),
                                          const SizedBox(
                                            width:
                                                8,
                                          ),
                                          Expanded(
                                            child:
                                                Text(
                                              order.consumerName
                                                      .isNotEmpty
                                                  ? order
                                                      .consumerName
                                                  : "Consumer",
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

                                      // Consumer phone
                                      if (order
                                          .consumerPhone
                                          .isNotEmpty) ...[
                                        const SizedBox(
                                          height:
                                              6,
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons
                                                  .phone,
                                              size:
                                                  18,
                                              color:
                                                  Colors.grey,
                                            ),
                                            const SizedBox(
                                              width:
                                                  8,
                                            ),
                                            Text(
                                              order
                                                  .consumerPhone,
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
                                ),

                                const SizedBox(
                                  height: 16,
                                ),

                                // ==================================
                                // DELIVERY ITEMS
                                // ==================================

                                const Text(
                                  "Delivery Items",
                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    fontSize:
                                        14,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(
                                    maxHeight:
                                        120,
                                  ),
                                  child:
                                      SingleChildScrollView(
                                    child:
                                        Column(
                                      children:
                                          order
                                              .items
                                              .map(
                                        (
                                          item,
                                        ) =>
                                            Padding(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            vertical:
                                                3,
                                          ),
                                          child:
                                              Row(
                                            children: [
                                              Expanded(
                                                child:
                                                    Text(
                                                  "${item.name} × ${item.quantity} ${item.unit}",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(
                                                width:
                                                    10,
                                              ),
                                              Text(
                                                "KES ${item.subtotal.toStringAsFixed(0)}",
                                                style:
                                                    const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ).toList(),
                                    ),
                                  ),
                                ),

                                const Divider(
                                  height: 20,
                                ),

                                // ==================================
                                // RIDER EARNINGS
                                // ==================================

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    const Text(
                                      "You earn",
                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                    Text(
                                      "KES ${order.deliveryCharge.toStringAsFixed(0)}",
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        color: AppColors
                                            .primary,
                                        fontSize:
                                            16,
                                      ),
                                    ),
                                  ],
                                ),

                                // ==================================
                                // LIVE TRACKING INDICATOR
                                // ==================================

                                if (_trackingOrderId ==
                                        order.id &&
                                    _isTrackingLocation) ...[
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  Container(
                                    width:
                                        double.infinity,
                                    padding:
                                        const EdgeInsets
                                            .all(10),
                                    decoration:
                                        BoxDecoration(
                                      color: Colors
                                          .green
                                          .withValues(
                                        alpha:
                                            0.08,
                                      ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        10,
                                      ),
                                    ),
                                    child:
                                        const Row(
                                      children: [
                                        Icon(
                                          Icons
                                              .gps_fixed,
                                          color: Colors
                                              .green,
                                          size: 20,
                                        ),
                                        SizedBox(
                                          width: 8,
                                        ),
                                        Expanded(
                                          child:
                                              Text(
                                            "Live location sharing is active",
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.green,
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // ==================================
                                // START DELIVERY
                                // ==================================

                                if (order.status ==
                                    OrderStatus
                                        .accepted) ...[
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  SizedBox(
                                    width:
                                        double.infinity,
                                    child:
                                        ElevatedButton
                                            .icon(
                                      onPressed:
                                          () =>
                                              _startDelivery(
                                        order,
                                      ),
                                      icon:
                                          const Icon(
                                        Icons
                                            .local_shipping,
                                      ),
                                      label:
                                          const Text(
                                        "Start Delivery",
                                      ),
                                      style:
                                          ElevatedButton
                                              .styleFrom(
                                        backgroundColor:
                                            AppColors
                                                .primary,
                                        foregroundColor:
                                            Colors.white,
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          vertical:
                                              13,
                                        ),
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                // ==================================
                                // MARK DELIVERED
                                // ==================================

                                if (order.status ==
                                    OrderStatus
                                        .inTransit) ...[
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  SizedBox(
                                    width:
                                        double.infinity,
                                    child:
                                        ElevatedButton
                                            .icon(
                                      onPressed:
                                          () =>
                                              _markDelivered(
                                        order,
                                      ),
                                      icon:
                                          const Icon(
                                        Icons
                                            .verified_outlined,
                                      ),
                                      label:
                                          const Text(
                                        "Enter Delivery Code",
                                      ),
                                      style:
                                          ElevatedButton
                                              .styleFrom(
                                        backgroundColor:
                                            AppColors
                                                .primary,
                                        foregroundColor:
                                            Colors.white,
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          vertical:
                                              13,
                                        ),
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                // ==================================
                                // DELIVERED MESSAGE
                                // ==================================

                                if (order.status ==
                                    OrderStatus
                                        .delivered) ...[
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  Container(
                                    width:
                                        double.infinity,
                                    padding:
                                        const EdgeInsets
                                            .all(12),
                                    decoration:
                                        BoxDecoration(
                                      color: Colors
                                          .green
                                          .withValues(
                                        alpha:
                                            0.08,
                                      ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        10,
                                      ),
                                    ),
                                    child:
                                        const Row(
                                      children: [
                                        Icon(
                                          Icons
                                              .check_circle,
                                          color: Colors
                                              .green,
                                        ),
                                        SizedBox(
                                          width: 8,
                                        ),
                                        Text(
                                          "Delivery completed",
                                          style:
                                              TextStyle(
                                            color: Colors
                                                .green,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
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
                      },
                    );
                  },
                ),
              ),

              // ======================================================
              // PAGINATION
              // ======================================================

              if (totalPages > 1)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
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
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),

                      IconButton(
                        onPressed:
                            _currentPage <
                                    totalPages -
                                        1
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
            ],
          );
        },
      ),
    );
  }
}
