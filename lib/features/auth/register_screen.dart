import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/widgets/logo.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../services/auth_service.dart';
import 'account_type_screen.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              const AppLogo(),

              const SizedBox(height: 30),

              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // CENTERED REGISTRATION FORM
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
                      // FULL NAME
                      // ------------------------------------------

                      AppTextField(
                        controller: nameController,
                        label: "Full Name",
                        icon: Icons.person,
                      ),

                      const SizedBox(height: 20),

                      // ------------------------------------------
                      // PHONE NUMBER
                      // ------------------------------------------

                      AppTextField(
                        controller: phoneController,
                        label: "Phone Number",
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 20),

                      // ------------------------------------------
                      // EMAIL
                      // ------------------------------------------

                      AppTextField(
                        controller: emailController,
                        label: "Email Address",
                        icon: Icons.email,
                      ),

                      const SizedBox(height: 20),

                      // ------------------------------------------
                      // PASSWORD
                      // ------------------------------------------

                      AppTextField(
                        controller: passwordController,
                        label: "Password",
                        icon: Icons.lock,
                        obscureText: true,
                      ),

                      const SizedBox(height: 20),

                      // ------------------------------------------
                      // CONFIRM PASSWORD
                      // ------------------------------------------

                      AppTextField(
                        controller: confirmPasswordController,
                        label: "Confirm Password",
                        icon: Icons.lock_outline,
                        obscureText: true,
                      ),

                      const SizedBox(height: 35),

                      // ------------------------------------------
                      // CONTINUE BUTTON
                      // ------------------------------------------

                      PrimaryButton(
                        text: "Continue",
                        onPressed: () async {
                          if (passwordController.text !=
                              confirmPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Passwords don't match",
                                ),
                              ),
                            );
                            return;
                          }

                          try {
                            final uid =
                                await AuthService().registerWithEmail(
                              name: nameController.text.trim(),
                              phone: phoneController.text.trim(),
                              email: emailController.text.trim(),
                              password: passwordController.text,
                            );

                            if (!context.mounted) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AccountTypeScreen(userId: uid),
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.message ?? "Registration failed",
                                ),
                              ),
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 25),

                      // ------------------------------------------
                      // LOGIN
                      // ------------------------------------------

                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Already have an account? Login",
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
    );
  }
}