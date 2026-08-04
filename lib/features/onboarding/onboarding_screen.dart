import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController controller = PageController();

  int currentPage = 0;

  final List<Map<String, String>> pages = [
    {
      "icon": "🌾",
      "title": "Fresh Produce",
      "description": "Buy directly from verified farmers across Kenya.",
    },

    {
      "icon": "🚜",
      "title": "Sell More",
      "description": "Farmers sell without middlemen and earn more.",
    },

    {
      "icon": "🚚",
      "title": "Fast Delivery",
      "description": "Track your rider live and receive your order safely.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: controller,

              itemCount: pages.length,

              onPageChanged: (value) {
                setState(() {
                  currentPage = value;
                });
              },

              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(30),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Text(
                        pages[index]["icon"]!,
                        style: const TextStyle(fontSize: 100),
                      ),

                      const SizedBox(height: 30),

                      Text(
                        pages[index]["title"]!,

                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        pages[index]["description"]!,

                        textAlign: TextAlign.center,

                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,

            children: List.generate(
              pages.length,

              (index) => Container(
                margin: const EdgeInsets.all(4),

                width: currentPage == index ? 18 : 8,

                height: 8,

                decoration: BoxDecoration(
                  color: currentPage == index ? Colors.green : Colors.grey,

                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),

            child: SizedBox(
              width: double.infinity,

              height: 55,

              child: ElevatedButton(
                onPressed: () {
                  if (currentPage < 2) {
                    controller.nextPage(
                      duration: const Duration(milliseconds: 400),

                      curve: Curves.ease,
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }
                },

                child: Text(currentPage == 2 ? "Get Started" : "Next"),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
