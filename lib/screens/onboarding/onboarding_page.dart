import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String image;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            SizedBox(height: isSmallScreen ? 20 : 40),
            Image.asset(
              image,
              height: isSmallScreen ? 160 : 220,
              fit: BoxFit.contain,
            ),
            SizedBox(height: isSmallScreen ? 24 : 40),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 22 : null,
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: isSmallScreen ? 14 : null,
              ),
            ),
            SizedBox(height: isSmallScreen ? 20 : 40),
          ],
        ),
      ),
    );
  }
}
