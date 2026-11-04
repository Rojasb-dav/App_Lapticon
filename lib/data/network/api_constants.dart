class ApiConstants {
  static const String baseUrl = 'https://lapticon-backend.onrender.com';

  /// Rutas del backend de Lapticon.

  // Usuarios
  static const String registerUser = '/api/users/register';
  static String getUserProfile(String uid) => '/api/users/$uid';
  static String updateUser(String uid) => '/api/users/$uid';

  // Vuelos y viajes
  static String validarVuelo(String numero, String fecha) => '/api/vuelos/$numero/$fecha';
  static const String viajes = '/api/viajes';
  static const String misViajes = '/api/viajes/mis-viajes'; // ⚠ Confirmar ruta en Apiary
}
