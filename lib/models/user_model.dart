class UserModel {
  final String uid;
  final String email;
  final String nombre;
  final String apellido;
  final String telefono;
  final String nacionalidad;

  UserModel({
    required this.uid,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.nacionalidad,
  });

  /// Full name getter for convenience
  String get nombreCompleto => '$nombre $apellido'.trim();

  /// Create UserModel from JSON received from backend API or Firebase fallback
  factory UserModel.fromJson(Map<String, dynamic> json, {String? defaultUid, String? defaultEmail}) {
    return UserModel(
      uid: (json['uid'] ?? json['id'] ?? defaultUid ?? '').toString(),
      email: (json['email'] ?? defaultEmail ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      apellido: (json['apellido'] ?? '').toString(),
      telefono: (json['telefono'] ?? '').toString(),
      nacionalidad: (json['nacionalidad'] ?? '').toString(),
    );
  }

  /// Convert UserModel to JSON payload for backend POST /api/users/register
  Map<String, dynamic> toRegisterJson() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'nacionalidad': nacionalidad,
    };
  }

  /// Convert UserModel to Map
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'nacionalidad': nacionalidad,
    };
  }

  /// CopyWith helper for immutable state updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? nombre,
    String? apellido,
    String? telefono,
    String? nacionalidad,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      telefono: telefono ?? this.telefono,
      nacionalidad: nacionalidad ?? this.nacionalidad,
    );
  }
}
