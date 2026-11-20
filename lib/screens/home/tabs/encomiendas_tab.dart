import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../models/encomienda_model.dart';
import '../../../models/chat_model.dart';
import '../../../router/app_router.dart';
import '../../../viewmodels/role_viewmodel.dart';
import '../../../viewmodels/encomienda_viewmodel.dart';
import '../../../viewmodels/chat_viewmodel.dart';
import '../../../widgets/lapticon_ui.dart';

/// Pestaña "Encomiendas" (remitente).
/// - "Aceptadas por un viajero": desde Firestore, con botón de chat.
/// - "Buscando viajero": desde el backend, con botón 🗑️ para eliminar.
class EncomiendasTab extends StatefulWidget {
  const EncomiendasTab({super.key});

  @override
  State<EncomiendasTab> createState() => _EncomiendasTabState();
}

class _EncomiendasTabState extends State<EncomiendasTab> {
  bool _solicitado = false;

  Future<void> _irAPublicar() async {
    final ok = await context.push<bool>(AppRoutes.crearEncomienda);
    if (ok == true && mounted) {
      await context.read<EncomiendaViewModel>().cargarMisEncomiendas();
    }
  }

  /// Pide confirmación y elimina la encomienda.
  Future<void> _confirmarEliminar(EncomiendaModel enc) async {
    final vm = context.read<EncomiendaViewModel>();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('¿Eliminar esta encomienda?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          '${enc.origen} ➔ ${enc.destino}\n"${enc.descripcion}"\n\nDejará de aparecer a los viajeros. Esta acción no se puede deshacer.',
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
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    final error = await vm.eliminarEncomienda(enc);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(error == null ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
              child: Text(error ??
                  'Encomienda eliminada. Ya no aparecerá a los viajeros.')),
        ]),
        backgroundColor: error == null ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleVM = context.watch<RoleViewModel>();
    if (!roleVM.esRemitente) return const _VistaViajero();

    if (!_solicitado) {
      _solicitado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<EncomiendaViewModel>().cargarMisEncomiendas();
        context.read<ChatViewModel>().escucharMisChats();
      });
    }

    final vm = context.watch<EncomiendaViewModel>();
    final chatVM = context.watch<ChatViewModel>();
    final miUid = chatVM.miUid;

    final aceptadas =
    chatVM.misChats.where((c) => c.soyRemitente(miUid) && c.tieneViajero).toList();
    final idsAceptadas = aceptadas.map((c) => c.chatId).toSet();
    final buscando =
    vm.misEncomiendas.where((e) => !idsAceptadas.contains(e.id)).toList();

    return RefreshIndicator(
      color: const Color(0xFFF59E0B),
      onRefresh: vm.cargarMisEncomiendas,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFFF59E0B)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _irAPublicar,
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
              label: const Text('Publicar Nueva Encomienda',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          if (aceptadas.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text('Aceptadas por un viajero',
                style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Coordina la entrega con el viajero por chat.',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 12),
            ...aceptadas.map((c) => _AceptadaCard(chat: c, miUid: miUid)),
          ],

          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Buscando viajero',
                  style: TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              if (vm.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFFF59E0B)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (vm.isLoading && buscando.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
            )
          else if (buscando.isEmpty)
            _Mensaje(
              icon: Icons.inventory_2_outlined,
              titulo: aceptadas.isEmpty
                  ? 'Aún no has publicado encomiendas'
                  : 'No tienes encomiendas pendientes',
              texto: aceptadas.isEmpty
                  ? 'Crea tu primera solicitud especificando la ruta, peso y valor a pagar.'
                  : 'Todas tus encomiendas ya tienen viajero. Publica una nueva cuando quieras.',
            )
          else
            ...buscando.map((e) => _EncomiendaCard(
              encomienda: e,
              onEliminar: () => _confirmarEliminar(e),
            )),
        ],
      ),
    );
  }
}

/// Encomienda aceptada: viajero, ruta, último mensaje y botón de chat.
class _AceptadaCard extends StatelessWidget {
  final ChatResumen chat;
  final String miUid;
  const _AceptadaCard({required this.chat, required this.miUid});

  @override
  Widget build(BuildContext context) {
    final viajero = chat.nombreDelOtro(miUid);
    final nuevo = chat.tieneMensajeNuevo(miUid) || !chat.matchVisto;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2_rounded,
                      color: Colors.greenAccent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(chat.ruta.isEmpty ? 'Encomienda' : chat.ruta,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('Viajero: $viajero',
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      if (chat.ultimoMensaje.isNotEmpty)
                        Text(chat.ultimoMensaje,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                            const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Aceptada',
                      style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<ChatViewModel>().marcarMatchVisto(chat.chatId);
                  context.push(AppRoutes.chat,
                      extra: {'chatId': chat.chatId, 'receiverName': viajero});
                },
                icon: Badge(
                  isLabelVisible: nuevo,
                  smallSize: 8,
                  child: const Icon(Icons.chat_rounded,
                      color: Color(0xFF38BDF8), size: 18),
                ),
                label: Text('Chat con $viajero',
                    style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF38BDF8)),
                  shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Encomienda que busca viajero (o vencida), con botón 🗑️ para eliminar.
class _EncomiendaCard extends StatelessWidget {
  final EncomiendaModel encomienda;
  final VoidCallback onEliminar;
  const _EncomiendaCard({required this.encomienda, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final vencida = encomienda.estaVencida;
    final estadoColor = vencida ? Colors.grey : const Color(0xFFF59E0B);
    final estadoTexto = vencida ? 'Expirada / Vencida' : 'Buscando viajero';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: vencida ? const Color(0xFF334155) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: vencida
                  ? Colors.grey.shade600
                  : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.inventory_2_rounded, color: estadoColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${encomienda.origen} ➔ ${encomienda.destino}',
                          style: TextStyle(
                              color: vencida ? Colors.grey.shade300 : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(encomienda.descripcion,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: vencida ? Colors.grey.shade400 : Colors.white70,
                              fontSize: 13)),
                    ],
                  ),
                ),
                Text('\$${encomienda.valorPagar.toStringAsFixed(2)}',
                    style: TextStyle(
                        color:
                        vencida ? Colors.grey.shade400 : const Color(0xFFF59E0B),
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(estadoTexto,
                      style: TextStyle(
                          color: estadoColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vencida
                        ? 'Vencida: ${encomienda.fechaVencimiento}'
                        : 'Vence: ${encomienda.fechaVencimiento}',
                    style: TextStyle(
                      color: vencida ? Colors.redAccent : Colors.white54,
                      fontWeight: vencida ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Eliminar encomienda',
                  onPressed: onEliminar,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista cuando el usuario está en modo Viajero.
class _VistaViajero extends StatelessWidget {
  const _VistaViajero();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _Mensaje(
          icon: Icons.flight_takeoff_rounded,
          titulo: 'Estás usando Lapticon como Viajero',
          texto:
          'La creación de solicitudes de paquetes es para remitentes. En la pestaña Viajes puedes ver y aceptar las encomiendas de tu ruta.',
          accion: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GradientButton(
              text: 'Cambiar a Remitente',
              icon: Icons.swap_horiz_rounded,
              onPressed: () => context.push(AppRoutes.roleSelection),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de mensaje informativo.
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
