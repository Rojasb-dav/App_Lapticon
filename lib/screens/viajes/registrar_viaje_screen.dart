import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/viaje_viewmodel.dart';
import '../../widgets/lapticon_ui.dart';

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

  /// Ciudades disponibles en Lapticon (nombre visible → código IATA del aeropuerto).
  static const Map<String, String> _ciudades = {
    'Bogotá': 'BOG',
    'Medellín': 'MDE',
    'Cali': 'CLO',
  };

  DateTime? _fecha;

  @override
  void initState() {
    super.initState();
    // Si cambia el número de vuelo, hay que validar de nuevo
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

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get _numeroVuelo => _vueloCtrl.text.trim().toUpperCase().replaceAll(' ', '');

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha ?? hoy,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
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

  void _snack(String msg, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

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
    // Autocompletar origen y destino con los datos del vuelo
    final v = vm.vueloValidado!;
    if (_origenCtrl.text.isEmpty && v.origen.isNotEmpty) _origenCtrl.text = v.origen;
    if (_destinoCtrl.text.isEmpty && v.destino.isNotEmpty) _destinoCtrl.text = v.destino;
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

  /// Menú desplegable de ciudad que escribe la selección en [controller].
  /// [excluir] evita que origen y destino sean la misma ciudad.
  Widget _selectorCiudad({
    required String label,
    required IconData icono,
    required TextEditingController controller,
    String? excluir,
  }) {
    final opciones = _ciudades.keys.where((c) => c != excluir).toList();
    return DropdownButtonFormField<String>(
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


  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ViajeViewModel>();
    final vuelo = vm.vueloValidado;

    return Scaffold(
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
        decoration: lapticonFondo,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Datos de tu vuelo',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Validamos tu vuelo contra datos reales antes de registrarlo.',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 24),
                  LapticonCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _vueloCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(color: Colors.white),
                          decoration: lapticonInput('Número de vuelo (ej. AV9)', Icons.confirmation_number_outlined),
                          validator: (v) => _requerido(v, 'Ingresa el número de vuelo'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _fechaCtrl,
                          readOnly: true,
                          onTap: _elegirFecha,
                          style: const TextStyle(color: Colors.white),
                          decoration: lapticonInput('Fecha del vuelo', Icons.calendar_month_outlined),
                          validator: (v) => _requerido(v, 'Selecciona la fecha'),
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: vm.validando ? null : _validar,
                          icon: vm.validando
                              ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: LapticonColors.acento))
                              : const Icon(Icons.verified_outlined),
                          label: Text(vm.validando ? 'Validando vuelo...' : 'Validar vuelo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: LapticonColors.acento,
                            side: const BorderSide(color: LapticonColors.acento),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        if (vuelo != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.greenAccent),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Vuelo verificado'
                                        '${vuelo.aerolinea.isNotEmpty ? ' · ${vuelo.aerolinea}' : ''}\n'
                                        '${vuelo.origen} → ${vuelo.destino}'
                                        '${vuelo.salida.isNotEmpty ? '\nSalida: ${vuelo.salida}' : ''}',
                                    style: const TextStyle(color: Colors.white, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
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
                    // Solo se habilita después de validar el vuelo
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
