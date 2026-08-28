import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../models/product_model.dart';
import 'cart_screen.dart';

class FarmProductsScreen extends StatefulWidget {
  final String farmerId;
  final String farmName;

  const FarmProductsScreen({
    super.key,
    required this.farmerId,
    required this.farmName,
  });

  @override
  State<FarmProductsScreen> createState() => _FarmProductsScreenState();
}

class _FarmProductsScreenState extends State<FarmProductsScreen> {
  late final Stream<List<Product>> _productsStream;

  @override
  void initState() {
    super.initState();
    _productsStream = ProductService().farmActiveProductsStream(widget.farmerId);
  }

    void _addToCart(Product product) {
    CartService().addProduct(product);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${product.name} added to cart")),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.farmName),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _productsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Text(
                "This farm has no products listed right now.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.green.withValues(alpha: 0.15),
                    child: const Icon(Icons.eco, color: Colors.green),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "KES ${product.consumerPrice.toStringAsFixed(0)} / ${product.unit} · ${product.stockQuantity} available",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
                    onPressed: () => _addToCart(product),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}