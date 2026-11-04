class ViajeModel {
  final String id;
  final String numeroVuelo;
  final DateTime? fecha;
  final String origen;
  final String destino;
  final String estado;

  ViajeModel({
    required this.id,
    required this.numeroVuelo,
    required this.fecha,
    required this.origen,
    required this.destino,
    required this.estado,
  });

  factory ViajeModel.fromJson(Map<String, dynamic> j) {
    return ViajeModel(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      numeroVuelo: (j['numeroVuelo'] ?? j['vuelo'] ?? j['numero_vuelo'] ?? j['flightNumber'] ?? '').toString(),
      fecha: DateTime.tryParse((j['fecha'] ?? j['fechaViaje'] ?? '').toString()),
      origen: (j['origen'] ?? '').toString(),
      destino: (j['destino'] ?? '').toString(),
      estado: (j['estado'] ?? 'activo').toString(),
    );
  }
}

/// Datos del vuelo devueltos por /api/vuelos/:numero/:fecha (AeroDataBox)
class VueloInfo {
  final String aerolinea;
  final String origen;
  final String destino;
  final String salida;

  VueloInfo({required this.aerolinea, required this.origen, required this.destino, required this.salida});

  factory VueloInfo.fromResponse(dynamic r) {
    dynamic d = r;
    if (d is Map && d['data'] != null) d = d['data'];
    if (d is Map && d['vuelo'] != null) d = d['vuelo'];
    if (d is List) {
      if (d.isEmpty) throw Exception('No encontramos ese vuelo para la fecha indicada.');
      d = d.first;
    }
    if (d is! Map) throw Exception('Respuesta inesperada al validar el vuelo.');

    String aeropuerto(dynamic p) {
      if (p is Map) {
        final a = p['airport'];
        if (a is Map) return (a['iata'] ?? a['municipalityName'] ?? a['name'] ?? '').toString();
        return (p['iata'] ?? p['ciudad'] ?? '').toString();
      }
      return (p ?? '').toString();
    }

    final dep = d['departure'] ?? d['origen'];
    final arr = d['arrival'] ?? d['destino'];
    final airline = d['airline'];
    String salida = '';
    if (dep is Map) {
      final st = dep['scheduledTime'];
      salida = (st is Map ? st['local'] : dep['scheduledTimeLocal'])?.toString() ?? '';
    }

    return VueloInfo(
      aerolinea: airline is Map ? (airline['name'] ?? '').toString() : (d['aerolinea'] ?? '').toString(),
      origen: aeropuerto(dep),
      destino: aeropuerto(arr),
      salida: salida,
    );
  }
}
