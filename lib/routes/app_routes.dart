import 'package:flutter/material.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/account_type_screen.dart';

import '../features/consumer/consumer_registration_screen.dart';
import '../features/farmer/farmer_registration_screen.dart';
import '../features/rider/rider_registration_screen.dart';

class AppRoutes {
  static const login = "/login";

  static const register = "/register";

  static const accountType = "/accountType";

  static const consumer = "/consumer";

  static const farmer = "/farmer";

  static const rider = "/rider";

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case accountType:
        return MaterialPageRoute(builder: (_) => const AccountTypeScreen());

      case consumer:
        return MaterialPageRoute(
          builder: (_) => const ConsumerRegistrationScreen(),
        );

      case farmer:
        return MaterialPageRoute(
          builder: (_) => const FarmerRegistrationScreen(),
        );

      case rider:
        return MaterialPageRoute(
          builder: (_) => const RiderRegistrationScreen(),
        );

      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
