import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/encomienda_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../widgets/lapticon_ui.dart';

class CrearEncomiendaScreen extends StatefulWidget {
  const CrearEncomiendaScreen({super.key});

  @override
  State<CrearEncomiendaScreen> createState() => _CrearEncomiendaScreenState();
}

class _CrearEncomiendaScreenState extends State<CrearEncomiendaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _descripcionCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController(text: '2 kg');
  final _valorPagarCtrl = TextEditingController(text: '20.0');
  final _fechaCtrl = TextEditingController();

  final TextEditingController _origenCtrl = TextEditingController(text: 'Bogotá');
  final TextEditingController _destinoCtrl = TextEditingController(text: 'Medellín');

  static const List<String> _ciudades = [
    'Bogotá',
    'Cali',
    'Medellín',
    'Miami',
    'Madrid',
  ];

  DateTime? _fechaVencimiento;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now().add(const Duration(days: 5));
    _fechaVencimiento = hoy;
    _fechaCtrl.text = _fmt(hoy);
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _pesoCtrl.dispose();
    _valorPagarCtrl.dispose();
    _fechaCtrl.dispose();
    _origenCtrl.dispose();
    _destinoCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaVencimiento ?? hoy.add(const Duration(days: 3)),
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: hoy.add(const Duration(days: 90)),
      helpText: 'Fecha límite de la encomienda',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFF59E0B),
            surface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (elegida != null) {
      setState(() {
        _fechaVencimiento = elegida;
        _fechaCtrl.text = _fmt(elegida);
      });
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

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_origenCtrl.text == _destinoCtrl.text) {
      _snack('El origen y el destino no pueden ser iguales.');
      return;
    }

    FocusScope.of(context).unfocus();

    final userVM = context.read<UserViewModel>();
    final encomiendaVM = context.read<EncomiendaViewModel>();

    final valor = double.tryParse(_valorPagarCtrl.text.trim()) ?? 0.0;
    final nombreRemitente = userVM.userProfile?.nombreCompleto ?? 'Remitente';

    final ok = await encomiendaVM.crearEncomienda(
      origen: _origenCtrl.text.trim(),
      destino: _destinoCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      peso: _pesoCtrl.text.trim(),
      valorPagar: valor,
      fechaVencimiento: _fechaCtrl.text,
      nombreRemitente: nombreRemitente,
    );

    if (!mounted) return;

    if (ok) {
      _snack('¡Encomienda publicada exitosamente!', error: false);
      context.pop(true);
    } else {
      _snack(encomiendaVM.errorMessage ?? 'Error al publicar encomienda');
    }
  }

  Widget _selectorCiudad({
    required String label,
    required IconData icono,
    required TextEditingController controller,
    String? excluir,
  }) {
    final opciones = _ciudades.where((c) => c != excluir).toList();
    return DropdownButtonFormField<String>(
      initialValue: opciones.contains(controller.text) ? controller.text : opciones.first,
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white, fontSize: 16),
      iconEnabledColor: const Color(0xFFF59E0B),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icono, color: const Color(0xFFF59E0B)),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: opciones.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) => setState(() => controller.text = v ?? ''),
      validator: (v) => (v == null || v.isEmpty) ? 'Selecciona $label' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final encomiendaVM = context.watch<EncomiendaViewModel>();

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
        title: const Text('Publicar Encomienda',
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
                  const Text('Detalles del Envío',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Especifica la ruta, la descripción y el valor a pagar por el transporte.',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 24),
                  LapticonCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _selectorCiudad(
                          label: 'Ciudad de Origen',
                          icono: Icons.store_rounded,
                          controller: _origenCtrl,
                          excluir: _destinoCtrl.text,
                        ),
                        const SizedBox(height: 16),
                        _selectorCiudad(
                          label: 'Ciudad de Destino',
                          icono: Icons.location_on_rounded,
                          controller: _destinoCtrl,
                          excluir: _origenCtrl.text,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descripcionCtrl,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Descripción del paquete / contenido',
                            labelStyle: const TextStyle(color: Colors.white54),
                            prefixIcon: const Icon(Icons.inventory_2_outlined, color: Color(0xFFF59E0B)),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa una descripción' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _pesoCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Peso est.',
                                  labelStyle: const TextStyle(color: Colors.white54),
                                  prefixIcon: const Icon(Icons.scale_outlined, color: Color(0xFFF59E0B)),
                                  filled: true,
                                  fillColor: const Color(0xFF0F172A),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _valorPagarCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Valor a Pagar (\$)',
                                  labelStyle: const TextStyle(color: Colors.white54),
                                  prefixIcon: const Icon(Icons.attach_money_rounded, color: Color(0xFFF59E0B)),
                                  filled: true,
                                  fillColor: const Color(0xFF0F172A),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                                  if (double.tryParse(v.trim()) == null) return 'Valor inválido';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _fechaCtrl,
                          readOnly: true,
                          onTap: _elegirFecha,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Fecha límite de validez',
                            labelStyle: const TextStyle(color: Colors.white54),
                            prefixIcon: const Icon(Icons.event_available_outlined, color: Color(0xFFF59E0B)),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD97706).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: encomiendaVM.isLoading ? null : _publicar,
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      label: encomiendaVM.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Publicar Encomienda',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
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
