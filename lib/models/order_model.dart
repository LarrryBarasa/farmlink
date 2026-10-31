import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  accepted,
  inTransit,
  delivered,
  cancelled,
}

class OrderItem {
  final String productId;
  final String name;
  final String unit;
  final int quantity;
  final double consumerUnitPrice;
  final double farmerUnitPrice;

  OrderItem({
    required this.productId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.consumerUnitPrice,
    required this.farmerUnitPrice,
  });

  double get subtotal =>
      consumerUnitPrice * quantity;

  double get farmerEarnings =>
      farmerUnitPrice * quantity;

  factory OrderItem.fromMap(
    Map<String, dynamic> map,
  ) {
    return OrderItem(
      productId:
          map['productId']?.toString() ?? '',
      name:
          map['name']?.toString() ?? '',
      unit:
          map['unit']?.toString() ?? '',
      quantity:
          _safeInt(map['quantity']),
      consumerUnitPrice:
          _safeDouble(
        map['consumerUnitPrice'],
      ),
      farmerUnitPrice:
          _safeDouble(
        map['farmerUnitPrice'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'unit': unit,
      'quantity': quantity,
      'consumerUnitPrice':
          consumerUnitPrice,
      'farmerUnitPrice':
          farmerUnitPrice,
    };
  }
}

class FarmOrder {
  final String id;
  final String farmerId;
  final String consumerId;
  final String consumerName;
  final String consumerPhone;
  final List<OrderItem> items;
  final double deliveryCharge;
  final double deliveryDistanceKm;
  final String deliveryMode;
  final OrderStatus status;
  final String? riderId;
  final String pinCode;
  final bool isPaidOut;

  final double? riderLat;
  final double? riderLng;

  final DateTime? riderLocationUpdatedAt;
  final DateTime? createdAt;

  FarmOrder({
    required this.id,
    required this.farmerId,
    required this.consumerId,
    required this.consumerName,
    required this.consumerPhone,
    required this.items,
    required this.deliveryCharge,
    required this.deliveryMode,
    required this.status,
    this.deliveryDistanceKm = 0.0,
    this.riderId,
    this.pinCode = '',
    this.isPaidOut = false,
    this.riderLat,
    this.riderLng,
    this.riderLocationUpdatedAt,
    this.createdAt,
  });

  // ================================================================
  // ITEMS SUBTOTAL
  // ================================================================

  double get itemsSubtotal =>
      items.fold<double>(
        0.0,
        (sum, item) =>
            sum + item.subtotal,
      );

  // ================================================================
  // TOTAL AMOUNT
  // ================================================================

  double get totalAmount =>
      itemsSubtotal + deliveryCharge;

  // ================================================================
  // MAX DELIVERY MINUTES
  // ================================================================

  int get maxDeliveryMinutes {
    const bufferMinutes = 15;
    const speedKmh = 25.0;

    final travelMinutes =
        (deliveryDistanceKm / speedKmh) * 60;

    final total =
        bufferMinutes + travelMinutes;

    return total > 90
        ? 90
        : total.round();
  }

  // ================================================================
  // FARMER EARNINGS
  // ================================================================

  double get farmerEarnings =>
      items.fold<double>(
        0.0,
        (sum, item) =>
            sum + item.farmerEarnings,
      );

  // ================================================================
  // FROM FIRESTORE
  // ================================================================

  factory FarmOrder.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    final rawItems = map['items'];

    List<OrderItem> parsedItems = [];

    if (rawItems is List) {
      parsedItems = rawItems
          .whereType<Map>()
          .map(
            (item) => OrderItem.fromMap(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          )
          .toList();
    }

    return FarmOrder(
      id: id,

      farmerId:
          map['farmerId']?.toString() ?? '',

      consumerId:
          map['consumerId']?.toString() ?? '',

      consumerName:
          map['consumerName']?.toString() ?? '',

      consumerPhone:
          map['consumerPhone']?.toString() ?? '',

      items: parsedItems,

      deliveryCharge:
          _safeDouble(
        map['deliveryCharge'],
      ),

      deliveryDistanceKm:
          _safeDouble(
        map['deliveryDistanceKm'],
      ),

      deliveryMode:
          map['deliveryMode']?.toString() ??
              'platformDelivery',

      status:
          OrderStatus.values.firstWhere(
        (status) =>
            status.name ==
            map['status']?.toString(),
        orElse: () =>
            OrderStatus.pending,
      ),

      riderId:
          map['riderId']?.toString(),

      pinCode:
          map['pinCode']?.toString() ?? '',
                isPaidOut: map['isPaidOut'] == true,

      riderLat:
          (map['riderLat'] as num?)
              ?.toDouble(),

      riderLng:
          (map['riderLng'] as num?)
              ?.toDouble(),

      riderLocationUpdatedAt:
          _parseDateTime(
        map['riderLocationUpdatedAt'],
      ),

      createdAt:
          _parseDateTime(
        map['createdAt'],
      ),
    );
  }

  // ================================================================
  // TO FIRESTORE
  // ================================================================

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'consumerId': consumerId,
      'consumerName': consumerName,
      'consumerPhone': consumerPhone,

      'items': items
          .map(
            (item) => item.toMap(),
          )
          .toList(),

      'deliveryCharge':
          deliveryCharge,

      'deliveryDistanceKm':
          deliveryDistanceKm,

      'deliveryMode':
          deliveryMode,

      'status':
          status.name,

      'riderId':
          riderId,

      'pinCode':
          pinCode,
                'isPaidOut': isPaidOut,

      'riderLat':
          riderLat,

      'riderLng':
          riderLng,

      'riderLocationUpdatedAt':
          riderLocationUpdatedAt != null
              ? Timestamp.fromDate(
                  riderLocationUpdatedAt!,
                )
              : null,

      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(
                  createdAt!,
                )
              : FieldValue.serverTimestamp(),
    };
  }
}

// ====================================================================
// DATE PARSER
// ====================================================================

DateTime? _parseDateTime(
  dynamic value,
) {
  if (value == null) {
    return null;
  }

  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value);
  }

  return null;
}

// ====================================================================
// DOUBLE
// ====================================================================

double _safeDouble(
  dynamic value,
) {
  if (value == null) {
    return 0.0;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }

  return 0.0;
}

// ====================================================================
// INT
// ====================================================================

int _safeInt(
  dynamic value,
) {
  if (value == null) {
    return 0;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? 0;
  }

  return 0;
}
