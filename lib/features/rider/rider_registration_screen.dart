import 'package:flutter/material.dart';

class RiderRegistrationScreen extends StatelessWidget {
  const RiderRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rider Registration"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: const [
            Icon(Icons.delivery_dining, size: 80, color: Colors.blue),

            SizedBox(height: 30),

            Text(
              "Rider Registration Screen",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 20),

            Text(
              "Register as a delivery rider and start receiving delivery jobs from Farmlink.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
