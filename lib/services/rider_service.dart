import 'package:cloud_firestore/cloud_firestore.dart';

class RiderService {
  final CollectionReference<Map<String, dynamic>> _riders =
      FirebaseFirestore.instance.collection('riders');

  Future<Map<String, dynamic>?> getRiderProfile(String riderId) async {
    final doc = await _riders.doc(riderId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<void> updateRiderLocation({
    required String riderId,
    required double latitude,
    required double longitude,
  }) async {
    await _riders.doc(riderId).update({
      'latitude': latitude,
      'longitude': longitude,
    });
  }
}