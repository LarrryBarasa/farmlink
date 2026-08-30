import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final CollectionReference _orders =
      FirebaseFirestore.instance.collection('orders');

  static String generatePin() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString(); // 1000-9999
  }

  Future<void> createOrder(FarmOrder order) async {
    await _orders.add(order.toMap());
  }

  Stream<List<FarmOrder>> farmerOrdersStream(String farmerId) {
    return _orders
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                FarmOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<FarmOrder>> consumerOrdersStream(String consumerId) {
    return _orders
        .where('consumerId', isEqualTo: consumerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                FarmOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<FarmOrder>> availableOrdersStream() {
    return _orders
        .where('status', isEqualTo: OrderStatus.pending.name)
        .where('riderId', isNull: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                FarmOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<FarmOrder>> riderOrdersStream(String riderId) {
    return _orders
        .where('riderId', isEqualTo: riderId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                FarmOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<bool> acceptOrder(String orderId, String riderId) async {
    final docRef = _orders.doc(orderId);

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data() as Map<String, dynamic>?;

      if (data == null) return false;
      if (data['riderId'] != null) return false;

      transaction.update(docRef, {
        'riderId': riderId,
        'status': OrderStatus.accepted.name,
      });

      return true;
    });
  }

  // Marks delivered only if the entered PIN matches. Returns true on success.
  Future<bool> confirmDeliveryWithPin(String orderId, String enteredPin) async {
    final docRef = _orders.doc(orderId);

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data() as Map<String, dynamic>?;

      if (data == null) return false;
      if (data['pinCode'] != enteredPin) return false;

      transaction.update(docRef, {'status': OrderStatus.delivered.name});
      return true;
    });
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _orders.doc(orderId).update({'status': status.name});
  }
}