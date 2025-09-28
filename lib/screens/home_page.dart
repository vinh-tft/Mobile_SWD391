import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/header.dart';
import '../widgets/hero_section.dart';
import '../widgets/features_section.dart';
import '../widgets/cta_section.dart';
import '../widgets/footer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Header(),
            const HeroSection(),
            const FeaturesSection(),
            const CtaSection(),
            const Footer(),
          ],
        ),
      ),
    );
  }
}
