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

  double get subtotal => consumerUnitPrice * quantity;

  double get farmerEarnings => farmerUnitPrice * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
      quantity: _safeInt(map['quantity']),
      consumerUnitPrice: _safeDouble(
        map['consumerUnitPrice'],
      ),
      farmerUnitPrice: _safeDouble(
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
      'consumerUnitPrice': consumerUnitPrice,
      'farmerUnitPrice': farmerUnitPrice,
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

  /// Distance from FARM -> CONSUMER.
  ///
  /// This is the distance we use for the rider's
  /// "KMs Done" dashboard.
  final double deliveryDistanceKm;

  final String deliveryMode;

  final OrderStatus status;

  final String? riderId;

  final String pinCode;

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
    this.createdAt,
  });

  // ================================================================
  // ORDER TOTALS
  // ================================================================

  double get itemsSubtotal {
    return items.fold<double>(
      0.0,
      (sum, item) => sum + item.subtotal,
    );
  }

  double get totalAmount {
    return itemsSubtotal + deliveryCharge;
  }

  double get farmerEarnings {
    return items.fold<double>(
      0.0,
      (sum, item) => sum + item.farmerEarnings,
    );
  }

  // ================================================================
  // FROM FIREBASE
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
                item as Map,
              ),
            ),
          )
          .toList();
    }

    return FarmOrder(
      id: id,

      farmerId: map['farmerId']?.toString() ?? '',

      consumerId: map['consumerId']?.toString() ?? '',

      consumerName:
          map['consumerName']?.toString() ?? '',

      consumerPhone:
          map['consumerPhone']?.toString() ?? '',

      items: parsedItems,

      deliveryCharge: _safeDouble(
        map['deliveryCharge'],
      ),

      // ============================================================
      // FARM -> CONSUMER DISTANCE
      //
      // IMPORTANT:
      // This is NOT rider -> farm distance.
      //
      // It is the stored distance for the actual delivery.
      // ============================================================

      deliveryDistanceKm: _safeDouble(
        map['deliveryDistanceKm'],
      ),

      deliveryMode:
          map['deliveryMode']?.toString() ??
              'platformDelivery',

      status: OrderStatus.values.firstWhere(
        (status) =>
            status.name == map['status']?.toString(),
        orElse: () => OrderStatus.pending,
      ),

      riderId: map['riderId']?.toString(),

      pinCode: map['pinCode']?.toString() ?? '',

      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(
              map['createdAt'].toString(),
            )
          : null,
    );
  }

  // ================================================================
  // TO FIREBASE
  // ================================================================

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,

      'consumerId': consumerId,

      'consumerName': consumerName,

      'consumerPhone': consumerPhone,

      'items': items
          .map((item) => item.toMap())
          .toList(),

      'deliveryCharge': deliveryCharge,

      // ============================================================
      // FARM -> CONSUMER DISTANCE
      // ============================================================

      'deliveryDistanceKm': deliveryDistanceKm,

      'deliveryMode': deliveryMode,

      'status': status.name,

      'riderId': riderId,

      'pinCode': pinCode,

      'createdAt':
          createdAt?.toIso8601String() ??
              DateTime.now().toIso8601String(),
    };
  }
}

// ====================================================================
// SAFE FIREBASE NUMBER HELPERS
// ====================================================================

double _safeDouble(dynamic value) {
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

int _safeInt(dynamic value) {
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
