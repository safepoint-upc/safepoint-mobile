import 'package:flutter/material.dart';
import 'mapa_screen.dart';
import 'estadisticas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Igual que el agente: inicializado en initState como late final
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const MapaScreen(),
      const EstadisticasScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Solo Scaffold + IndexedStack + BottomNavigationBar — sin AppBar aquí.
    // Cada pantalla tiene su propio Scaffold con su propio AppBar.
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
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