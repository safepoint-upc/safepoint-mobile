import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/splash_screen.dart';
import '../../screens/welcome_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/agente/home_screen.dart' as agente;
import '../../screens/agente/mapa_screen.dart' as agente;
import '../../screens/agente/predicciones_screen.dart' as agente;
import '../../screens/agente/alertas_screen.dart' as agente;
import '../../screens/agente/incidentes_screen.dart' as agente;
import '../../screens/agente/perfil_screen.dart' as agente;
import '../../screens/ciudadano/home_screen.dart' as ciudadano;
import '../../screens/ciudadano/mapa_screen.dart' as ciudadano;
import '../../screens/ciudadano/estadisticas_screen.dart' as ciudadano;

class AppRouter {
  final AuthProvider _authProvider;
  late final GoRouter router;

  AppRouter(this._authProvider) {
    router = GoRouter(
      initialLocation: '/splash',
      // refreshListenable escucha cambios en AuthProvider y re-evalúa
      // el redirect automáticamente sin recrear el router
      refreshListenable: _authProvider,
      redirect: (context, state) {
        final isAuthenticated = _authProvider.isAuthenticated;
        final isLoading = _authProvider.isLoading;
        final location = state.matchedLocation;

        if (isLoading) return '/splash';

        if (isAuthenticated &&
            (location == '/login' || location == '/welcome')) {
          return _authProvider.usuario!.esAgente ? '/agente' : '/ciudadano';
        }

        if (!isAuthenticated && location.startsWith('/agente')) {
          return '/welcome';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: '/welcome',
          builder: (_, __) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/agente',
          builder: (_, __) => const agente.HomeScreen(),
        ),
        GoRoute(
          path: '/agente/mapa',
          builder: (_, __) => const agente.MapaScreen(),
        ),
        GoRoute(
          path: '/agente/predicciones',
          builder: (_, __) => const agente.PrediccionesScreen(),
        ),
        GoRoute(
          path: '/agente/alertas',
          builder: (_, __) => const agente.AlertasScreen(),
        ),
        GoRoute(
          path: '/agente/incidentes',
          builder: (_, __) => const agente.IncidentesScreen(),
        ),
        GoRoute(
          path: '/agente/perfil',
          builder: (_, __) => const agente.PerfilScreen(),
        ),
        GoRoute(
          path: '/ciudadano',
          builder: (_, __) => const ciudadano.HomeScreen(),
        ),
        GoRoute(
          path: '/ciudadano/mapa',
          builder: (_, __) => const ciudadano.MapaScreen(),
        ),
        GoRoute(
          path: '/ciudadano/estadisticas',
          builder: (_, __) => const ciudadano.EstadisticasScreen(),
        ),
      ],
    );
  }
}