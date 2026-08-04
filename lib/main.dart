import 'package:flutter/material.dart';

import 'routes/app_routes.dart';

void main() {
  runApp(const FarmlinkApp());
}

class FarmlinkApp extends StatelessWidget {
  const FarmlinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: "Farmlink",

      initialRoute: AppRoutes.login,

      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
