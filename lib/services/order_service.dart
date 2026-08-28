import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final CollectionReference _orders =
      FirebaseFirestore.instance.collection('orders');

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

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _orders.doc(orderId).update({'status': status.name});
  }
}