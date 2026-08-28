enum OrderStatus { pending, confirmed, delivered, cancelled }

class OrderItem {
  final String productId;
  final String name;
  final String unit;
  final int quantity;
  final double consumerUnitPrice; // what the consumer pays per unit
  final double farmerUnitPrice; // what the farmer earns per unit

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
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      unit: map['unit'] ?? '',
      quantity: map['quantity'] ?? 0,
      consumerUnitPrice: (map['consumerUnitPrice'] as num?)?.toDouble() ?? 0,
      farmerUnitPrice: (map['farmerUnitPrice'] as num?)?.toDouble() ?? 0,
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
  final String deliveryMode; // 'farmerSelf' or 'platformDelivery'
  final OrderStatus status;
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
    this.createdAt,
  });

  double get itemsSubtotal =>
      items.fold(0, (sum, item) => sum + item.subtotal);

  double get totalAmount => itemsSubtotal + deliveryCharge;

  double get farmerEarnings =>
      items.fold(0, (sum, item) => sum + item.farmerEarnings);

    factory FarmOrder.fromMap(Map<String, dynamic> map, String id) {
    return FarmOrder(
      id: id,
      farmerId: map['farmerId'] ?? '',
      consumerId: map['consumerId'] ?? '',
      consumerName: map['consumerName'] ?? '',
      consumerPhone: map['consumerPhone'] ?? '',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((i) => OrderItem.fromMap(i as Map<String, dynamic>))
          .toList(),
      deliveryCharge: (map['deliveryCharge'] as num?)?.toDouble() ?? 0,
      deliveryMode: map['deliveryMode'] ?? 'platformDelivery',
      status: OrderStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'consumerId': consumerId,
      'consumerName': consumerName,
      'consumerPhone': consumerPhone,
      'items': items.map((i) => i.toMap()).toList(),
      'deliveryCharge': deliveryCharge,
      'deliveryMode': deliveryMode,
      'status': status.name,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}