import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../models/encomienda_model.dart';
import '../../../router/app_router.dart';
import '../../../viewmodels/role_viewmodel.dart';
import '../../../viewmodels/encomienda_viewmodel.dart';
import '../../../widgets/lapticon_ui.dart';

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
      context.read<EncomiendaViewModel>().cargarMisEncomiendas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleVM = context.watch<RoleViewModel>();

    if (!roleVM.esRemitente) return const _VistaViajero();

    if (!_solicitado) {
      _solicitado = true;
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.read<EncomiendaViewModel>().cargarMisEncomiendas());
    }

    final vm = context.watch<EncomiendaViewModel>();

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
                colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
              ),
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
              label: const Text(
                'Publicar Nueva Encomienda',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mis Encomiendas Creadas',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              if (vm.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (vm.isLoading && vm.misEncomiendas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
            )
          else if (vm.misEncomiendas.isEmpty)
            const _Mensaje(
              icon: Icons.inventory_2_outlined,
              titulo: 'Aún no has publicado encomiendas',
              texto: 'Crea tu primera solicitud especificando la ruta, peso y valor a pagar.',
            )
          else
            ...vm.misEncomiendas.map((e) => _EncomiendaCard(encomienda: e)),
        ],
      ),
    );
  }
}

class _EncomiendaCard extends StatelessWidget {
  final EncomiendaModel encomienda;
  const _EncomiendaCard({required this.encomienda});

  @override
  Widget build(BuildContext context) {
    final tomada = encomienda.estaTomada;
    final entregada = encomienda.estaEntregada;

    Color estadoColor = const Color(0xFFF59E0B);
    String estadoTexto = 'Buscando viajero';

    if (tomada) {
      estadoColor = Colors.greenAccent;
      estadoTexto = 'Aceptada por viajero';
    } else if (entregada) {
      estadoColor = Colors.blueAccent;
      estadoTexto = 'Entregada';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LapticonCard(
        padding: const EdgeInsets.all(18),
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
                      Text(
                        '${encomienda.origen} ➔ ${encomienda.destino}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        encomienda.descripcion,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${encomienda.valorPagar.toStringAsFixed(2)}',
                  style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    estadoTexto,
                    style: TextStyle(color: estadoColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  'Vence: ${encomienda.fechaVencimiento}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
            if (tomada) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push(
                      AppRoutes.chat,
                      extra: {
                        'chatId': encomienda.id,
                        'receiverName': encomienda.nombreViajero ?? 'Viajero Asignado',
                      },
                    );
                  },
                  icon: const Icon(Icons.chat_rounded, color: Color(0xFF38BDF8), size: 18),
                  label: Text(
                    'Chat con ${encomienda.nombreViajero ?? "Viajero"}',
                    style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF38BDF8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
          texto: 'La creación de solicitudes de paquetes es para remitentes. En la pestaña Viajes puedes ver e interactuar con las encomiendas registradas en tu ruta.',
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

class _Mensaje extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String texto;
  final Widget? accion;
  const _Mensaje({required this.icon, required this.titulo, required this.texto, this.accion});

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
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.4)),
          if (accion case final Widget a) a,
        ],
      ),
    );
  }
}
