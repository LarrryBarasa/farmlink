import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';
import '../auth/login_screen.dart';
import 'add_edit_product_screen.dart';

class FarmerHomeScreen extends StatelessWidget {
  const FarmerHomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService().signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please log in again.')));
    }

    final farmerId = currentUser.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Farmlink',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.black),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditProductScreen(farmerId: farmerId),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: StreamBuilder<List<Product>>(
        stream: ProductService().farmerProductsStream(farmerId),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Text(
                  'Could not load your products.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  "You haven't listed any products yet.\n"
                  "Tap + to add your first one.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
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
                    backgroundImage:
                        product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? NetworkImage(product.imageUrl!)
                        : null,
                    child: product.imageUrl == null || product.imageUrl!.isEmpty
                        ? const Icon(Icons.eco, color: Colors.green)
                        : null,
                  ),

                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Text(
                    'KES ${product.farmerPrice.toStringAsFixed(0)} '
                    '/ ${product.unit} · '
                    'Stock: ${product.stockQuantity}',
                  ),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditProductScreen(
                          farmerId: farmerId,
                          existingProduct: product,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
