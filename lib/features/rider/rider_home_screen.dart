import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_config.dart';
import '../../services/auth_service.dart';
import '../../services/rider_service.dart';
import '../../services/farmer_service.dart';
import '../../services/order_service.dart';
import '../../services/location_service.dart';
import '../../models/order_model.dart';
import '../auth/login_screen.dart';
import 'package:flutter/services.dart';
import 'my_deliveries_screen.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  late final String _riderId;
  late final Future<Map<String, dynamic>?> _riderProfileFuture;
  late final Stream<List<FarmOrder>> _availableOrdersStream;

  bool _accepting = false;

  // Tracks delivery jobs already seen by the rider.
  Set<String> _seenOrderIds = {};

  // Prevents haptic feedback from triggering for every job
  // during the initial stream load.
  bool _firstLoad = true;

  @override
  void initState() {
    super.initState();
    _riderId = AuthService().currentUser!.uid;
    _riderProfileFuture = RiderService().getRiderProfile(_riderId);
    _availableOrdersStream = OrderService().availableOrdersStream();
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().signOut();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _acceptJob(String orderId) async {
    setState(() => _accepting = true);

    try {
      final success = await OrderService().acceptOrder(orderId, _riderId);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Job accepted! Check the truck icon above."),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Too late — another rider already took this job."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not accept job: $e")),
      );
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Farmlink",
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyDeliveriesScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.local_shipping,
              color: Colors.black,
            ),
          ),
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(
              Icons.logout,
              color: Colors.black,
            ),
          ),
        ],
      ),

      body: FutureBuilder<Map<String, dynamic>?>(
        future: _riderProfileFuture,
        builder: (context, riderSnapshot) {
          final riderData = riderSnapshot.data;
          final riderLat = (riderData?['latitude'] as num?)?.toDouble();
          final riderLng = (riderData?['longitude'] as num?)?.toDouble();
          final riderName = riderData?['fullName'] ?? '';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riderName.isNotEmpty
                      ? "Welcome back, $riderName 🚴"
                      : "Welcome back 🚴",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Available Deliveries",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (riderLat == null || riderLng == null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    "Your location isn't set, so jobs can't be sorted by distance.",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 13,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                Expanded(
                  child: StreamBuilder<List<FarmOrder>>(
                    stream: _availableOrdersStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final orders = snapshot.data ?? [];

                      // Detect newly available delivery jobs.
                      final currentIds =
                          orders.map((o) => o.id).toSet();

                      if (!_firstLoad) {
                        final newIds =
                            currentIds.difference(_seenOrderIds);

                        if (newIds.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            HapticFeedback.vibrate();
                          });
                        }
                      } else {
                        _firstLoad = false;
                      }

                      _seenOrderIds = currentIds;

                      if (orders.isEmpty) {
                        return const Center(
                          child: Text(
                            "No delivery jobs available right now.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return FutureBuilder<List<_JobCardData>>(
                        future: _buildJobCards(
                          orders,
                          riderLat,
                          riderLng,
                        ),
                        builder: (context, cardsSnapshot) {
                          if (!cardsSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final cards = cardsSnapshot.data!;

                          cards.sort((a, b) {
                            if (a.distanceKm == null &&
                                b.distanceKm == null) {
                              return 0;
                            }

                            if (a.distanceKm == null) return 1;
                            if (b.distanceKm == null) return -1;

                            return a.distanceKm!
                                .compareTo(b.distanceKm!);
                          });

                          return ListView.builder(
                            itemCount: cards.length,
                            itemBuilder: (context, index) {
                              final card = cards[index];

                              final riderEarning =
                                  card.order.deliveryCharge *
                                      (1 -
                                          AppConfig
                                              .deliveryCommissionRate);

                              return Card(
                                margin:
                                    const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              card.farmName,
                                              style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          if (card.distanceKm != null)
                                            Text(
                                              "${card.distanceKm!.toStringAsFixed(1)} km",
                                              style: const TextStyle(
                                                color:
                                                    AppColors.primary,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      Text(
                                        "${card.order.items.length} item(s)",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                        children: [
                                          Text(
                                            "You earn: KES ${riderEarning.toStringAsFixed(0)}",
                                            style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                              color:
                                                  AppColors.primary,
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: _accepting
                                                ? null
                                                : () => _acceptJob(
                                                      card.order.id,
                                                    ),
                                            style:
                                                ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              foregroundColor:
                                                  Colors.white,
                                            ),
                                            child:
                                                const Text("Accept"),
                                          ),
                                        ],
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
      ),
    );
  }

  Future<List<_JobCardData>> _buildJobCards(
    List<FarmOrder> orders,
    double? riderLat,
    double? riderLng,
  ) async {
    final farmerService = FarmerService();
    final locationService = LocationService();
    final cards = <_JobCardData>[];

    for (final order in orders) {
      final profile =
          await farmerService.getFarmerProfile(order.farmerId);

      final farmName = profile?['farmName'] ?? 'Farm';
      final farmLat =
          (profile?['latitude'] as num?)?.toDouble();
      final farmLng =
          (profile?['longitude'] as num?)?.toDouble();

      double? distance;

      if (riderLat != null &&
          riderLng != null &&
          farmLat != null &&
          farmLng != null) {
        distance = locationService.distanceKm(
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
    }

    return cards;
  }
}

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