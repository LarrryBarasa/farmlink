import '../core/constants/app_config.dart';
import 'location_service.dart';

class FarmLocation {
  final String farmerId;
  final double latitude;
  final double longitude;

  FarmLocation({
    required this.farmerId,
    required this.latitude,
    required this.longitude,
  });
}

class DeliveryGroup {
  final List<String> farmerIds;
  final double charge;

  DeliveryGroup({required this.farmerIds, required this.charge});
}

class DeliveryPlan {
  final List<DeliveryGroup> groups;
  final bool isSplit;

  DeliveryPlan({required this.groups, required this.isSplit});
}

class DeliveryCalculatorService {
  final LocationService _locationService = LocationService();

  DeliveryPlan calculate({
    required double consumerLat,
    required double consumerLng,
    required List<FarmLocation> farms,
  }) {
    if (farms.isEmpty) {
      return DeliveryPlan(groups: [], isSplit: false);
    }

    if (farms.length == 1) {
      final distance = _locationService.distanceKm(
        consumerLat,
        consumerLng,
        farms[0].latitude,
        farms[0].longitude,
      );

      final charge = AppConfig.baseDeliveryFee + (AppConfig.perKmRate * distance);

      return DeliveryPlan(
        groups: [DeliveryGroup(farmerIds: [farms[0].farmerId], charge: charge)],
        isSplit: false,
      );
    }

    // Check the largest distance between any two farms
    double maxPairwiseDistance = 0;
    for (var i = 0; i < farms.length; i++) {
      for (var j = i + 1; j < farms.length; j++) {
        final d = _locationService.distanceKm(
          farms[i].latitude,
          farms[i].longitude,
          farms[j].latitude,
          farms[j].longitude,
        );
        if (d > maxPairwiseDistance) maxPairwiseDistance = d;
      }
    }

    if (maxPairwiseDistance <= AppConfig.farmProximityThresholdKm) {
      // Farms close together: one combined delivery
      double farthestFromConsumer = 0;
      for (final farm in farms) {
        final d = _locationService.distanceKm(
          consumerLat,
          consumerLng,
          farm.latitude,
          farm.longitude,
        );
        if (d > farthestFromConsumer) farthestFromConsumer = d;
      }

      final extraStops = farms.length - 1;
      final charge = AppConfig.baseDeliveryFee +
          (AppConfig.perKmRate * farthestFromConsumer) +
          (AppConfig.extraStopFee * extraStops);

      return DeliveryPlan(
        groups: [
          DeliveryGroup(
            farmerIds: farms.map((f) => f.farmerId).toList(),
            charge: charge,
          ),
        ],
        isSplit: false,
      );
    }

    // Farms far apart: separate delivery per farm
    final groups = farms.map((farm) {
      final distance = _locationService.distanceKm(
        consumerLat,
        consumerLng,
        farm.latitude,
        farm.longitude,
      );
      final charge = AppConfig.baseDeliveryFee + (AppConfig.perKmRate * distance);
      return DeliveryGroup(farmerIds: [farm.farmerId], charge: charge);
    }).toList();

    return DeliveryPlan(groups: groups, isSplit: true);
  }
}