import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_model.dart';

class OrderService {
  final CollectionReference _orders =
      FirebaseFirestore.instance.collection('orders');

  // ================================================================
  // GENERATE DELIVERY PIN
  // ================================================================

  static String generatePin() {
    final random = Random();

    return (1000 + random.nextInt(9000)).toString();
  }

  // ================================================================
  // CREATE ORDER
  // ================================================================

  Future<void> createOrder(
    FarmOrder order,
  ) async {
    await _orders.add(
      order.toMap(),
    );
  }

  // ================================================================
  // SINGLE ORDER STREAM
  // ================================================================

  Stream<FarmOrder?> orderStream(
    String orderId,
  ) {
    return _orders
        .doc(orderId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return null;
      }

      return FarmOrder.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    });
  }

  // ================================================================
  // FARMER ORDERS
  // ================================================================

  Stream<List<FarmOrder>> farmerOrdersStream(
    String farmerId,
  ) {
    return _orders
        .where(
          'farmerId',
          isEqualTo: farmerId,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => FarmOrder.fromMap(
                  doc.data()
                      as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  // ================================================================
  // CONSUMER ORDERS
  // ================================================================

  Stream<List<FarmOrder>> consumerOrdersStream(
    String consumerId,
  ) {
    return _orders
        .where(
          'consumerId',
          isEqualTo: consumerId,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => FarmOrder.fromMap(
                  doc.data()
                      as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  // ================================================================
  // AVAILABLE RIDER ORDERS
  // ================================================================

  Stream<List<FarmOrder>> availableOrdersStream() {
    return _orders
        .where(
          'status',
          isEqualTo: OrderStatus.pending.name,
        )
        .where(
          'riderId',
          isNull: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => FarmOrder.fromMap(
                  doc.data()
                      as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  // ================================================================
  // RIDER ORDERS
  // ================================================================

  Stream<List<FarmOrder>> riderOrdersStream(
    String riderId,
  ) {
    return _orders
        .where(
          'riderId',
          isEqualTo: riderId,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => FarmOrder.fromMap(
                  doc.data()
                      as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  // ================================================================
  // CHECK IF RIDER HAS ACTIVE DELIVERY
  // ================================================================

  Future<bool> riderHasActiveDelivery(
    String riderId,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where(
          'riderId',
          isEqualTo: riderId,
        )
        .where(
          'status',
          whereIn: [
            OrderStatus.accepted.name,
            OrderStatus.inTransit.name,
          ],
        )
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ================================================================
  // ACCEPT ORDER
  // ================================================================

  Future<bool> acceptOrder(
    String orderId,
    String riderId,
  ) async {
    final docRef = _orders.doc(orderId);

    return FirebaseFirestore.instance
        .runTransaction(
      (transaction) async {
        final snapshot =
            await transaction.get(docRef);

        final data =
            snapshot.data()
                as Map<String, dynamic>?;

        if (data == null) {
          return false;
        }

        if (data['riderId'] != null) {
          return false;
        }

        transaction.update(
          docRef,
          {
            'riderId': riderId,
            'status':
                OrderStatus.accepted.name,
          },
        );

        return true;
      },
    );
  }

  // ================================================================
  // UPDATE ORDER STATUS
  // ================================================================

  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    await _orders.doc(orderId).update(
      {
        'status': status.name,
      },
    );
  }

  // ================================================================
  // UPDATE RIDER LIVE LOCATION
  // ================================================================

  Future<void> updateRiderLiveLocation(
    String orderId,
    double lat,
    double lng,
  ) async {
    await _orders.doc(orderId).update(
      {
        'riderLat': lat,
        'riderLng': lng,

        // Firestore Timestamp is preferable to
        // storing a local DateTime string.
        'riderLocationUpdatedAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  // ================================================================
  // CLEAR RIDER LIVE LOCATION
  // ================================================================

  Future<void> clearRiderLiveLocation(
    String orderId,
  ) async {
    await _orders.doc(orderId).update(
      {
        'riderLat': FieldValue.delete(),
        'riderLng': FieldValue.delete(),
        'riderLocationUpdatedAt':
            FieldValue.delete(),
      },
    );
  }

  // ================================================================
  // CONFIRM DELIVERY WITH PIN
  // ================================================================

  Future<bool> confirmDeliveryWithPin(
    String orderId,
    String enteredPin,
  ) async {
    final docRef = _orders.doc(orderId);

    return FirebaseFirestore.instance
        .runTransaction(
      (transaction) async {
        final snapshot =
            await transaction.get(docRef);

        final data =
            snapshot.data()
                as Map<String, dynamic>?;

        if (data == null) {
          return false;
        }

        if (data['pinCode'] != enteredPin) {
          return false;
        }

        transaction.update(
          docRef,
          {
            'status':
                OrderStatus.delivered.name,

            'riderLat':
                FieldValue.delete(),

            'riderLng':
                FieldValue.delete(),

            'riderLocationUpdatedAt':
                FieldValue.delete(),
          },
        );

        return true;
      },
    );
  }
}
