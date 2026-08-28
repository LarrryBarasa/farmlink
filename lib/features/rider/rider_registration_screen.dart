import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import 'rider_home_screen.dart';

class RiderRegistrationScreen extends StatefulWidget {
  final String userId;

  const RiderRegistrationScreen({super.key, required this.userId});

  @override
  State<RiderRegistrationScreen> createState() =>
      _RiderRegistrationScreenState();
}

class _RiderRegistrationScreenState extends State<RiderRegistrationScreen> {
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final vehicleController = TextEditingController();
  final countyController = TextEditingController();

  bool _saving = false;

  Future<void> _submit() async {
    setState(() => _saving = true);

    try {
      final position = await LocationService().getCurrentLocation();

      await AuthService().saveRoleProfile(
        uid: widget.userId,
        role: 'rider',
        collectionName: 'riders',
        profileData: {
          'fullName': fullNameController.text.trim(),
          'phone': phoneController.text.trim(),
          'vehicleType': vehicleController.text.trim(),
          'county': countyController.text.trim(),
          'latitude': position?.latitude,
          'longitude': position?.longitude,
        },
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RiderHomeScreen()),
        (route) => false,
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
      appBar: AppBar(
        title: const Text("Rider Registration"),
        centerTitle: true,
      ),

            body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            const Icon(Icons.delivery_dining, size: 80, color: Colors.blue),

            const SizedBox(height: 20),

            const Text(
              "Register as a delivery rider and start receiving delivery jobs from Farmlink.",
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
              controller: vehicleController,
              decoration: const InputDecoration(
                labelText: "Vehicle Type (e.g. Motorbike, Bicycle)",
              ),
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

