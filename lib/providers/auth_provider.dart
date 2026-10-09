import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  Usuario? _usuario;
  bool _isLoading = true;

  Usuario? get usuario => _usuario;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _usuario != null;

  AuthProvider() {
    checkAuth();
  }

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Si el servidor de Render está dormido, le damos un timeout máximo de 5 segundos
      // Si expira, asumimos que no hay sesión activa y dejamos que el usuario avance a /welcome
      _usuario = await _authService.getMe().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
    } catch (e) {
      _usuario = null;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.login(email, password);
    if (result['success']) {
      _usuario = result['usuario'];
    }

    _isLoading = false;
    notifyListeners();
    return result['success'];
  }

  Future<void> logout() async {
    await _authService.logout();
    _usuario = null;
    notifyListeners();
  }
}
