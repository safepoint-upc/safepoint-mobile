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

  /// Verifica la sesión leyendo el token JWT guardado localmente.
  /// No hace ninguna llamada a red — es instantáneo.
  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    _usuario = await _authService.getUserFromToken();

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
