 import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/location_service.dart';
import '../../app/colors.dart';

  class LiveTrackingScreen extends StatefulWidget {
    final String orderId;
    final double destinationLat;
    final double destinationLng;
    final String destinationLabel;

    const LiveTrackingScreen({
      super.key,
      required this.orderId,
      required this.destinationLat,
      required this.destinationLng,
      required this.destinationLabel,
    });

    @override
    State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
  }

  class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
    final MapController _mapController = MapController();

    bool _hasFitBounds = false;

    // Approximate boda-boda speed.
    static const double assumedSpeedKmh = 20.0;

    String _timeAgo(DateTime? time) {
      if (time == null) {
        return 'Never';
      }

      final difference = DateTime.now().difference(time);

      if (difference.inSeconds < 60) {
        return '${difference.inSeconds}s ago';
      }

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      }

      if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      }

      return '${difference.inDays}d ago';
    }

    void _fitBounds(
      LatLng rider,
      LatLng destination,
    ) {
      if (_hasFitBounds) {
        return;
      }

      _hasFitBounds = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        final bounds = LatLngBounds.fromPoints([
          rider,
          destination,
        ]);

        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(60),
          ),
        );
      });
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Track Rider'),
        ),
        body: StreamBuilder<FarmOrder?>(
          stream: OrderService().orderStream(widget.orderId),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Unable to load tracking information.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final order = snapshot.data;

            if (order == null) {
              return const Center(
                child: Text('Order not found.'),
              );
            }

            final riderLat = order.riderLat;
            final riderLng = order.riderLng;

            if (riderLat == null || riderLng == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_off,
                        size: 60,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Your rider hasn't started sharing "
                        "their live location yet.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Status: ${order.status.name.toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final riderPoint = LatLng(
              riderLat,
              riderLng,
            );

            final destinationPoint = LatLng(
              widget.destinationLat,
              widget.destinationLng,
            );

            final distanceKm = LocationService().distanceKm(
              riderLat,
              riderLng,
              widget.destinationLat,
              widget.destinationLng,
            );

            final etaMinutes =
                (distanceKm / assumedSpeedKmh * 60).round();

            _fitBounds(
              riderPoint,
              destinationPoint,
            );

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppColors.primary,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'away',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '~$etaMinutes min',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'estimated ETA',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                  ),
                  child: Text(
                    'Last updated '
                    '${_timeAgo(order.riderLocationUpdatedAt)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),

                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: riderPoint,
                      initialZoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/'
                            '{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.example.farmlink',
                      ),

                      MarkerLayer(
                        markers: [
                          Marker(
                            point: riderPoint,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.two_wheeler,
                              color: Colors.blue,
                              size: 38,
                            ),
                          ),

                          Marker(
                            point: destinationPoint,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.destinationLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
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