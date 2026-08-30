import 'package:flutter/material.dart';
import '../consumer/consumer_registration_screen.dart';
import '../farmer/farmer_registration_screen.dart';
import '../rider/rider_registration_screen.dart';

class AccountTypeScreen extends StatelessWidget {
  final String userId;

  const AccountTypeScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Account Type"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Text(
              "How would you like to use Farmlink?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            const Text(
              "Select one option below",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 35),

            _buildCard(
              context,
              icon: Icons.shopping_cart,
              title: "Consumer",
              subtitle: "Buy fresh farm products",
              color: Colors.green,
            ),

            const SizedBox(height: 20),

            _buildCard(
              context,
              icon: Icons.agriculture,
              title: "Farmer",
              subtitle: "Sell your farm produce",
              color: Colors.orange,
            ),

            const SizedBox(height: 20),

            _buildCard(
              context,
              icon: Icons.delivery_dining,
              title: "Rider",
              subtitle: "Deliver customer orders",
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Widget screen;

          switch (title) {
            case "Consumer":
              screen = ConsumerRegistrationScreen(userId: userId);
              break;

            case "Farmer":
              screen = FarmerRegistrationScreen(userId: userId);
              break;

            case "Rider":
              screen = RiderRegistrationScreen(userId: userId);
              break;

            default:
              return;
          }

          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withValues(alpha: .15),
                child: Icon(icon, color: color, size: 32),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}
