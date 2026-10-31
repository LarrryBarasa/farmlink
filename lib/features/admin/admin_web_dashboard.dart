import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../../models/order_model.dart';
import '../auth/login_screen.dart';

class AdminWebDashboard extends StatefulWidget {
  const AdminWebDashboard({super.key});

  @override
  State<AdminWebDashboard> createState() => _AdminWebDashboardState();
}

class _AdminWebDashboardState extends State<AdminWebDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<AdminStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _statsFuture = AdminService().getSystemStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Overview"),
            Tab(text: "Users"),
            Tab(text: "Payments"),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () =>
                setState(() => _statsFuture = AdminService().getSystemStats()),
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.black),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(statsFuture: _statsFuture),
          const _UsersTab(),
          const _PaymentsTab(),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Future<AdminStats> statsFuture;
  const _OverviewTab({required this.statsFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminStats>(
      future: statsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Could not load stats: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      title: "Farmers",
                      value: "${stats.totalFarmers}",
                      icon: Icons.agriculture,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      title: "Consumers",
                      value: "${stats.totalConsumers}",
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      title: "Riders",
                      value: "${stats.totalRiders}",
                      icon: Icons.delivery_dining,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      title: "Orders",
                      value: "${stats.totalOrders}",
                      icon: Icons.receipt_long,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      title: "Delivered",
                      value: "${stats.deliveredOrders}",
                      icon: Icons.check_circle,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      title: "Revenue",
                      value: "KES ${stats.platformRevenue.toStringAsFixed(0)}",
                      icon: Icons.payments,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                "System Overview",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                height: 280,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY:
                        [
                              stats.totalFarmers,
                              stats.totalConsumers,
                              stats.totalRiders,
                              stats.totalOrders,
                              stats.deliveredOrders,
                            ].reduce((a, b) => a > b ? a : b).toDouble() *
                            1.2 +
                        1,
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const labels = [
                              "Farmers",
                              "Consumers",
                              "Riders",
                              "Orders",
                              "Delivered",
                            ];
                            final index = value.toInt();
                            if (index < 0 || index >= labels.length)
                              return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                labels[index],
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    barGroups: [
                      _bar(0, stats.totalFarmers.toDouble(), Colors.green),
                      _bar(1, stats.totalConsumers.toDouble(), Colors.blue),
                      _bar(2, stats.totalRiders.toDouble(), Colors.orange),
                      _bar(3, stats.totalOrders.toDouble(), Colors.purple),
                      _bar(4, stats.deliveredOrders.toDouble(), Colors.teal),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  BarChartGroupData _bar(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: color,
          width: 28,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String _selectedCollection = 'farmers';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _perPage = 5;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String userId,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete User"),
        content: Text(
          "Are you sure you want to permanently delete $name? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AdminService().deleteUser(_selectedCollection, userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'farmers', label: Text('Farmers')),
                  ButtonSegment(value: 'consumers', label: Text('Consumers')),
                  ButtonSegment(value: 'riders', label: Text('Riders')),
                ],
                selected: {_selectedCollection},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedCollection = selection.first;
                    _currentPage = 0;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 0;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search by name...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: AdminService().usersStream(_selectedCollection),
            builder: (context, snapshot) {
              final allUsers = snapshot.data ?? [];

              final filtered = _searchQuery.isEmpty
                  ? allUsers
                  : allUsers.where((u) {
                      final name = (u['fullName'] ?? u['farmName'] ?? '')
                          .toString()
                          .toLowerCase();
                      return name.contains(_searchQuery.toLowerCase());
                    }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    allUsers.isEmpty
                        ? "No users found."
                        : "No matches for \"$_searchQuery\".",
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }

              final totalPages = (filtered.length / _perPage).ceil();
              if (_currentPage >= totalPages) _currentPage = totalPages - 1;
              if (_currentPage < 0) _currentPage = 0;

              final start = _currentPage * _perPage;
              final end = (start + _perPage) > filtered.length
                  ? filtered.length
                  : start + _perPage;
              final pageUsers = filtered.sublist(start, end);

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: pageUsers.length,
                      itemBuilder: (context, index) {
                        final user = pageUsers[index];
                        final isDisabled = user['isDisabled'] == true;
                        final name =
                            user['fullName'] ?? user['farmName'] ?? 'Unnamed';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(name),
                            subtitle: Text(user['phone'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isDisabled ? "Disabled" : "Active",
                                  style: TextStyle(
                                    color: isDisabled
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                                Switch(
                                  value: !isDisabled,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: (enabled) =>
                                      AdminService().setUserDisabled(
                                        _selectedCollection,
                                        user['id'],
                                        !enabled,
                                      ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _confirmDelete(context, user['id'], name),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _currentPage > 0
                                ? () => setState(() => _currentPage--)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text("Page ${_currentPage + 1} of $totalPages"),
                          IconButton(
                            onPressed: _currentPage < totalPages - 1
                                ? () => setState(() => _currentPage++)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PaymentsTab extends StatefulWidget {
  const _PaymentsTab();

  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _perPage = 5;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.orange.withValues(alpha: 0.1),
          child: const Text(
            "Once automated M-Pesa payouts are live, this list will only show failed payouts needing your action.",
            style: TextStyle(fontSize: 12, color: Colors.orange),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
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
        ),
        Expanded(
          child: StreamBuilder<List<FarmOrder>>(
            stream: AdminService().pendingPayoutOrdersStream(),
            builder: (context, snapshot) {
              final allOrders = snapshot.data ?? [];

              final filtered = _searchQuery.isEmpty
                  ? allOrders
                  : allOrders
                        .where(
                          (o) => o.consumerName.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                        )
                        .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    allOrders.isEmpty
                        ? "No pending payouts."
                        : "No matches for \"$_searchQuery\".",
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }

              final totalPages = (filtered.length / _perPage).ceil();
              if (_currentPage >= totalPages) _currentPage = totalPages - 1;
              if (_currentPage < 0) _currentPage = 0;

              final start = _currentPage * _perPage;
              final end = (start + _perPage) > filtered.length
                  ? filtered.length
                  : start + _perPage;
              final pageOrders = filtered.sublist(start, end);

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: pageOrders.length,
                      itemBuilder: (context, index) {
                        final order = pageOrders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text("Order for ${order.consumerName}"),
                            subtitle: Text(
                              "Farmer earns: KES ${order.farmerEarnings.toStringAsFixed(0)} · Delivery: KES ${order.deliveryCharge.toStringAsFixed(0)}",
                            ),
                            trailing: ElevatedButton(
                              onPressed: () =>
                                  AdminService().markOrderPaidOut(order.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Mark Paid"),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _currentPage > 0
                                ? () => setState(() => _currentPage--)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text("Page ${_currentPage + 1} of $totalPages"),
                          IconButton(
                            onPressed: _currentPage < totalPages - 1
                                ? () => setState(() => _currentPage++)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
