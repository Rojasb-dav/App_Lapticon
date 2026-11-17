class ApiConstants {
  static const String baseUrl = 'https://lapticon-backend.onrender.com';

  // Usuarios
  static const String registerUser = '/api/users/register';
  static String getUserProfile(String uid) => '/api/users/$uid';
  static String updateUser(String uid) => '/api/users/$uid';

  // Viajes
  static String validarVuelo(String numero, String fecha) => '/api/vuelos/$numero/$fecha';
  static const String viajes = '/api/viajes';
  static const String viajesDisponibles = '/api/viajes/disponibles';
  static String viajeEstado(String id) => '/api/viajes/$id/estado';

  // Encomiendas
  static const String encomiendas = '/api/encomiendas';
  static const String misEncomiendas = '/api/encomiendas/mis-encomiendas';
  static const String encomiendasDisponibles = '/api/encomiendas/disponibles';
  static const String encomiendasBuscar = '/api/encomiendas/buscar';
  static String tomarEncomienda(String id) => '/api/encomiendas/tomar/$id';
  static String encomiendaEstado(String id) => '/api/encomiendas/$id/estado';

  // Chats
  static String chatEstado(String chatId) => '/api/chats/estado/$chatId';
}
