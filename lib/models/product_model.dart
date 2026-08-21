enum ProductCategory { crop, animal, dairy, other }

enum DeliveryMode { farmerSelf, platformDelivery, both }

class Product {
  final String id;
  final String farmerId;
  final String name;
  final ProductCategory category;
  final double farmerPrice; // raw price farmer set — never shown to consumer
  final double commissionRate; // locked in at creation time
  final String unit;
  final int stockQuantity;
  final DeliveryMode deliveryMode;
  final double? farmerDeliveryCharge;
  final String? imageUrl;
  final bool isActive;

  Product({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.category,
    required this.farmerPrice,
    required this.commissionRate,
    required this.unit,
    required this.stockQuantity,
    required this.deliveryMode,
    this.farmerDeliveryCharge,
    this.imageUrl,
    this.isActive = true,
  });

  // What the consumer actually sees — commission baked in
  double get consumerPrice => farmerPrice * (1 + commissionRate);

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      farmerId: map['farmerId'] ?? '',
      name: map['name'] ?? '',
      category: ProductCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ProductCategory.other,
      ),
      farmerPrice: (map['farmerPrice'] as num?)?.toDouble() ?? 0,
      commissionRate: (map['commissionRate'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] ?? '',
      stockQuantity: map['stockQuantity'] ?? 0,
      deliveryMode: DeliveryMode.values.firstWhere(
        (e) => e.name == map['deliveryMode'],
        orElse: () => DeliveryMode.platformDelivery,
      ),
      farmerDeliveryCharge: map['farmerDeliveryCharge'] != null
          ? (map['farmerDeliveryCharge'] as num).toDouble()
          : null,
      imageUrl: map['imageUrl'],
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'name': name,
      'category': category.name,
      'farmerPrice': farmerPrice,
      'commissionRate': commissionRate,
      'unit': unit,
      'stockQuantity': stockQuantity,
      'deliveryMode': deliveryMode.name,
      'farmerDeliveryCharge': farmerDeliveryCharge,
      'imageUrl': imageUrl,
      'isActive': isActive,
    };
  }
}
