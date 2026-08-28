import 'package:cloud_firestore/cloud_firestore.dart';

class ConsumerService {
  final CollectionReference<Map<String, dynamic>> _consumers =
      FirebaseFirestore.instance.collection('consumers');

  Future<Map<String, dynamic>?> getConsumerProfile(
    String consumerId,
  ) async {
    final doc = await _consumers.doc(consumerId).get();

    if (!doc.exists) {
      return null;
    }

    return doc.data();
  }

  Future<void> updateConsumerLocation({
    required String consumerId,
    required double latitude,
    required double longitude,
  }) async {
    await _consumers.doc(consumerId).update({
      'latitude': latitude,
      'longitude': longitude,
    });
  }
}
