import 'package:cloud_firestore/cloud_firestore.dart';

class FarmerService {
  final CollectionReference<Map<String, dynamic>> _farmers =
      FirebaseFirestore.instance.collection('farmers');

  Future<Map<String, dynamic>?> getFarmerProfile(String farmerId) async {
    final doc = await _farmers.doc(farmerId).get();

    if (!doc.exists) {
      return null;
    }

    return doc.data();
  }

  Future<void> updateFarmerLocation({
    required String farmerId,
    required double latitude,
    required double longitude,
  }) async {
    await _farmers.doc(farmerId).update({
      'latitude': latitude,
      'longitude': longitude,
    });
  }
}
