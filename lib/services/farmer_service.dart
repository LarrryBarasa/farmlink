import 'package:cloud_firestore/cloud_firestore.dart';

class FarmerService {
  final CollectionReference _farmers = FirebaseFirestore.instance.collection(
    'farmers',
  );

  Future<Map<String, dynamic>?> getFarmerProfile(String farmerId) async {
    final doc = await _farmers.doc(farmerId).get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>?;
  }
}
