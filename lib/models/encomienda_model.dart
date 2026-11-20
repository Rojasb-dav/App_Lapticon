class EncomiendaModel {
  final String id;
  final String uidRemitente;
  final String nombreRemitente;
  final String origen;
  final String destino;
  final String descripcion;
  final String peso;
  final double valorPagar;
  final String fechaVencimiento;
  final String estado; // 'disponible' | 'tomada' | 'en_transito' | 'entregada'
  final String? uidViajero;
  final String? nombreViajero;

  EncomiendaModel({
    required this.id,
    required this.uidRemitente,
    required this.nombreRemitente,
    required this.origen,
    required this.destino,
    required this.descripcion,
    required this.peso,
    required this.valorPagar,
    required this.fechaVencimiento,
    required this.estado,
    this.uidViajero,
    this.nombreViajero,
  });

  bool get estaDisponible => estado == 'disponible' || estado == 'creada';
  bool get estaTomada => estado == 'tomada' || estado == 'asignada';
  bool get estaEntregada => estado == 'entregada';

  bool get estaVencida {
    if (fechaVencimiento.isEmpty) return false;
    final parsed = DateTime.tryParse(fechaVencimiento);
    if (parsed == null) return false;
    final hoy = DateTime.now();
    final inicioDeHoy = DateTime(hoy.year, hoy.month, hoy.day);
    return parsed.isBefore(inicioDeHoy);
  }

  /// Lee los campos reales del backend (ciudadOrigen, valor, observaciones, viajeroId...)
  /// y los antiguos como respaldo para la caché local.
  factory EncomiendaModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    // "2026-12-20T00:00:00.000Z" → "2026-12-20"
    String soloFecha(dynamic v) => (v ?? '').toString().split('T').first;

    return EncomiendaModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      uidRemitente: (json['uidRemitente'] ?? json['uid'] ?? json['remitenteUid'] ?? '').toString(),
      nombreRemitente: (json['nombreRemitente'] ?? json['remitenteNombre'] ?? 'Remitente').toString(),
      origen: (json['ciudadOrigen'] ?? json['origen'] ?? '').toString(),
      destino: (json['ciudadDestino'] ?? json['destino'] ?? '').toString(),
      descripcion: (json['observaciones'] ?? json['descripcion'] ?? '').toString(),
      peso: (json['peso'] ?? '—').toString(),
      valorPagar: parseDouble(json['valor'] ?? json['valorPagar'] ?? json['precio']),
      fechaVencimiento: soloFecha(json['fechaLimiteEntrega'] ?? json['fechaVencimiento']),
      estado: (json['estado'] ?? 'disponible').toString(),
      uidViajero: (json['viajeroId'] ?? json['uidViajero'])?.toString(),
      nombreViajero: json['nombreViajero']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uidRemitente': uidRemitente,
      'nombreRemitente': nombreRemitente,
      'origen': origen,
      'destino': destino,
      'descripcion': descripcion,
      'peso': peso,
      'valorPagar': valorPagar,
      'fechaVencimiento': fechaVencimiento,
      'estado': estado,
      if (uidViajero != null) 'uidViajero': uidViajero,
      if (nombreViajero != null) 'nombreViajero': nombreViajero,
    };
  }

  EncomiendaModel copyWith({
    String? id,
    String? uidRemitente,
    String? nombreRemitente,
    String? origen,
    String? destino,
    String? descripcion,
    String? peso,
    double? valorPagar,
    String? fechaVencimiento,
    String? estado,
    String? uidViajero,
    String? nombreViajero,
  }) {
    return EncomiendaModel(
      id: id ?? this.id,
      uidRemitente: uidRemitente ?? this.uidRemitente,
      nombreRemitente: nombreRemitente ?? this.nombreRemitente,
      origen: origen ?? this.origen,
      destino: destino ?? this.destino,
      descripcion: descripcion ?? this.descripcion,
      peso: peso ?? this.peso,
      valorPagar: valorPagar ?? this.valorPagar,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      estado: estado ?? this.estado,
      uidViajero: uidViajero ?? this.uidViajero,
      nombreViajero: nombreViajero ?? this.nombreViajero,
    );
  }
}
