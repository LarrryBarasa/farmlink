import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../services/farmer_service.dart';
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
    final farmerId = AuthService().currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Farmlink",
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

      body: FutureBuilder<Map<String, dynamic>?>(
        future: FarmerService().getFarmerProfile(farmerId),
        builder: (context, profileSnapshot) {
          final profile = profileSnapshot.data;
          final farmerName = profile?['fullName'] ?? '';
          final farmName = profile?['farmName'] ?? '';

          return StreamBuilder<List<Product>>(
            stream: ProductService().farmerProductsStream(farmerId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = snapshot.data ?? [];
              final totalProducts = products.length;
              final totalStock = products.fold<int>(
                0,
                (sum, p) => sum + p.stockQuantity,
              );
              final activeListings = products.where((p) => p.isActive).length;
              final inventoryValue = products.fold<double>(
                0,
                (sum, p) => sum + (p.farmerPrice * p.stockQuantity),
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Dashboard header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farmerName.isNotEmpty
                              ? "Welcome back, $farmerName 🌱"
                              : "Welcome back 🌱",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        if (farmName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            farmName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatBlock(
                              label: "Products",
                              value: "$totalProducts",
                            ),
                            _StatBlock(
                              label: "Active",
                              value: "$activeListings",
                            ),
                            _StatBlock(
                              label: "Total Stock",
                              value: "$totalStock",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Your Products",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  if (products.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          "You haven't listed any products yet.\nTap + to add your first one.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...products.map(
                      (product) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.green.withOpacity(0.15),
                            backgroundImage: product.imageUrl != null
                                ? NetworkImage(product.imageUrl!)
                                : null,
                            child: product.imageUrl == null
                                ? const Icon(Icons.eco, color: Colors.green)
                                : null,
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "KES ${product.farmerPrice.toStringAsFixed(0)} / ${product.unit} · Stock: ${product.stockQuantity}",
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
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;

  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
