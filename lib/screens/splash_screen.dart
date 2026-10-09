import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Espera máxima total de 3.5 segundos para no congelar la pantalla de carga
    int elapsed = 0;
    while (authProvider.isLoading && elapsed < 3500) {
      await Future.delayed(const Duration(milliseconds: 150));
      elapsed += 150;
      if (!mounted) return;
    }
    if (!mounted) return;

    // Redirige según si hay sesión activa y cuál es el rol del usuario
    if (authProvider.isAuthenticated && authProvider.usuario != null) {
      context.go(authProvider.usuario!.esAgente ? '/agente' : '/ciudadano');
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 48,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            // Nombre de la app
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Safe',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Point',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // Indicador de carga
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}