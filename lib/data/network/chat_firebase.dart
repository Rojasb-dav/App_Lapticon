import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Conexión al proyecto Firebase SECUNDARIO "Lapticon Chat", usado solo para el chat.
/// - El login sigue en el proyecto principal (lapticon-eba31).
/// - Aquí se entra como usuario anónimo, solo para cumplir las reglas de Firestore.
/// Si algún día se usa el proyecto principal, basta cambiar estas opciones.
class ChatFirebase {
  static FirebaseApp? _app;

  /// Datos de Configuración del proyecto → General (proyecto "Lapticon Chat").
  static const FirebaseOptions _opciones = FirebaseOptions(
    apiKey: 'AIzaSyDAk3kDRPayAcS5AvTTtGzQdfFBu0iK-xE', // "current_key" del google-services.json (AIza...)
    appId: '1:149591705291:android:7d1e4c18dc3a907c813d4e',
    messagingSenderId: '149591705291',
    projectId: 'lapticon-chat',
  );

  /// Devuelve la base de datos del chat e inicia la conexión la primera vez.
  static Future<FirebaseFirestore> db() async {
    _app ??= await _iniciar();
    final auth = FirebaseAuth.instanceFor(app: _app!);
    if (auth.currentUser == null) {
      await auth.signInAnonymously(); // requiere "Anónimo" activado en Authentication
    }
    return FirebaseFirestore.instanceFor(app: _app!);
  }

  /// Reutiliza la conexión si ya existe (evita error al reiniciar la app).
  static Future<FirebaseApp> _iniciar() async {
    try {
      return Firebase.app('chat');
    } catch (_) {
      return Firebase.initializeApp(name: 'chat', options: _opciones);
    }
  }
}
