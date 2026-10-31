import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../../models/order_model.dart';
import '../auth/login_screen.dart';

class AdminMobileDashboard extends StatefulWidget {
  const AdminMobileDashboard({super.key});

  @override
  State<AdminMobileDashboard> createState() => _AdminMobileDashboardState();
}

class _AdminMobileDashboardState extends State<AdminMobileDashboard> {
  late Future<AdminStats> _statsFuture;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _perPage = 3;

  @override
  void initState() {
    super.initState();
    _statsFuture = AdminService().getSystemStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _statsFuture = AdminService().getSystemStats());
  }

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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Farmlink Admin",
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh, color: Colors.black)),
          IconButton(onPressed: () => _logout(context), icon: const Icon(Icons.logout, color: Colors.black)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Welcome, Admin",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<AdminStats>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Could not load stats: ${snapshot.error}", style: const TextStyle(color: Colors.red));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final stats = snapshot.data!;
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.4,
                  children: [
                    _StatCard(title: "Farmers", value: "${stats.totalFarmers}", icon: Icons.agriculture, color: Colors.green),
                    _StatCard(title: "Consumers", value: "${stats.totalConsumers}", icon: Icons.people, color: Colors.blue),
                    _StatCard(title: "Riders", value: "${stats.totalRiders}", icon: Icons.delivery_dining, color: Colors.orange),
                    _StatCard(title: "Orders", value: "${stats.totalOrders}", icon: Icons.receipt_long, color: Colors.purple),
                    _StatCard(title: "Delivered", value: "${stats.deliveredOrders}", icon: Icons.check_circle, color: Colors.teal),
                    _StatCard(title: "Revenue", value: "KES ${stats.platformRevenue.toStringAsFixed(0)}", icon: Icons.payments, color: AppColors.primary),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const Text("Payments Needing Approval", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              "Once automated payouts are live, only failed ones will appear here.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 0;
                });
              },
              decoration: InputDecoration(
                hintText: "Search by consumer name...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<FarmOrder>>(
              stream: AdminService().pendingPayoutOrdersStream(),
              builder: (context, snapshot) {
                final allOrders = snapshot.data ?? [];

                final filtered = _searchQuery.isEmpty
                    ? allOrders
                    : allOrders
                        .where((o) => o.consumerName
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      allOrders.isEmpty ? "No pending payouts." : "No matches for \"$_searchQuery\".",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final totalPages = (filtered.length / _perPage).ceil();
                if (_currentPage >= totalPages) _currentPage = totalPages - 1;
                if (_currentPage < 0) _currentPage = 0;

                final start = _currentPage * _perPage;
                final end = (start + _perPage) > filtered.length ? filtered.length : start + _perPage;
                final pageOrders = filtered.sublist(start, end);

                return Column(
                  children: [
                    ...pageOrders.map((order) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(order.consumerName),
                          subtitle: Text(
                            "Farmer: KES ${order.farmerEarnings.toStringAsFixed(0)} · Delivery: KES ${order.deliveryCharge.toStringAsFixed(0)}",
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => AdminService().markOrderPaidOut(order.id),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                            child: const Text("Mark Paid"),
                          ),
                        ),
                      );
                    }),
                    if (totalPages > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text("Page ${_currentPage + 1} of $totalPages"),
                          IconButton(
                            onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}