import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'welcome_screen.dart';
import 'agente/home_screen.dart' as agente_home;
import 'ciudadano/home_screen.dart' as ciudadano_home;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    while (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }
    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      if (authProvider.usuario!.esAgente) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const agente_home.HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ciudadano_home.HomeScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0f1e),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF1e293b),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFF3b82f6).withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.shield_outlined, size: 48, color: Color(0xFF3b82f6)),
            ),
            const SizedBox(height: 24),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Safe',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF3b82f6), letterSpacing: -0.5),
                  ),
                  TextSpan(
                    text: 'Point',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3b82f6)),
            ),
          ],
        ),
      ),
    );
  }
}
