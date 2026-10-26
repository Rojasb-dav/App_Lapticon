import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Stream of Auth State Changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Current logged-in Firebase user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Get fresh Firebase ID Token
  Future<String?> getIdToken({bool forceRefresh = true}) async {
    return await _firebaseAuth.currentUser?.getIdToken(forceRefresh);
  }

  /// Sign in with email and password
  Future<UserCredential> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error inesperado durante el inicio de sesión: $e');
    }
  }

  /// Register new user with email and password in Firebase Auth
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error inesperado durante el registro: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Friendly Spanish exception mapping
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe ningún usuario registrado con este correo electrónico.';
      case 'wrong-password':
        return 'Contraseña incorrecta. Por favor, verifica tus datos.';
      case 'invalid-email':
        return 'El formato del correo electrónico es inválido.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta registrada con este correo electrónico.';
      case 'weak-password':
        return 'La contraseña es demasiado débil. Usa al menos 6 caracteres.';
      case 'invalid-credential':
        return 'Las credenciales ingresadas son inválidas o han expirado.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Por favor, reintenta más tarde.';
      default:
        return e.message ?? 'Error de autenticación (${e.code}).';
    }
  }
}
