import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_config.dart';
import '../../services/auth_service.dart';
import '../../services/rider_service.dart';
import '../../services/farmer_service.dart';
import '../../services/order_service.dart';
import '../../services/location_service.dart';
import '../../models/order_model.dart';
import '../auth/login_screen.dart';
import 'my_deliveries_screen.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  String? _riderId;

  Future<Map<String, dynamic>?>? _riderProfileFuture;

  Stream<List<FarmOrder>>? _availableOrdersStream;

  Stream<List<FarmOrder>>? _riderOrdersStream;

  Set<String> _seenOrderIds = {};

  bool _firstLoad = true;

  bool _accepting = false;

  @override
  void initState() {
    super.initState();

    final user = AuthService().currentUser;

    if (user != null) {
      _riderId = user.uid;

      _riderProfileFuture =
          RiderService().getRiderProfile(user.uid);

      _availableOrdersStream =
          OrderService().availableOrdersStream();

      _riderOrdersStream =
          OrderService().riderOrdersStream(user.uid);
    }
  }

  // ================================================================
  // VIBRATION
  // ================================================================

  Future<void> _buzz() async {
    try {
      final hasVibrator =
          await Vibration.hasVibrator();

      if (hasVibrator ?? false) {
        await Vibration.vibrate(
          duration: 500,
        );
      }
    } catch (_) {
      // Vibration is optional.
    }
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
  // ACCEPT DELIVERY
  // ================================================================

  Future<void> _acceptJob(
    String orderId,
  ) async {
    final riderId = _riderId;

    if (riderId == null) {
      return;
    }

    setState(() {
      _accepting = true;
    });

    try {
      final success =
          await OrderService().acceptOrder(
        orderId,
        riderId,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Job accepted! Check My Deliveries.",
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Too late — another rider already took this job.",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Could not accept job: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _accepting = false;
        });
      }
    }
  }

  // ================================================================
  // CALCULATE TOTAL KMs DONE
  //
  // Only delivered orders are counted.
  //
  // deliveryDistanceKm means:
  //
  // FARM -> CONSUMER
  //
  // Example:
  //
  // Order 1 = 13.3 km
  // Order 2 = 5.7 km
  //
  // KMs Done = 19.0 km
  // ================================================================

  double _calculateTotalKm(
    List<FarmOrder> orders,
  ) {
    double totalKm = 0.0;

    for (final order in orders) {
      if (order.status != OrderStatus.delivered) {
        continue;
      }

      totalKm += order.deliveryDistanceKm;
    }

    return totalKm;
  }

  // ================================================================
  // RIDER DASHBOARD
  // ================================================================

  Widget _buildDashboard(
  List<FarmOrder> orders,
) {
  // ================================================================
  // DELIVERED ORDERS
  // ================================================================

  final deliveredOrders = orders.where(
    (order) =>
        order.status == OrderStatus.delivered,
  ).toList();

  // ================================================================
  // PENDING ORDERS
  // ================================================================

  final pendingOrders = orders.where(
    (order) =>
        order.status == OrderStatus.accepted ||
        order.status == OrderStatus.inTransit,
  ).toList();

  // ================================================================
  // CLIENTS SERVED
  // ================================================================

  final clientsServed = deliveredOrders
      .map(
        (order) => order.consumerId,
      )
      .where(
        (id) => id.isNotEmpty,
      )
      .toSet()
      .length;

  // ================================================================
  // TOTAL EARNINGS
  //
  // Rider receives the delivery charge minus the platform
  // commission.
  //
  // Example:
  //
  // Delivery charge = KES 200
  // Commission = 10%
  // Rider earns = KES 180
  // ================================================================

  final totalEarnings = deliveredOrders.fold<double>(
    0.0,
    (total, order) {
      final riderEarning =
          order.deliveryCharge *
              (1 -
                  AppConfig.deliveryCommissionRate);

      return total + riderEarning;
    },
  );

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

      const SizedBox(
        height: 12,
      ),

      GridView.count(
        crossAxisCount: 2,

        shrinkWrap: true,

        physics:
            const NeverScrollableScrollPhysics(),

        crossAxisSpacing: 12,

        mainAxisSpacing: 12,

        childAspectRatio: 1.55,

        children: [
          // ==========================================================
          // TOTAL EARNINGS
          // ==========================================================

          _DashboardCard(
            title: "Total Earnings",

            value:
                "KES ${totalEarnings.toStringAsFixed(0)}",

            subtitle:
                "From completed deliveries",

            icon:
                Icons.payments_outlined,

            color:
                Colors.green,
          ),

          // ==========================================================
          // DELIVERIES DONE
          // ==========================================================

          _DashboardCard(
            title: "Deliveries Done",

            value:
                "${deliveredOrders.length}",

            subtitle:
                "Completed",

            icon:
                Icons.check_circle_outline,

            color:
                Colors.blue,
          ),

          // ==========================================================
          // PENDING DELIVERY
          // ==========================================================

          _DashboardCard(
            title: "Pending Delivery",

            value:
                "${pendingOrders.length}",

            subtitle:
                "In progress",

            icon:
                Icons.local_shipping_outlined,

            color:
                Colors.orange,
          ),

          // ==========================================================
          // CLIENTS SERVED
          // ==========================================================

          _DashboardCard(
            title: "Clients Served",

            value:
                "$clientsServed",

            subtitle:
                "Unique clients",

            icon:
                Icons.people_outline,

            color:
                Colors.purple,
          ),
        ],
      ),

      const SizedBox(
        height: 24,
      ),
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
    final riderId = _riderId;

    if (riderId == null ||
        _riderProfileFuture == null ||
        _availableOrdersStream == null ||
        _riderOrdersStream == null) {
      return Scaffold(
        backgroundColor:
            const Color(0xFFF5F5F5),

        body: Center(
          child: ElevatedButton(
            onPressed:
                () => _logout(context),

            child: const Text(
              "Please log in again",
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F5F5),

      // ==============================================================
      // APP BAR
      // ==============================================================

      appBar: AppBar(
        backgroundColor:
            Colors.white,

        elevation: 0,

        title: const Text(
          "Farmlink",

          style: TextStyle(
            color: Colors.green,
            fontWeight:
                FontWeight.bold,
            fontSize: 24,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const MyDeliveriesScreen(),
                ),
              );
            },

            icon: const Icon(
              Icons.local_shipping,
              color: Colors.black,
            ),
          ),

          IconButton(
            onPressed:
                () => _logout(context),

            icon: const Icon(
              Icons.logout,
              color: Colors.black,
            ),
          ),
        ],
      ),

      // ==============================================================
      // BODY
      // ==============================================================

      body:
          FutureBuilder<Map<String, dynamic>?>(
        future:
            _riderProfileFuture,

        builder: (
          context,
          riderSnapshot,
        ) {
          final riderData =
              riderSnapshot.data;

          final riderName =
              riderData?['fullName']
                      ?.toString() ??
                  '';

          // ----------------------------------------------------------
          // RIDER LOCATION
          //
          // Used only for sorting available deliveries.
          // ----------------------------------------------------------

          final riderLat =
              (riderData?['latitude']
                      as num?)
                  ?.toDouble();

          final riderLng =
              (riderData?['longitude']
                      as num?)
                  ?.toDouble();

          return StreamBuilder<
              List<FarmOrder>>(
            stream:
                _riderOrdersStream,

            builder: (
              context,
              riderOrdersSnapshot,
            ) {
              final riderOrders =
                  riderOrdersSnapshot.data ??
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
                      riderName.isNotEmpty
                          ? "Welcome back, $riderName 🛵"
                          : "Welcome back 🛵",

                      style:
                          const TextStyle(
                        fontSize: 18,
                        color:
                            Colors.grey,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // =================================================
                    // DASHBOARD
                    // =================================================

                    _buildDashboard(
                      riderOrders,
                    ),

                    // =================================================
                    // AVAILABLE DELIVERIES
                    // =================================================

                    const Text(
                      "Available Deliveries",

                      style:
                          TextStyle(
                        fontSize: 24,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    if (riderLat ==
                            null ||
                        riderLng ==
                            null) ...[
                      const SizedBox(
                        height: 8,
                      ),

                      const Text(
                        "Your location isn't set, so jobs can't be sorted by distance.",

                        style:
                            TextStyle(
                          color:
                              Colors.orange,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 16,
                    ),

                    // =================================================
                    // AVAILABLE ORDERS
                    // =================================================

                    Expanded(
                      child:
                          StreamBuilder<
                              List<FarmOrder>>(
                        stream:
                            _availableOrdersStream,

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

                          if (snapshot
                              .hasError) {
                            return Center(
                              child: Text(
                                "Could not load deliveries.\n${snapshot.error}",

                                textAlign:
                                    TextAlign.center,

                                style:
                                    const TextStyle(
                                  color:
                                      Colors.red,
                                ),
                              ),
                            );
                          }

                          final orders =
                              snapshot.data ??
                                  <FarmOrder>[];

                          // =================================================
                          // VIBRATE FOR NEW JOB
                          // =================================================

                          final currentIds =
                              orders
                                  .map(
                                    (order) =>
                                        order.id,
                                  )
                                  .toSet();

                          if (!_firstLoad) {
                            final newIds =
                                currentIds
                                    .difference(
                              _seenOrderIds,
                            );

                            if (newIds
                                .isNotEmpty) {
                              WidgetsBinding
                                  .instance
                                  .addPostFrameCallback(
                                (_) {
                                  if (mounted) {
                                    _buzz();
                                  }
                                },
                              );
                            }
                          } else {
                            _firstLoad =
                                false;
                          }

                          _seenOrderIds =
                              currentIds;

                          // =================================================
                          // NO JOBS
                          // =================================================

                          if (orders.isEmpty) {
                            return const Center(
                              child: Text(
                                "No delivery jobs available right now.",

                                style:
                                    TextStyle(
                                  color:
                                      Colors.grey,
                                ),
                              ),
                            );
                          }

                          // =================================================
                          // BUILD JOB CARDS
                          // =================================================

                          return FutureBuilder<
                              List<_JobCardData>>(
                            future:
                                _buildJobCards(
                              orders,
                              riderLat,
                              riderLng,
                            ),

                            builder: (
                              context,
                              cardsSnapshot,
                            ) {
                              if (cardsSnapshot
                                      .connectionState ==
                                  ConnectionState
                                      .waiting) {
                                return const Center(
                                  child:
                                      CircularProgressIndicator(),
                                );
                              }

                              if (cardsSnapshot
                                  .hasError) {
                                return Center(
                                  child: Text(
                                    "Could not load delivery details.\n${cardsSnapshot.error}",

                                    textAlign:
                                        TextAlign.center,

                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.red,
                                    ),
                                  ),
                                );
                              }

                              final cards =
                                  cardsSnapshot.data ??
                                      <_JobCardData>[];

                              // =================================================
                              // SORT AVAILABLE JOBS
                              //
                              // Rider -> Farm distance.
                              //
                              // This is NOT KMs Done.
                              // =================================================

                              cards.sort(
                                (
                                  a,
                                  b,
                                ) {
                                  final aDistance =
                                      a.distanceKm;

                                  final bDistance =
                                      b.distanceKm;

                                  if (aDistance ==
                                          null &&
                                      bDistance ==
                                          null) {
                                    return 0;
                                  }

                                  if (aDistance ==
                                      null) {
                                    return 1;
                                  }

                                  if (bDistance ==
                                      null) {
                                    return -1;
                                  }

                                  return aDistance
                                      .compareTo(
                                    bDistance,
                                  );
                                },
                              );

                              // =================================================
                              // AVAILABLE JOB LIST
                              // =================================================

                              return ListView
                                  .builder(
                                itemCount:
                                    cards.length,

                                itemBuilder:
                                    (
                                  context,
                                  index,
                                ) {
                                  final card =
                                      cards[index];

                                  final riderEarning =
                                      card.order
                                              .deliveryCharge *
                                          (1 -
                                              AppConfig
                                                  .deliveryCommissionRate);

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
                                        Padding(
                                      padding:
                                          const EdgeInsets
                                              .all(
                                        14,
                                      ),

                                      child:
                                          Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,

                                        children: [
                                          // =================================================
                                          // FARM + DISTANCE
                                          // =================================================

                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,

                                            children: [
                                              Expanded(
                                                child:
                                                    Text(
                                                  card
                                                      .farmName,

                                                  style:
                                                      const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize:
                                                        16,
                                                  ),
                                                ),
                                              ),

                                              if (card
                                                      .distanceKm !=
                                                  null)
                                                Text(
                                                  "${card.distanceKm!.toStringAsFixed(1)} km",

                                                  style:
                                                      const TextStyle(
                                                    color:
                                                        AppColors.primary,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                            ],
                                          ),

                                          const SizedBox(
                                            height: 6,
                                          ),

                                          Text(
                                            "${card.order.items.length} item(s)",

                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors.grey,
                                            ),
                                          ),

                                          const Divider(
                                            height: 20,
                                          ),

                                          // =================================================
                                          // EARNINGS
                                          // =================================================

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
                                                      FontWeight.bold,
                                                ),
                                              ),

                                              Text(
                                                "KES ${riderEarning.toStringAsFixed(0)}",

                                                style:
                                                    const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color:
                                                      AppColors.primary,
                                                  fontSize:
                                                      16,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(
                                            height: 12,
                                          ),

                                          // =================================================
                                          // ACCEPT
                                          // =================================================

                                          SizedBox(
                                            width:
                                                double.infinity,

                                            child:
                                                ElevatedButton(
                                              onPressed:
                                                  _accepting
                                                      ? null
                                                      : () =>
                                                          _acceptJob(
                                                            card
                                                                .order
                                                                .id,
                                                          ),

                                              style:
                                                  ElevatedButton
                                                      .styleFrom(
                                                backgroundColor:
                                                    AppColors.primary,

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

                                              child:
                                                  _accepting
                                                      ? const SizedBox(
                                                          width:
                                                              20,
                                                          height:
                                                              20,

                                                          child:
                                                              CircularProgressIndicator(
                                                            color:
                                                                Colors.white,

                                                            strokeWidth:
                                                                2,
                                                          ),
                                                        )
                                                      : const Text(
                                                          "Accept Delivery",
                                                        ),
                                            ),
                                          ),
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

  // ================================================================
  // BUILD AVAILABLE JOB CARDS
  // ================================================================

  Future<List<_JobCardData>> _buildJobCards(
    List<FarmOrder> orders,
    double? riderLat,
    double? riderLng,
  ) async {
    final farmerService =
        FarmerService();

    final locationService =
        LocationService();

    final cards =
        <_JobCardData>[];

    for (final order in orders) {
      try {
        final profile =
            await farmerService
                .getFarmerProfile(
          order.farmerId,
        );

        final farmName =
            profile?['farmName']
                    ?.toString() ??
                'Farm';

        final farmLat =
            (profile?['latitude']
                    as num?)
                ?.toDouble();

        final farmLng =
            (profile?['longitude']
                    as num?)
                ?.toDouble();

        double? distance;

        // ------------------------------------------------------------
        // RIDER -> FARM DISTANCE
        //
        // Used only for sorting available jobs.
        // ------------------------------------------------------------

        if (riderLat != null &&
            riderLng != null &&
            farmLat != null &&
            farmLng != null) {
          distance =
              locationService
                  .distanceKm(
            riderLat,
            riderLng,
            farmLat,
            farmLng,
          );
        }

        cards.add(
          _JobCardData(
            order: order,
            farmName: farmName,
            distanceKm: distance,
          ),
        );
      } catch (_) {
        cards.add(
          _JobCardData(
            order: order,
            farmName: 'Farm',
            distanceKm: null,
          ),
        );
      }
    }

    return cards;
  }
}

// ====================================================================
// DASHBOARD CARD
// ====================================================================

class _DashboardCard
    extends StatelessWidget {
  final String title;

  final String value;

  final String subtitle;

  final IconData icon;

  final Color color;

  const _DashboardCard({
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
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

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
                  CrossAxisAlignment
                      .start,

              mainAxisAlignment:
                  MainAxisAlignment
                      .center,

              children: [
                Text(
                  title,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    color:
                        Colors.grey,

                    fontSize:
                        12,
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
                    fontSize:
                        20,

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

// ====================================================================
// JOB CARD DATA
// ====================================================================

class _JobCardData {
  final FarmOrder order;

  final String farmName;

  final double? distanceKm;

  _JobCardData({
    required this.order,
    required this.farmName,
    this.distanceKm,
  });
}
