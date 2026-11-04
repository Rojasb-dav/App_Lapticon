
/// Identificador único que asigna Firebase. Es la llave del usuario en el backend.
class UserModel {
  final String uid;
  final String email;
  final String nombre;
  final String apellido;
  final String telefono;
  final String nacionalidad;
  final String? rol; // 'remitente' | 'viajero'

  /// Representa el perfil de un usuario de Lapticon

  /// Rol actual del usuario: `'remitente'` o `'viajero'`
  UserModel({
    required this.uid,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.nacionalidad,
    this.rol,
  });

  String get nombreCompleto => '$nombre $apellido'.trim();

  /// Construye un [UserModel] a partir del JSON que responde el backend.

  factory UserModel.fromJson(Map<String, dynamic> json, {String? defaultUid, String? defaultEmail}) {
    final rolJson = json['rol']?.toString();
    return UserModel(
      uid: (json['uid'] ?? json['id'] ?? defaultUid ?? '').toString(),
      email: (json['email'] ?? defaultEmail ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      apellido: (json['apellido'] ?? '').toString(),
      telefono: (json['telefono'] ?? '').toString(),
      nacionalidad: (json['nacionalidad'] ?? '').toString(),
      rol: (rolJson != null && rolJson.isNotEmpty) ? rolJson : null,
    );
  }

  Map<String, dynamic> toRegisterJson() => {
    'nombre': nombre,
    'apellido': apellido,
    'telefono': telefono,
    'nacionalidad': nacionalidad,
  };

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'nombre': nombre,
    'apellido': apellido,
    'telefono': telefono,
    'nacionalidad': nacionalidad,
    if (rol != null) 'rol': rol,
  };

  /// Devuelve una copia del modelo cambiando solo los campos indicados.

  UserModel copyWith({
    String? uid,
    String? email,
    String? nombre,
    String? apellido,
    String? telefono,
    String? nacionalidad,
    String? rol,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      telefono: telefono ?? this.telefono,
      nacionalidad: nacionalidad ?? this.nacionalidad,
      rol: rol ?? this.rol,
    );
  }
}
