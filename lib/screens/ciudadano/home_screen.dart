import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import 'mapa_screen.dart';
import 'estadisticas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MapaScreen(),
    EstadisticasScreen(),
  ];

  // Vuelve al welcome — el ciudadano no tiene sesión que cerrar
  void _salir(BuildContext context) {
    context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield, color: AppTheme.primary, size: 20),
            SizedBox(width: 8),
            Text('SafePoint'),
          ],
        ),
        actions: [
          // Botón para volver a la pantalla de bienvenida
          TextButton.icon(
            onPressed: () => _salir(context),
            icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary, size: 18),
            label: const Text(
              'Salir',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
        ],
      ),
    );
  }
}