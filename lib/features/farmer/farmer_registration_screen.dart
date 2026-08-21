import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class FarmerRegistrationScreen extends StatefulWidget {
  final String userId;

  const FarmerRegistrationScreen({super.key, required this.userId});

  @override
  State<FarmerRegistrationScreen> createState() =>
      _FarmerRegistrationScreenState();
}

class _FarmerRegistrationScreenState extends State<FarmerRegistrationScreen> {
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final farmNameController = TextEditingController();
  final countyController = TextEditingController();

  bool _saving = false;

  Future<void> _submit() async {
    setState(() => _saving = true);

    try {
      await AuthService().saveRoleProfile(
        uid: widget.userId,
        role: 'farmer',
        collectionName: 'farmers',
        profileData: {
          'fullName': fullNameController.text.trim(),
          'phone': phoneController.text.trim(),
          'farmName': farmNameController.text.trim(),
          'county': countyController.text.trim(),
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Farmer account created")));

      // TODO: navigate to a FarmerHomeScreen once it exists,
      // same pattern as ConsumerHomeScreen.
      Navigator.popUntil(context, (route) => route.isFirst);
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
      appBar: AppBar(
        title: const Text("Farmer Registration"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            const Icon(Icons.agriculture, size: 80, color: Colors.green),

            const SizedBox(height: 20),

            const Text(
              "Register your farm and start selling your produce on Farmlink.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

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
              controller: farmNameController,
              decoration: const InputDecoration(labelText: "Farm Name"),
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: countyController,
              decoration: const InputDecoration(labelText: "County"),
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
    );
  }
}
