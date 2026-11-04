import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  static const String _webClientId =
      '919252353880-9g5b6t2lhmh4fh32nalegqq2gbd76grh.apps.googleusercontent.com';

  AuthRepository({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: _webClientId,
            );

  /// Stream of Auth State Changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Current logged-in Firebase user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Check if Google account is linked
  bool get isGoogleLinked {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == 'google.com');
  }

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

  /// Sign in with Google Account
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled Google Sign-In
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      final errStr = e.toString();
      debugPrint('Google Sign-In Error: $errStr');
      if (errStr.contains('10') || errStr.contains('12500')) {
        throw Exception(
            'Google Sign-In (Error 10): Registra la huella digital SHA-1 de tu proyecto en la consola de Firebase.');
      } else if (errStr.contains('12501') || errStr.contains('cancel')) {
        return null;
      }
      throw Exception('Error al iniciar sesión con Google: $e');
    }
  }

  /// Link Google Account to currently logged-in user
  Future<UserCredential?> linkGoogleAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No hay un usuario autenticado para vincular.');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled Google Sign-In
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      final errStr = e.toString();
      debugPrint('Google Link Error: $errStr');
      if (errStr.contains('10') || errStr.contains('12500')) {
        throw Exception(
            'Google Sign-In (Error 10): Registra la huella digital SHA-1 de tu proyecto en la consola de Firebase.');
      } else if (errStr.contains('12501') || errStr.contains('cancel')) {
        return null;
      }
      throw Exception('Error al vincular la cuenta de Google: $e');
    }
  }

  /// Envía correo de recuperación de contraseña
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.setLanguageCode('es'); // correo en español
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error inesperado al enviar el correo: $e');
    }
  }

  /// Sign out current user from Firebase & Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _firebaseAuth.signOut();
  }

  /// Friendly Spanish exception mapping
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta registrada con este correo electrónico. Inicia sesión con tu contraseña y podrás vincular Google desde tu perfil.';
      case 'credential-already-in-use':
        return 'Esta cuenta de Google ya está vinculada a otro usuario.';
      case 'provider-already-linked':
        return 'Tu cuenta ya se encuentra vinculada con Google.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Verifica tu red.';
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
