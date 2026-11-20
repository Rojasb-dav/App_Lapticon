import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/viaje_viewmodel.dart';
import '../../widgets/lapticon_ui.dart';

/// Formulario para registrar un viaje (rol viajero).
/// Flujo: número de vuelo + fecha → Validar (GET /api/vuelos/:numero/:fecha)
/// → si el servicio responde, se llenan solos Origen y Destino
/// → Registrar (POST /api/viajes).
class RegistrarViajeScreen extends StatefulWidget {
  const RegistrarViajeScreen({super.key});

  @override
  State<RegistrarViajeScreen> createState() => _RegistrarViajeScreenState();
}

class _RegistrarViajeScreenState extends State<RegistrarViajeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vueloCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _origenCtrl = TextEditingController();
  final _destinoCtrl = TextEditingController();

  /// Ciudades disponibles y su código IATA de aeropuerto.
  static const Map<String, String> _ciudades = {
    'Bogotá': 'BOG',
    'Medellín': 'MDE',
    'Cali': 'CLO',
    'Miami': 'MIA',
    'Madrid': 'MAD',
  };

  DateTime? _fecha;

  @override
  void initState() {
    super.initState();
    // Si cambia el número de vuelo, hay que volver a validar.
    _vueloCtrl.addListener(() => context.read<ViajeViewModel>().resetValidacion());
  }

  @override
  void dispose() {
    _vueloCtrl.dispose();
    _fechaCtrl.dispose();
    _origenCtrl.dispose();
    _destinoCtrl.dispose();
    super.dispose();
  }

  /// Fecha en formato AAAA-MM-DD (el que espera el backend).
  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Número de vuelo limpio: "av 9340" → "AV9340".
  String get _numeroVuelo => _vueloCtrl.text.trim().toUpperCase().replaceAll(' ', '');

  /// Quita tildes y pasa a mayúsculas para comparar nombres de ciudades.
  String _normalizar(String s) => s
      .trim()
      .toUpperCase()
      .replaceAll('Á', 'A')
      .replaceAll('É', 'E')
      .replaceAll('Í', 'I')
      .replaceAll('Ó', 'O')
      .replaceAll('Ú', 'U');

  /// Convierte lo que devuelve el servicio de vuelos ("BOG" o "Bogota")
  /// al nombre del desplegable ("Bogotá"). Devuelve null si no está en la lista.
  String? _aCiudad(String dato) {
    final d = _normalizar(dato);
    if (d.isEmpty) return null;
    for (final e in _ciudades.entries) {
      if (e.value == d || _normalizar(e.key) == d) return e.key;
    }
    return null;
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha ?? hoy,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day), // no se permiten fechas pasadas
      lastDate: hoy.add(const Duration(days: 365)),
      helpText: 'Fecha del vuelo',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: LapticonColors.acento,
            surface: LapticonColors.tarjeta,
          ),
        ),
        child: child!,
      ),
    );
    if (elegida != null) {
      setState(() {
        _fecha = elegida;
        _fechaCtrl.text = _fmt(elegida);
      });
      if (mounted) context.read<ViajeViewModel>().resetValidacion();
    }
  }

  /// Mensaje inferior: rojo = error, verde = éxito, o un color propio (ámbar = aviso).
  void _snack(String msg, {bool error = true, Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color ?? (error ? Colors.redAccent : Colors.green),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  /// Valida el vuelo y, si el servicio devuelve los aeropuertos,
  /// llena Origen y Destino automáticamente.
  Future<void> _validar() async {
    if (_numeroVuelo.isEmpty || _fecha == null) {
      _snack('Ingresa el número de vuelo y la fecha para validar.');
      return;
    }
    FocusScope.of(context).unfocus();
    final vm = context.read<ViajeViewModel>();
    final error = await vm.validarVuelo(_numeroVuelo, _fmt(_fecha!));
    if (!mounted) return;
    if (error != null) {
      _snack(error);
      return;
    }

    final v = vm.vueloValidado!;
    final sinVerificar = v.aerolinea.startsWith('Sin verificar');
    final origen = _aCiudad(v.origen);
    final destino = _aCiudad(v.destino);

    // setState para que los desplegables se redibujen con la ciudad encontrada
    setState(() {
      if (origen != null) _origenCtrl.text = origen;
      if (destino != null && destino != origen) _destinoCtrl.text = destino;
    });

    if (sinVerificar) {
      _snack('El servicio de vuelos no está disponible. Elige origen y destino manualmente.',
          color: Colors.amber.shade800);
    } else if (origen == null || destino == null) {
      _snack('Vuelo encontrado (${v.origen} → ${v.destino}), pero esa ruta no está entre las ciudades disponibles.',
          color: Colors.amber.shade800);
    }
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<ViajeViewModel>();
    final error = await vm.registrarViaje(
      numeroVuelo: _numeroVuelo,
      fecha: _fmt(_fecha!),
      origen: _origenCtrl.text.trim(),
      destino: _destinoCtrl.text.trim(),
    );
    if (!mounted) return;
    if (error != null) {
      _snack(error);
    } else {
      _snack('¡Viaje registrado con éxito!', error: false);
      context.pop(true);
    }
  }

  String? _requerido(String? v, String msg) => (v == null || v.trim().isEmpty) ? msg : null;

  /// Desplegable de ciudad. `excluir` evita elegir la misma ciudad en origen y destino.
  /// La `key` cambia con el valor para que el desplegable se actualice al autollenar.
  Widget _selectorCiudad({
    required String label,
    required IconData icono,
    required TextEditingController controller,
    String? excluir,
  }) {
    final opciones = _ciudades.keys.where((c) => c != excluir).toList();
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-${controller.text}'),
      initialValue: opciones.contains(controller.text) ? controller.text : null,
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white, fontSize: 16),
      iconEnabledColor: const Color(0xFF38BDF8),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icono, color: const Color(0xFF38BDF8)),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: opciones
          .map((c) => DropdownMenuItem(value: c, child: Text('$c (${_ciudades[c]})')))
          .toList(),
      onChanged: (v) => setState(() => controller.text = v ?? ''),
      validator: (v) => (v == null || v.isEmpty) ? 'Selecciona ${label.toLowerCase()}' : null,
    );
  }

  /// Letrero bajo el botón Validar:
  /// verde = vuelo verificado; ámbar = servicio de vuelos no disponible.
  Widget _estadoVuelo(dynamic vuelo) {
    final sinVerificar = vuelo.aerolinea.toString().startsWith('Sin verificar');
    final color = sinVerificar ? Colors.amber : Colors.green;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            sinVerificar ? Icons.warning_amber_rounded : Icons.check_circle,
            color: sinVerificar ? Colors.amber : Colors.greenAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sinVerificar
                  ? 'Vuelo sin verificar · $_numeroVuelo\nElige origen y destino manualmente.'
                  : 'Vuelo Verificado · $_numeroVuelo'
                  '${vuelo.aerolinea.toString().isNotEmpty ? ' · ${vuelo.aerolinea}' : ''}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ViajeViewModel>();
    final vuelo = vm.vueloValidado;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Registrar Viaje',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: lapticonFondo,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Datos de tu vuelo',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Validamos tu vuelo con los datos del sistema.',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 24),
                  LapticonCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Número de vuelo
                        TextFormField(
                          controller: _vueloCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(color: Colors.white),
                          decoration: lapticonInput(
                              'Número de vuelo (ej. AV9340)', Icons.confirmation_number_outlined),
                          validator: (v) => _requerido(v, 'Ingresa el número de vuelo'),
                        ),
                        const SizedBox(height: 16),
                        // Fecha (abre el calendario)
                        TextFormField(
                          controller: _fechaCtrl,
                          readOnly: true,
                          onTap: _elegirFecha,
                          style: const TextStyle(color: Colors.white),
                          decoration: lapticonInput('Fecha del vuelo', Icons.calendar_month_outlined),
                          validator: (v) => _requerido(v, 'Selecciona la fecha'),
                        ),
                        const SizedBox(height: 20),
                        // Botón Validar vuelo
                        OutlinedButton.icon(
                          onPressed: vm.validando ? null : _validar,
                          icon: vm.validando
                              ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: LapticonColors.acento))
                              : const Icon(Icons.verified_outlined),
                          label: Text(vm.validando ? 'Validando vuelo...' : 'Validar vuelo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: LapticonColors.acento,
                            side: const BorderSide(color: LapticonColors.acento),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        // Resultado de la validación (verde o ámbar)
                        if (vuelo != null) ...[
                          const SizedBox(height: 16),
                          _estadoVuelo(vuelo),
                        ],
                        const SizedBox(height: 20),
                        // Desplegables de ciudades
                        _selectorCiudad(
                          label: 'Origen',
                          icono: Icons.flight_takeoff_rounded,
                          controller: _origenCtrl,
                          excluir: _destinoCtrl.text,
                        ),
                        const SizedBox(height: 16),
                        _selectorCiudad(
                          label: 'Destino',
                          icono: Icons.flight_land_rounded,
                          controller: _destinoCtrl,
                          excluir: _origenCtrl.text,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  GradientButton(
                    text: 'Registrar Viaje',
                    icon: Icons.save_rounded,
                    loading: vm.guardando,
                    onPressed: (vuelo == null || vm.guardando) ? null : _registrar,
                  ),
                  if (vuelo == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text('Primero valida tu vuelo para poder registrarlo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
