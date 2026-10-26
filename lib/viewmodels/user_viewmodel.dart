import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/repositories/user_repository.dart';
import '../models/user_model.dart';

enum UserProfileStatus {
  initial,
  loading,
  profileLoaded,
  profileNotFound,
  error,
}

class UserViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  UserModel? _userProfile;
  UserProfileStatus _status = UserProfileStatus.initial;
  bool _isLoading = false;
  String? _errorMessage;

  UserViewModel({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();

  // Getters
  UserModel? get userProfile => _userProfile;
  UserProfileStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasProfile => _userProfile != null && _userProfile!.nombre.isNotEmpty;

  /// Fetch user profile from backend
  Future<bool> fetchUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _userProfile = null;
      _status = UserProfileStatus.profileNotFound;
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final profile = await _userRepository.getUserProfile(currentUser.uid);
      if (profile != null && profile.nombre.isNotEmpty) {
        _userProfile = profile;
        _status = UserProfileStatus.profileLoaded;
        _setLoading(false);
        return true;
      } else {
        _userProfile = null;
        _status = UserProfileStatus.profileNotFound;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '');
      _status = UserProfileStatus.error;
      _setLoading(false);
      return false;
    }
  }

  /// Register user profile in backend (POST /api/users/register)
  Future<bool> completeProfile({
    required String nombre,
    required String apellido,
    required String telefono,
    required String nacionalidad,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedProfile = await _userRepository.registerUserProfile(
        nombre: nombre.trim(),
        apellido: apellido.trim(),
        telefono: telefono.trim(),
        nacionalidad: nacionalidad.trim(),
      );

      _userProfile = updatedProfile;
      _status = UserProfileStatus.profileLoaded;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '');
      _status = UserProfileStatus.error;
      _setLoading(false);
      return false;
    }
  }

  /// Clear stored profile on logout
  void clearProfile() {
    _userProfile = null;
    _status = UserProfileStatus.initial;
    _errorMessage = null;
    notifyListeners();
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
}
