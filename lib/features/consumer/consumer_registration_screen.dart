import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'consumer_home_screen.dart';

class ConsumerRegistrationScreen extends StatefulWidget {
  final String userId;

  const ConsumerRegistrationScreen({super.key, required this.userId});

  @override
  State<ConsumerRegistrationScreen> createState() =>
      _ConsumerRegistrationScreenState();
}

class _ConsumerRegistrationScreenState
    extends State<ConsumerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final countyController = TextEditingController();
  final emailController = TextEditingController();

  bool _saving = false;

  Future<void> _submit() async {
    setState(() => _saving = true);

    try {
      await AuthService().saveRoleProfile(
        uid: widget.userId,
        role: 'consumer',
        collectionName: 'consumers',
        profileData: {
          'fullName': fullNameController.text.trim(),
          'phone': phoneController.text.trim(),
          'county': countyController.text.trim(),
          'email': emailController.text.trim(),
        },
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ConsumerHomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Could not save profile: $e")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Consumer Registration")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            children: [
              TextFormField(
                controller: fullNameController,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Phone Number"),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: countyController,
                decoration: const InputDecoration(labelText: "County"),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Create Account"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
