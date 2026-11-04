import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/user_repository.dart';
import '../models/user_model.dart';

/// Valores válidos del rol. Se usan constantes para evitar errores de escritura.
class AppRoles {
  static const String remitente = 'remitente';
  static const String viajero = 'viajero';
}

/// Maneja el rol del usuario (remitente o viajero).
class RoleViewModel extends ChangeNotifier {
  final UserRepository _userRepository;
  RoleViewModel({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();

  String? _rol;
  bool _isLoading = false;
  String? _errorMessage;

  String? get rol => _rol;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get esViajero => _rol == AppRoles.viajero;
  bool get esRemitente => _rol == AppRoles.remitente;

  // La clave incluye el uid para que dos cuentas en el mismo teléfono no compartan rol
  String _cacheKey(String uid) => 'rol_$uid';

  /// 1) Si el backend trae el rol, se usa y se actualiza la caché.
  /// 2) Si no, se usa la caché local como respaldo.
  Future<String?> cargarRol(UserModel? profile) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final rolBackend = profile?.rol;

    if (rolBackend != null && rolBackend.isNotEmpty) {
      _rol = rolBackend;
      await prefs.setString(_cacheKey(uid), rolBackend);
    } else {
      _rol = prefs.getString(_cacheKey(uid));
    }
    notifyListeners();
    return _rol;
  }

  /// Guarda primero en el backend (PUT /api/users/:uid) y luego en caché.
  Future<bool> guardarRol(String rol, UserModel profile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _userRepository.updateRol(profile: profile, rol: rol);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey(profile.uid), rol);
      _rol = rol;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void limpiar() {
    _rol = null;
    notifyListeners();
  }
}
