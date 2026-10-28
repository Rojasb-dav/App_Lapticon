import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authStateSubscription;

  AuthStatus _status = AuthStatus.initial;
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository() {
    _initAuthStateListener();
  }

  // Getters
  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  void _initAuthStateListener() {
    _authStateSubscription = _authRepository.authStateChanges.listen((User? user) {
      _currentUser = user;
      if (user != null) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final credential = await _authRepository.loginWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = credential.user;
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AuthStatus.error;
      _setLoading(false);
      return false;
    }
  }

  /// Register with email and password in Firebase Auth
  Future<bool> register(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final credential = await _authRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = credential.user;
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AuthStatus.error;
      _setLoading(false);
      return false;
    }
  }

  /// Recuperación de contraseña
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authRepository.signOut();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _errorMessage = 'Error al cerrar sesión: $e';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
