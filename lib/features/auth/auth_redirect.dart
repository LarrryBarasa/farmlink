import 'package:flutter/material.dart';

import 'login_screen.dart';

class AuthRedirect {
  /// Forces the user back to the Login screen.
  ///
  /// This removes all previous screens from the navigation stack,
  /// so pressing the back button will not return them to registration.
  static void goToLogin(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }
}
