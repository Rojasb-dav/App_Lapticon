import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../models/viaje_model.dart';
import '../../../models/encomienda_model.dart';
import '../../../models/chat_model.dart';
import '../../../router/app_router.dart';
import '../../../viewmodels/role_viewmodel.dart';
import '../../../viewmodels/viaje_viewmodel.dart';
import '../../../viewmodels/encomienda_viewmodel.dart';
import '../../../viewmodels/user_viewmodel.dart';
import '../../../viewmodels/chat_viewmodel.dart';
import '../../../widgets/lapticon_ui.dart';

/// Pestaña "Viajes".
/// - Viajero: registra viajes, ve encomiendas de otros en su ruta y las acepta.
///   "Encomiendas que llevo" sale de Firestore, así no desaparece al aceptar.
/// - Remitente: aviso para cambiar de rol.
class ViajesTab extends StatefulWidget {
  const ViajesTab({super.key});

  @override
  State<ViajesTab> createState() => _ViajesTabState();
}

class _ViajesTabState extends State<ViajesTab> {
  bool _solicitado = false;
  ViajeModel? _viajeSeleccionado;

  Future<void> _irARegistrar() async {
    final ok = await context.push<bool>(AppRoutes.registrarViaje);
    if (ok == true && mounted) {
      await context.read<ViajeViewModel>().cargarMisViajes();
    }
  }

  void _buscarEncomiendas(ViajeModel viaje) {
    setState(() => _viajeSeleccionado = viaje);
    context.read<EncomiendaViewModel>().buscarEncomiendasParaViajero(
      origen: viaje.origen,
      destino: viaje.destino,
    );
  }

  /// Aceptar: PUT /api/encomiendas/tomar/:id y luego registrar el chat en Firestore.
  Future<void> _aceptarEncomienda(EncomiendaModel enc) async {
    final encomiendaVM = context.read<EncomiendaViewModel>();
    final chatVM = context.read<ChatViewModel>();
    final viajeroNombre =
        context.read<UserViewModel>().userProfile?.nombreCompleto ?? 'Viajero';

    final ok = await encomiendaVM.tomarEncomienda(
        encomienda: enc, viajeroNombre: viajeroNombre);
    if (!mounted) return;

    if (!ok) {
      _snack(encomiendaVM.errorMessage ?? 'No se pudo aceptar la encomienda.',
          Colors.redAccent, Icons.error_outline);
      return;
    }

    final errorChat = await chatVM.asegurarChat(
      chatId: enc.id,
      uidRemitente: enc.uidRemitente,
      nombreRemitente: enc.nombreRemitente,
      nombreViajero: viajeroNombre,
      ruta: '${enc.origen} → ${enc.destino}',
    );
    if (!mounted) return;

    if (errorChat != null) {
      _snack('Encomienda aceptada, pero no se pudo crear el chat: $errorChat',
          Colors.orange, Icons.warning_amber_rounded);
      return;
    }
    _snack('¡Encomienda aceptada! Búscala en "Encomiendas que llevo".',
        Colors.green, Icons.check_circle_outline);
  }

  void _snack(String texto, Color color, IconData icono) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icono, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _confirmarEliminarViaje(ViajeModel viaje) async {
    final vm = context.read<ViajeViewModel>();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('¿Cerrar este viaje?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Tu viaje ${viaje.origen} ➔ ${viaje.destino} (Vuelo ${viaje.numeroVuelo}) dejará de aparecer y podrás registrar uno nuevo. Las encomiendas que ya aceptaste y sus chats se conservan.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Cerrar viaje', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    final error = await vm.eliminarViaje(viaje.id);
    if (!mounted) return;
    if (error != null) {
      _snack(error, Colors.redAccent, Icons.error_outline);
      return;
    }
    _snack('Viaje cerrado. Ya puedes registrar uno nuevo.', Colors.green,
        Icons.check_circle_outline);

    final viajes = vm.viajes;
    setState(() => _viajeSeleccionado = viajes.isNotEmpty ? viajes.first : null);
    if (_viajeSeleccionado != null) _buscarEncomiendas(_viajeSeleccionado!);
  }

  String _fmtFecha(DateTime? d) {
    if (d == null) return 'Sin fecha';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final roleVM = context.watch<RoleViewModel>();
    if (!roleVM.esViajero) return const _VistaRemitente();

    if (!_solicitado) {
      _solicitado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final viajeVM = context.read<ViajeViewModel>();
        await viajeVM.cargarMisViajes();
        if (!mounted) return;
        if (viajeVM.viajes.isNotEmpty) _buscarEncomiendas(viajeVM.viajes.first);
      });
    }

    final viajeVM = context.watch<ViajeViewModel>();
    final encomiendaVM = context.watch<EncomiendaViewModel>();
    final chatVM = context.watch<ChatViewModel>();
    final miUid = chatVM.miUid;

    // Si el viaje seleccionado ya no está en la lista, se toma el primero.
    if (_viajeSeleccionado != null &&
        !viajeVM.viajes.any((v) => v.id == _viajeSeleccionado!.id)) {
      _viajeSeleccionado = viajeVM.viajes.isNotEmpty ? viajeVM.viajes.first : null;
    }

    // Encomiendas que YO llevo (desde Firestore, no desaparecen).
    final llevo = chatVM.misChats
        .where((c) => c.uidViajero == miUid && !c.soyRemitente(miUid))
        .toList();
    final idsLlevo = llevo.map((c) => c.chatId).toSet();

    // Disponibles de la ruta, sin las que ya acepté (esas van en "que llevo").
    final disponibles = encomiendaVM.encomiendasDisponiblesRuta
        .where((e) => !idsLlevo.contains(e.id))
        .toList();

    return RefreshIndicator(
      color: LapticonColors.acento,
      onRefresh: () async {
        await viajeVM.cargarMisViajes();
        if (_viajeSeleccionado != null) {
          await encomiendaVM.buscarEncomiendasParaViajero(
            origen: _viajeSeleccionado!.origen,
            destino: _viajeSeleccionado!.destino,
          );
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          GradientButton(
            text: 'Registrar nuevo viaje',
            icon: Icons.add_rounded,
            onPressed: _irARegistrar,
          ),
          const SizedBox(height: 24),
          const Text('Mis viajes programados',
              style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (viajeVM.cargandoLista && viajeVM.viajes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(
                  child: CircularProgressIndicator(color: LapticonColors.acento)),
            )
          else if (viajeVM.viajes.isEmpty)
            const _Mensaje(
              icon: Icons.luggage_rounded,
              titulo: 'Aún no tienes viajes registrados',
              texto:
              'Registra tu próximo viaje para encontrar encomiendas en tu misma ruta.',
            )
          else ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: viajeVM.viajes.map((v) {
                    final esSel = _viajeSeleccionado?.id == v.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        selected: esSel,
                        showCheckmark: false,
                        avatar: Icon(Icons.flight_takeoff_rounded,
                            size: 16, color: esSel ? Colors.black : Colors.white),
                        label: Text('${v.origen} → ${v.destino}'),
                        labelStyle: TextStyle(
                          color: esSel ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        selectedColor: const Color(0xFF38BDF8),
                        backgroundColor: const Color(0xFF1E293B),
                        onSelected: (_) => _buscarEncomiendas(v),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              if (_viajeSeleccionado != null) ...[
                _TarjetaViaje(
                  viaje: _viajeSeleccionado!,
                  fecha: _fmtFecha(_viajeSeleccionado!.fecha),
                  onCerrar: () => _confirmarEliminarViaje(_viajeSeleccionado!),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Encomiendas en tu Ruta',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    if (encomiendaVM.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF38BDF8)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (disponibles.isEmpty)
                  _Mensaje(
                    icon: Icons.search_off_rounded,
                    titulo: 'Sin solicitudes coincidentes',
                    texto:
                    'No hay encomiendas nuevas para la ruta ${_viajeSeleccionado!.origen} → ${_viajeSeleccionado!.destino}. Desliza hacia abajo para actualizar.',
                  )
                else
                  ...disponibles.map(
                        (enc) => _EncomiendaCoincidenteCard(
                      encomienda: enc,
                      onAceptar: () => _aceptarEncomienda(enc),
                    ),
                  ),
              ],
            ],

          // ---- Encomiendas que llevo (Firestore) ----
          if (llevo.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text('Encomiendas que llevo',
                style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Encomiendas que aceptaste. Coordina la entrega por chat.',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 12),
            ...llevo.map((c) => _LlevoCard(chat: c, miUid: miUid)),
          ],
        ],
      ),
    );
  }
}

/// Tarjeta del viaje seleccionado (con etiqueta "En curso" si aplica).
class _TarjetaViaje extends StatelessWidget {
  final ViajeModel viaje;
  final String fecha;
  final VoidCallback onCerrar;
  const _TarjetaViaje(
      {required this.viaje, required this.fecha, required this.onCerrar});

  @override
  Widget build(BuildContext context) {
    final enCurso =
    !['disponible', 'activo'].contains(viaje.estado.toLowerCase());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flight_rounded, color: Color(0xFF38BDF8), size: 22),
              const SizedBox(width: 8),
              Text('Vuelo ${viaje.numeroVuelo}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(width: 8),
              if (enCurso)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('En curso',
                      style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 20),
                tooltip: 'Cerrar viaje',
                onPressed: onCerrar,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _Dato(icon: Icons.event_outlined, texto: 'Fecha: $fecha'),
              _Dato(
                  icon: Icons.location_on_outlined,
                  texto: 'Ruta: ${viaje.origen} ➔ ${viaje.destino}'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de una encomienda que llevo, con acceso directo al chat.
class _LlevoCard extends StatelessWidget {
  final ChatResumen chat;
  final String miUid;
  const _LlevoCard({required this.chat, required this.miUid});

  @override
  Widget build(BuildContext context) {
    final nombre = chat.nombreDelOtro(miUid);
    final nuevo = chat.tieneMensajeNuevo(miUid);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push(AppRoutes.chat,
              extra: {'chatId': chat.chatId, 'receiverName': nombre}),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_rounded,
                    color: Colors.greenAccent, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('De: $nombre',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      if (chat.ruta.isNotEmpty)
                        Text(chat.ruta,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      if (chat.ultimoMensaje.isNotEmpty)
                        Text(chat.ultimoMensaje,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                Badge(
                  isLabelVisible: nuevo,
                  label: const Text('1'),
                  child: const Icon(Icons.chat_bubble_rounded,
                      color: Color(0xFF38BDF8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icon;
  final String texto;
  const _Dato({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white54, size: 14),
        const SizedBox(width: 6),
        Flexible(
          child: Text(texto,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
      ],
    );
  }
}

/// Encomienda disponible en la ruta (o vencida).
class _EncomiendaCoincidenteCard extends StatelessWidget {
  final EncomiendaModel encomienda;
  final VoidCallback onAceptar;
  const _EncomiendaCoincidenteCard(
      {required this.encomienda, required this.onAceptar});

  @override
  Widget build(BuildContext context) {
    final vencida = encomienda.estaVencida;
    final peso = encomienda.peso.trim();
    final tienePeso = peso.isNotEmpty && peso != '—' && peso != '-';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: vencida ? const Color(0xFF334155) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: vencida
                  ? Colors.grey.shade600
                  : const Color(0xFF38BDF8).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_pin_circle_rounded,
                    color: vencida ? Colors.grey : const Color(0xFF38BDF8),
                    size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(encomienda.nombreRemitente,
                      style: TextStyle(
                          color: vencida ? Colors.grey.shade300 : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (vencida ? Colors.grey : const Color(0xFFD97706))
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('\$${encomienda.valorPagar.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: vencida
                              ? Colors.grey.shade400
                              : const Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(encomienda.descripcion,
                style: TextStyle(
                    color: vencida ? Colors.grey.shade400 : Colors.white70,
                    fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                if (tienePeso)
                  _Dato(icon: Icons.scale_outlined, texto: 'Peso: $peso'),
                _Dato(
                  icon: Icons.event_outlined,
                  texto: vencida
                      ? 'Vencida: ${encomienda.fechaVencimiento}'
                      : 'Vence: ${encomienda.fechaVencimiento}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (vencida)
              const Center(
                child: Text('Encomienda Expirada',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: onAceptar,
                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  label: const Text('Aceptar Llevar Encomienda',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VistaRemitente extends StatelessWidget {
  const _VistaRemitente();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _Mensaje(
          icon: Icons.inventory_2_rounded,
          titulo: 'Estás usando Lapticon como Remitente',
          texto:
          'El registro y búsqueda de viajes es para viajeros. Cambia tu rol si vas a viajar y quieres llevar encomiendas.',
          accion: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GradientButton(
              text: 'Cambiar a Viajero',
              icon: Icons.swap_horiz_rounded,
              onPressed: () => context.push(AppRoutes.roleSelection),
            ),
          ),
        ),
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String texto;
  final Widget? accion;
  const _Mensaje(
      {required this.icon, required this.titulo, required this.texto, this.accion});

  @override
  Widget build(BuildContext context) {
    return LapticonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 48, color: LapticonColors.acento),
          const SizedBox(height: 14),
          Text(titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.4)),
          if (accion != null) accion!,
        ],
      ),
    );
  }
}
