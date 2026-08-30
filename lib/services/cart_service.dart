import 'dart:async';

import '../models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get subtotal =>
      product.consumerPrice * quantity;
}

class CartService {
  // ================================================================
  // SINGLETON
  // ================================================================

  static final CartService _instance =
      CartService._internal();

  factory CartService() => _instance;

  CartService._internal();

  // ================================================================
  // CART ITEMS
  // ================================================================

  final List<CartItem> _items = [];

  List<CartItem> get items =>
      List.unmodifiable(_items);

  // ================================================================
  // CART CHANGE STREAM
  // ================================================================

  final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  Stream<void> get changes =>
      _changesController.stream;

  // ================================================================
  // FARMER IDS
  // ================================================================

  List<String> get farmerIds =>
      _items
          .map((item) => item.product.farmerId)
          .toSet()
          .toList();

  // ================================================================
  // ITEMS BY FARMER
  // ================================================================

  Map<String, List<CartItem>> get itemsByFarmer {
    final Map<String, List<CartItem>> grouped = {};

    for (final item in _items) {
      grouped
          .putIfAbsent(
            item.product.farmerId,
            () => [],
          )
          .add(item);
    }

    return grouped;
  }

  // ================================================================
  // SUBTOTAL
  // ================================================================

  double get subtotal =>
      _items.fold(
        0,
        (sum, item) => sum + item.subtotal,
      );

  // ================================================================
  // ITEM COUNT
  //
  // Example:
  // Tomatoes quantity 2
  // Potatoes quantity 3
  // Cart count = 5
  // ================================================================

  int get itemCount =>
      _items.fold(
        0,
        (sum, item) => sum + item.quantity,
      );

  // ================================================================
  // NOTIFY LISTENERS
  // ================================================================

  void _notifyCartChanged() {
    if (!_changesController.isClosed) {
      _changesController.add(null);
    }
  }

  // ================================================================
  // ADD PRODUCT
  // ================================================================

  void addProduct(Product product) {
    final existingIndex =
        _items.indexWhere(
      (item) =>
          item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      final existingItem =
          _items[existingIndex];

      // ------------------------------------------------------------
      // DO NOT EXCEED STOCK
      // ------------------------------------------------------------

      if (existingItem.quantity <
          product.stockQuantity) {
        existingItem.quantity++;
      }
    } else {
      // ------------------------------------------------------------
      // ONLY ADD IF THERE IS STOCK
      // ------------------------------------------------------------

      if (product.stockQuantity > 0) {
        _items.add(
          CartItem(
            product: product,
            quantity: 1,
          ),
        );
      }
    }

    // --------------------------------------------------------------
    // IMPORTANT:
    // Tell ConsumerHomeScreen that the cart changed.
    // --------------------------------------------------------------

    _notifyCartChanged();
  }

  // ================================================================
  // UPDATE QUANTITY
  // ================================================================

  void updateQuantity(
    String productId,
    int quantity,
  ) {
    final index =
        _items.indexWhere(
      (item) =>
          item.product.id == productId,
    );

    if (index < 0) return;

    // --------------------------------------------------------------
    // REMOVE ITEM IF QUANTITY IS ZERO
    // --------------------------------------------------------------

    if (quantity <= 0) {
      _items.removeAt(index);
      _notifyCartChanged();
      return;
    }

    // --------------------------------------------------------------
    // LIMIT TO AVAILABLE STOCK
    // --------------------------------------------------------------

    final maxStock =
        _items[index]
            .product
            .stockQuantity;

    if (quantity > maxStock) {
      quantity = maxStock;
    }

    // --------------------------------------------------------------
    // UPDATE
    // --------------------------------------------------------------

    _items[index].quantity =
        quantity;

    _notifyCartChanged();
  }

  // ================================================================
  // REMOVE INDIVIDUAL PRODUCT
  // ================================================================

  void removeProduct(
    String productId,
  ) {
    final oldLength =
        _items.length;

    _items.removeWhere(
      (item) =>
          item.product.id == productId,
    );

    // Only notify if something was actually removed.
    if (_items.length != oldLength) {
      _notifyCartChanged();
    }
  }

  // ================================================================
  // CLEAR ENTIRE CART
  // ================================================================

  void clear() {
    if (_items.isEmpty) return;

    _items.clear();

    _notifyCartChanged();
  }

  // ================================================================
  // DISPOSE
  // ================================================================

  void dispose() {
    _changesController.close();
  }
}