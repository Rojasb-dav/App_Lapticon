import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../network/api_client.dart';
import '../network/api_constants.dart';

class UserRepository {
  final ApiClient _apiClient;
  final FirebaseAuth _firebaseAuth;

  UserRepository({ApiClient? apiClient, FirebaseAuth? firebaseAuth})
      : _apiClient = apiClient ?? ApiClient(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Fetch user profile from backend GET /api/users/{uid}
  /// Returns null if user profile does not exist (e.g. 404 or profile uncompleted)
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final response = await _apiClient.get(ApiConstants.getUserProfile(uid));
      if (response != null) {
        Map<String, dynamic> dataMap = {};
        if (response is List && response.isNotEmpty) {
          final first = response.first;
          if (first is Map<String, dynamic>) dataMap = first;
        } else if (response is Map<String, dynamic>) {
          if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
            dataMap = response['data'];
            if (dataMap.containsKey('user') && dataMap['user'] is Map<String, dynamic>) {
              dataMap = dataMap['user'];
            }
          } else if (response.containsKey('user') && response['user'] is Map<String, dynamic>) {
            dataMap = response['user'];
          } else {
            dataMap = response;
          }
        }

        final email = _firebaseAuth.currentUser?.email ?? '';
        final userModel = UserModel.fromJson(dataMap, defaultUid: uid, defaultEmail: email);
        if (userModel.nombre.isNotEmpty) {
          return userModel;
        }
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // User has not completed their profile yet in backend
        return null;
      }
      rethrow;
    } catch (e) {
      throw Exception('Error al obtener el perfil de usuario: $e');
    }
  }

  /// Register or Update user profile in backend POST /api/users/register
  Future<UserModel> registerUserProfile({
    required String nombre,
    required String apellido,
    required String telefono,
    required String nacionalidad,
  }) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('No hay un usuario autenticado en Firebase.');
    }

    final payload = {
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'nacionalidad': nacionalidad,
    };

    try {
      final response = await _apiClient.post(ApiConstants.registerUser, payload);

      Map<String, dynamic> dataMap = {};
      if (response is Map<String, dynamic>) {
        if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
          dataMap = response['data'];
        } else if (response.containsKey('user') && response['user'] is Map<String, dynamic>) {
          dataMap = response['user'];
        } else {
          dataMap = response;
        }
      }

      final returnedNombre = dataMap['nombre']?.toString() ?? nombre;
      final returnedApellido = dataMap['apellido']?.toString() ?? apellido;
      final returnedTelefono = dataMap['telefono']?.toString() ?? telefono;
      final returnedNacionalidad = dataMap['nacionalidad']?.toString() ?? nacionalidad;

      return UserModel(
        uid: currentUser.uid,
        email: currentUser.email ?? '',
        nombre: returnedNombre.isNotEmpty ? returnedNombre : nombre,
        apellido: returnedApellido.isNotEmpty ? returnedApellido : apellido,
        telefono: returnedTelefono.isNotEmpty ? returnedTelefono : telefono,
        nacionalidad: returnedNacionalidad.isNotEmpty ? returnedNacionalidad : nacionalidad,
      );
    } catch (e) {
      rethrow;
    }
  }
}
