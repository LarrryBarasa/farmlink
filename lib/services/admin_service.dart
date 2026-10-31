import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_config.dart';
import '../models/order_model.dart';

class AdminStats {
  final int totalFarmers;
  final int totalConsumers;
  final int totalRiders;
  final int totalOrders;
  final int deliveredOrders;
  final double platformRevenue;

  AdminStats({
    required this.totalFarmers,
    required this.totalConsumers,
    required this.totalRiders,
    required this.totalOrders,
    required this.deliveredOrders,
    required this.platformRevenue,
  });
}

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AdminStats> getSystemStats() async {
    final farmersSnap = await _firestore.collection('farmers').get();
    final consumersSnap = await _firestore.collection('consumers').get();
    final ridersSnap = await _firestore.collection('riders').get();
    final ordersSnap = await _firestore.collection('orders').get();

    final orders = ordersSnap.docs
        .map((doc) => FarmOrder.fromMap(doc.data(), doc.id))
        .toList();

    final delivered =
        orders.where((o) => o.status == OrderStatus.delivered).toList();

    double revenue = 0;
    for (final order in delivered) {
      final productCommission = order.itemsSubtotal - order.farmerEarnings;
      revenue += productCommission;
      revenue += order.deliveryCharge * AppConfig.deliveryCommissionRate;
    }

    return AdminStats(
      totalFarmers: farmersSnap.docs.length,
      totalConsumers: consumersSnap.docs.length,
      totalRiders: ridersSnap.docs.length,
      totalOrders: ordersSnap.docs.length,
      deliveredOrders: delivered.length,
      platformRevenue: revenue,
    );
  }

  Stream<List<Map<String, dynamic>>> usersStream(String collectionName) {
    return _firestore.collection(collectionName).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  Future<void> setUserDisabled(
    String collectionName,
    String userId,
    bool disabled,
  ) async {
    await _firestore.collection(collectionName).doc(userId).update({
      'isDisabled': disabled,
    });
  }

  Stream<List<FarmOrder>> pendingPayoutOrdersStream() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.delivered.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FarmOrder.fromMap(doc.data(), doc.id))
            .where((order) => !order.isPaidOut)
            .toList());
  }

  Future<void> markOrderPaidOut(String orderId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'isPaidOut': true,
    });
  }


    Future<void> deleteUser(String collectionName, String userId) async {
    await _firestore.collection(collectionName).doc(userId).delete();
  }


}