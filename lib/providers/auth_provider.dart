import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  Usuario? _usuario;
  bool _isCheckingAuth = true;
  bool _isLoggingIn = false;

  Usuario? get usuario => _usuario;
  bool get isCheckingAuth => _isCheckingAuth;
  bool get isLoggingIn => _isLoggingIn;
  bool get isLoading => _isCheckingAuth || _isLoggingIn;
  bool get isAuthenticated => _usuario != null;

  AuthProvider() {
    checkAuth();
  }

  /// Verifica la sesión leyendo el token JWT guardado localmente.
  /// No hace ninguna llamada a red — es instantáneo.
  Future<void> checkAuth() async {
    _isCheckingAuth = true;
    notifyListeners();

    _usuario = await _authService.getUserFromToken();

    _isCheckingAuth = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoggingIn = true;
    notifyListeners();

    final result = await _authService.login(email, password);
    if (result['success'] == true && result['usuario'] != null) {
      _usuario = result['usuario'];
    }

    _isLoggingIn = false;
    notifyListeners();
    return result['success'] == true && _usuario != null;
  }

  Future<void> logout() async {
    await _authService.logout();
    _usuario = null;
    notifyListeners();
  }
}
