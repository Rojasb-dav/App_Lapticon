import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Conexión al proyecto Firebase SECUNDARIO "Lapticon Chat", usado solo para el chat.
/// - El login sigue en el proyecto principal (lapticon-eba31).
/// - Aquí se entra como usuario anónimo, solo para cumplir las reglas de Firestore.
///
/// IMPORTANTE: varias pantallas piden la conexión al mismo tiempo al abrir la app.
/// Por eso se guarda la conexión "en curso" (_db) y todas esperan la misma,
/// en vez de intentar crear la app 'chat' varias veces (error "already exists").
class ChatFirebase {
  static Future<FirebaseFirestore>? _db;

  /// Datos de Configuración del proyecto → General (proyecto "Lapticon Chat").
  static const FirebaseOptions _opciones = FirebaseOptions(
    apiKey: 'AIzaSyDAk3kDRPayAcS5AvTTtGzQdfFBu0iK-xE',
    appId: '1:149591705291:android:7d1e4c18dc3a907c813d4e',
    messagingSenderId: '149591705291',
    projectId: 'lapticon-chat',
  );

  /// Devuelve la base de datos del chat. Todas las llamadas comparten la misma conexión.
  static Future<FirebaseFirestore> db() => _db ??= _conectar();

  static Future<FirebaseFirestore> _conectar() async {
    try {
      final app = await _obtenerApp();
      final auth = FirebaseAuth.instanceFor(app: app);
      if (auth.currentUser == null) {
        await auth.signInAnonymously(); // requiere "Anónimo" activado
      }
      return FirebaseFirestore.instanceFor(app: app);
    } catch (e) {
      _db = null; // si falló (sin internet, etc.), la próxima llamada reintenta
      rethrow;
    }
  }

  /// Reutiliza la app 'chat' si ya existe; si no, la crea una sola vez.
  static Future<FirebaseApp> _obtenerApp() async {
    for (final app in Firebase.apps) {
      if (app.name == 'chat') return app;
    }
    try {
      return await Firebase.initializeApp(name: 'chat', options: _opciones);
    } catch (e) {
      // Si otra parte la creó justo antes, usamos esa.
      if (e.toString().contains('already exists')) return Firebase.app('chat');
      rethrow;
    }
  }
}
