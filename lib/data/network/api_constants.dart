class ApiConstants {
  static const String baseUrl = 'https://lapticon-backend.onrender.com';

  // Endpoints
  static const String registerUser = '/api/users/register';
  static String getUserProfile(String uid) => '/api/users/$uid';
}
