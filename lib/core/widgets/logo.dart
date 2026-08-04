import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        CircleAvatar(
          radius: 45,
          backgroundColor: AppColors.primary,

          child: Icon(Icons.agriculture, color: Colors.white, size: 45),
        ),

        SizedBox(height: 15),

        Text(
          "Farmlink",
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),

        SizedBox(height: 8),

        Text(
          "Connecting Farmers Directly to Buyers",
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
