import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../models/viaje_model.dart';
import '../../../router/app_router.dart';
import '../../../viewmodels/role_viewmodel.dart';
import '../../../viewmodels/viaje_viewmodel.dart';
import '../../../widgets/lapticon_ui.dart';

class ViajesTab extends StatefulWidget {
  const ViajesTab({super.key});

  @override
  State<ViajesTab> createState() => _ViajesTabState();
}

class _ViajesTabState extends State<ViajesTab> {
  bool _solicitado = false;

  Future<void> _irARegistrar() async {
    final ok = await context.push<bool>(AppRoutes.registrarViaje);
    if (ok == true && mounted) context.read<ViajeViewModel>().cargarMisViajes();
  }

  @override
  Widget build(BuildContext context) {
    final roleVM = context.watch<RoleViewModel>();

    if (!roleVM.esViajero) return const _VistaRemitente();

    // Carga la lista la primera vez que el viajero entra a la pestaña
    if (!_solicitado) {
      _solicitado = true;
      WidgetsBinding.instance.addPostFrameCallback(
              (_) => context.read<ViajeViewModel>().cargarMisViajes());
    }

    final vm = context.watch<ViajeViewModel>();

    return RefreshIndicator(
      color: LapticonColors.acento,
      onRefresh: vm.cargarMisViajes,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          GradientButton(
            text: 'Registrar nuevo viaje',
            icon: Icons.add_rounded,
            onPressed: _irARegistrar,
          ),
          const SizedBox(height: 28),
          const Text('Mis viajes',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          if (vm.cargandoLista)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(color: LapticonColors.acento)),
            )
          else if (vm.errorLista != null)
            _Mensaje(
              icon: Icons.cloud_off_rounded,
              titulo: 'No pudimos cargar tus viajes',
              texto: vm.errorLista!,
              accion: TextButton(
                onPressed: vm.cargarMisViajes,
                child: const Text('Reintentar', style: TextStyle(color: LapticonColors.acento)),
              ),
            )
          else if (vm.viajes.isEmpty)
              const _Mensaje(
                icon: Icons.luggage_rounded,
                titulo: 'Aún no tienes viajes',
                texto: 'Registra tu próximo vuelo para empezar a llevar encomiendas.',
              )
            else
              ...vm.viajes.map((v) => _ViajeCard(viaje: v)),
        ],
      ),
    );
  }
}

class _ViajeCard extends StatelessWidget {
  final ViajeModel viaje;
  const _ViajeCard({required this.viaje});

  @override
  Widget build(BuildContext context) {
    final completado = viaje.estado.toLowerCase() == 'completado';
    final f = viaje.fecha;
    final fecha = f == null
        ? 'Sin fecha'
        : '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LapticonCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LapticonColors.azul1.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.flight_rounded, color: LapticonColors.acento),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${viaje.origen} → ${viaje.destino}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Vuelo ${viaje.numeroVuelo} · $fecha',
                      style: const TextStyle(color: Colors.white60, fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (completado ? Colors.grey : Colors.green).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(completado ? 'Completado' : 'Activo',
                  style: TextStyle(
                      color: completado ? Colors.white60 : Colors.greenAccent,
                      fontSize: 12, fontWeight: FontWeight.bold)),
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
          texto: 'El registro de viajes es para viajeros. Cambia tu rol si vas a viajar y quieres llevar encomiendas.',
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
          if (accion != null) accion!,
        ],
      ),
    );
  }
}
