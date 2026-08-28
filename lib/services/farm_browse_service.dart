import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/farm_summary.dart';
import 'location_service.dart';

class FarmBrowseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  Stream<List<FarmSummary>> nearbyFarmsStream({
    double? consumerLat,
    double? consumerLng,
  }) {
    return _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final Map<String, int> countByFarmer = {};
      for (final doc in snapshot.docs) {
        final farmerId = doc.data()['farmerId'] as String? ?? '';
        if (farmerId.isEmpty) continue;
        countByFarmer[farmerId] = (countByFarmer[farmerId] ?? 0) + 1;
      }

      final farmerIds = countByFarmer.keys.toList();
      if (farmerIds.isEmpty) return <FarmSummary>[];

      final farmerDocs = await Future.wait(
        farmerIds.map((id) => _firestore.collection('farmers').doc(id).get()),
      );

      final summaries = <FarmSummary>[];

      for (var i = 0; i < farmerIds.length; i++) {
        final doc = farmerDocs[i];
        if (!doc.exists) continue;

        final data = doc.data() as Map<String, dynamic>;
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();

        double? distance;
        if (consumerLat != null &&
            consumerLng != null &&
            lat != null &&
            lng != null) {
          distance =
              _locationService.distanceKm(consumerLat, consumerLng, lat, lng);
        }

        summaries.add(FarmSummary(
          farmerId: farmerIds[i],
          farmName: data['farmName'] ?? 'Unnamed Farm',
          fullName: data['fullName'] ?? '',
          county: data['county'] ?? '',
          latitude: lat,
          longitude: lng,
          productCount: countByFarmer[farmerIds[i]]!,
          distanceKm: distance,
        ));
      }

      // Nearest first; farms with unknown distance go to the end
      summaries.sort((a, b) {
        if (a.distanceKm == null && b.distanceKm == null) return 0;
        if (a.distanceKm == null) return 1;
        if (b.distanceKm == null) return -1;
        return a.distanceKm!.compareTo(b.distanceKm!);
      });

      return summaries;
    });
  }
}