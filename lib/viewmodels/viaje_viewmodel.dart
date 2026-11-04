import 'package:flutter/foundation.dart';
import '../data/network/api_client.dart';
import '../data/repositories/viaje_repository.dart';
import '../models/viaje_model.dart';

class ViajeViewModel extends ChangeNotifier {
  final ViajeRepository _repo;
  ViajeViewModel({ViajeRepository? repo}) : _repo = repo ?? ViajeRepository();

  List<ViajeModel> _viajes = [];
  bool _cargandoLista = false;
  bool _validando = false;
  bool _guardando = false;
  String? _errorLista;
  VueloInfo? _vueloValidado;

  List<ViajeModel> get viajes => _viajes;
  bool get cargandoLista => _cargandoLista;
  bool get validando => _validando;
  bool get guardando => _guardando;
  String? get errorLista => _errorLista;
  VueloInfo? get vueloValidado => _vueloValidado;

  String _limpiar(Object e) =>
      e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');

  Future<void> cargarMisViajes() async {
    _cargandoLista = true;
    _errorLista = null;
    notifyListeners();
    try {
      _viajes = await _repo.misViajes();
    } catch (e) {
      _errorLista = _limpiar(e);
    } finally {
      _cargandoLista = false;
      notifyListeners();
    }
  }

  /// Devuelve null si el vuelo es válido, o el mensaje de error
  Future<String?> validarVuelo(String numero, String fecha) async {
    _validando = true;
    _vueloValidado = null;
    notifyListeners();
    try {
      _vueloValidado = await _repo.validarVuelo(numero, fecha);
      return null;
    } on ApiException catch (e) {
      return e.statusCode == 404
          ? 'No encontramos el vuelo $numero para esa fecha.'
          : _limpiar(e);
    } catch (e) {
      return _limpiar(e);
    } finally {
      _validando = false;
      notifyListeners();
    }
  }

  void resetValidacion() {
    if (_vueloValidado != null) {
      _vueloValidado = null;
      notifyListeners();
    }
  }

  Future<String?> registrarViaje({
    required String numeroVuelo,
    required String fecha,
    required String origen,
    required String destino,
  }) async {
    _guardando = true;
    notifyListeners();
    try {
      await _repo.registrarViaje(
          numeroVuelo: numeroVuelo, fecha: fecha, origen: origen, destino: destino);
      _vueloValidado = null;
      await cargarMisViajes();
      return null;
    } catch (e) {
      return _limpiar(e);
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }
}
