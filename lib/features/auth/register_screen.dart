import 'package:flutter/material.dart';
import '../../core/widgets/logo.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import 'account_type_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              const SizedBox(height: 20),

              const AppLogo(),

              const SizedBox(height: 30),

              const Text(
                "Create Account",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              const AppTextField(label: "Full Name", icon: Icons.person),

              const SizedBox(height: 20),

              const AppTextField(label: "Phone Number", icon: Icons.phone),

              const SizedBox(height: 20),

              const AppTextField(label: "Email Address", icon: Icons.email),

              const SizedBox(height: 20),

              const AppTextField(
                label: "Password",
                icon: Icons.lock,
                obscureText: true,
              ),

              const SizedBox(height: 20),

              const AppTextField(
                label: "Confirm Password",
                icon: Icons.lock_outline,
                obscureText: true,
              ),

              const SizedBox(height: 35),

              PrimaryButton(
                text: "Continue",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountTypeScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
