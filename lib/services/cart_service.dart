import '../models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.consumerPrice * quantity;
}

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  List<String> get farmerIds =>
      _items.map((item) => item.product.farmerId).toSet().toList();

  Map<String, List<CartItem>> get itemsByFarmer {
    final Map<String, List<CartItem>> grouped = {};
    for (final item in _items) {
      grouped.putIfAbsent(item.product.farmerId, () => []).add(item);
    }
    return grouped;
  }

  double get subtotal =>
      _items.fold(0, (sum, item) => sum + item.subtotal);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  void addProduct(Product product) {
    final existingIndex =
        _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;

    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = quantity;
    }
  }

  void removeProduct(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
  }

  void clear() {
    _items.clear();
  }
}