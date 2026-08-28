import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import 'farmer_home_screen.dart';

class FarmerRegistrationScreen extends StatefulWidget {
  final String userId;

  const FarmerRegistrationScreen({
    super.key,
    required this.userId,
  });

  @override
  State<FarmerRegistrationScreen> createState() =>
      _FarmerRegistrationScreenState();
}

class _FarmerRegistrationScreenState
    extends State<FarmerRegistrationScreen> {
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final farmNameController = TextEditingController();
  final countyController = TextEditingController();

  bool _saving = false;

  Future<void> _submit() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final position = await LocationService().getCurrentLocation();

      debugPrint(
        'LOCATION RESULT: '
        'lat=${position?.latitude}, '
        'lng=${position?.longitude}',
      );

      await AuthService().saveRoleProfile(
        uid: widget.userId,
        role: 'farmer',
        collectionName: 'farmers',
        profileData: {
          'fullName': fullNameController.text.trim(),
          'phone': phoneController.text.trim(),
          'farmName': farmNameController.text.trim(),
          'county': countyController.text.trim(),
          'latitude': position?.latitude,
          'longitude': position?.longitude,
        },
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const FarmerHomeScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Could not save profile: $e",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    farmNameController.dispose();
    countyController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        title: const Text("Farmer Registration"),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,

          padding: const EdgeInsets.all(24),

          child: Column(
            children: [
              const Icon(
                Icons.agriculture,
                size: 80,
                color: Colors.green,
              ),

              const SizedBox(height: 20),

              const Text(
                "Register your farm and start selling your produce on Farmlink.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              TextFormField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: farmNameController,
                decoration: const InputDecoration(
                  labelText: "Farm Name",
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: countyController,
                decoration: const InputDecoration(
                  labelText: "County",
                ),
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Create Account"),
                ),
              ),

              // Extra space at the bottom so the keyboard
              // does not cover the last part of the screen.
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
