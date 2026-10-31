import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'admin_web_dashboard.dart';
import 'admin_mobile_dashboard.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const AdminWebDashboard();
    } else {
      return const AdminMobileDashboard();
    }
  }
}