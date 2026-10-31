import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/widgets/logo.dart';
import '../../core/widgets/app_text_field.dart';
import '../../services/auth_service.dart';

import '../consumer/consumer_home_screen.dart';
import '../farmer/farmer_home_screen.dart';
import '../rider/rider_home_screen.dart';
import '../admin/admin_home_screen.dart';
import 'register_screen.dart';

import '../../services/farmer_service.dart';
import '../../services/consumer_service.dart';
import '../../services/rider_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _loading = false;

  // ================================================================
  // LOGIN
  // ================================================================

  Future<void> _login() async {
    setState(() => _loading = true);

    try {
      final auth = AuthService();

      await auth.loginWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final uid = auth.currentUser!.uid;
      final role = await auth.getUserRole(uid);

      if (!mounted) return;

      // ============================================================
      // CHECK IF ACCOUNT IS DISABLED
      // ============================================================

      final isDisabled = await _checkIfDisabled(role, uid);

      if (isDisabled) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your account has been disabled. Please contact support.',
            ),
          ),
        );

        return;
      }

      // ============================================================
      // WEB = ADMIN ONLY
      // ============================================================

      if (kIsWeb && role != 'admin') {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Web access is restricted to administrators.',
            ),
          ),
        );

        return;
      }

      // ============================================================
      // SELECT HOME SCREEN BASED ON ROLE
      // ============================================================

      Widget destination;

      switch (role) {
        case 'admin':
          destination = const AdminHomeScreen();
          break;

        case 'farmer':
          destination = const FarmerHomeScreen();
          break;

        case 'rider':
          destination = const RiderHomeScreen();
          break;

        case 'consumer':
          destination = const ConsumerHomeScreen();
          break;

        default:
          await FirebaseAuth.instance.signOut();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No account type found. Please contact support.',
              ),
            ),
          );

          return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => destination,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Login failed',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ================================================================
  // CHECK IF ACCOUNT IS DISABLED
  // ================================================================

  Future<bool> _checkIfDisabled(String? role, String uid) async {
    try {
      Map<String, dynamic>? profile;

      switch (role) {
        case 'farmer':
          profile = await FarmerService().getFarmerProfile(uid);
          break;

        case 'consumer':
          profile = await ConsumerService().getConsumerProfile(uid);
          break;

        case 'rider':
          profile = await RiderService().getRiderProfile(uid);
          break;

        default:
          return false;
      }

      return profile?['isDisabled'] == true;
    } catch (_) {
      return false;
    }
  }

  // ================================================================
  // FORGOT PASSWORD
  // ================================================================

  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your email address first.',
          ),
        ),
      );

      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset instructions have been sent to your email.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Could not send password reset email.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
          ),
        ),
      );
    }
  }

  // ================================================================
  // DISPOSE
  // ================================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ================================================================
  // UI
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppLogo(),

                const SizedBox(height: 40),

                // ==================================================
                // CENTERED LOGIN FORM
                // ==================================================

                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: kIsWeb ? 420 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ------------------------------------------
                        // EMAIL
                        // ------------------------------------------

                        AppTextField(
                          controller: emailController,
                          label: 'Email',
                          icon: Icons.person,
                        ),

                        const SizedBox(height: 20),

                        // ------------------------------------------
                        // PASSWORD
                        // ------------------------------------------

                        AppTextField(
                          controller: passwordController,
                          label: 'Password',
                          icon: Icons.lock,
                          obscureText: true,
                        ),

                        const SizedBox(height: 5),

                        // ------------------------------------------
                        // FORGOT PASSWORD | CREATE ACCOUNT
                        // ------------------------------------------

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed:
                                  _loading ? null : _forgotPassword,
                              child: const Text(
                                'Forgot Password?',
                              ),
                            ),

                            const Text(
                              '|',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),

                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              RegisterScreen(),
                                        ),
                                      );
                                    },
                              child: const Text(
                                'Create Account',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        // ------------------------------------------
                        // LOGIN BUTTON
                        // ------------------------------------------

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
