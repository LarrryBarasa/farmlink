import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/widgets/logo.dart';
import '../../core/widgets/app_text_field.dart';
import '../../services/auth_service.dart';
import '../consumer/consumer_home_screen.dart';
import '../farmer/farmer_home_screen.dart';
import '../rider/rider_home_screen.dart';
import 'register_screen.dart';
import '../admin/admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _loading = false;

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No account type found. Please contact support."),
            ),
          );
          setState(() => _loading = false);
          return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Login failed")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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

              children: [
                const AppLogo(),

                const SizedBox(height: 40),

                AppTextField(
                  controller: emailController,
                  label: "Email",
                  icon: Icons.person,
                ),

                const SizedBox(height: 20),

                AppTextField(
                  controller: passwordController,
                  label: "Password",
                  icon: Icons.lock,
                  obscureText: true,
                ),

                const SizedBox(height: 30),

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
                        : const Text("Login"),
                  ),
                ),

                const SizedBox(height: 15),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegisterScreen()),
                    );
                  },
                  child: const Text("Create Account"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
