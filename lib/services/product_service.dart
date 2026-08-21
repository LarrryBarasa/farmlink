import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  // Commission rate applied to every new product.
  // Change this value when your business commission changes.
  static const double defaultCommissionRate = 0.10;

  // Add a new product
  Future<void> addProduct({
    required String farmerId,
    required String name,
    required ProductCategory category,
    required double farmerPrice,
    required String unit,
    required int stockQuantity,
    required DeliveryMode deliveryMode,
    double? farmerDeliveryCharge,
    String? imageUrl,
  }) async {
    final product = Product(
      id: '',
      farmerId: farmerId,
      name: name,
      category: category,
      farmerPrice: farmerPrice,
      commissionRate: defaultCommissionRate,
      unit: unit,
      stockQuantity: stockQuantity,
      deliveryMode: deliveryMode,
      farmerDeliveryCharge: farmerDeliveryCharge,
      imageUrl: imageUrl,
      isActive: true,
    );

    await _products.add(product.toMap());
  }

  // Get all products belonging to a farmer
  Stream<List<Product>> getFarmerProducts(String farmerId) {
    return _products.where('farmerId', isEqualTo: farmerId).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get a single product
  Future<Product?> getProduct(String productId) async {
    final doc = await _products.doc(productId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return Product.fromMap(doc.data()!, doc.id);
  }

  // Update an existing product
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    await _products.doc(productId).update(updates);
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    await _products.doc(productId).delete();
  }

  // Activate/deactivate a product
  Future<void> setProductActive(String productId, bool isActive) async {
    await _products.doc(productId).update({'isActive': isActive});
  }

  // Update stock quantity
  Future<void> updateStock(String productId, int quantity) async {
    await _products.doc(productId).update({'stockQuantity': quantity});
  }

  Stream<List<Product>> farmerProductsStream(String farmerId) {
    return _products.where('farmerId', isEqualTo: farmerId).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return Product.fromap(doc.data(), doc.id);
      }).toList();
    });
  }
}
