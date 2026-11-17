import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../models/viaje_model.dart';
import '../../../models/encomienda_model.dart';
import '../../../router/app_router.dart';
import '../../../viewmodels/role_viewmodel.dart';
import '../../../viewmodels/viaje_viewmodel.dart';
import '../../../viewmodels/encomienda_viewmodel.dart';
import '../../../viewmodels/user_viewmodel.dart';
import '../../../widgets/lapticon_ui.dart';

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
      context.read<ViajeViewModel>().cargarMisViajes();
    }
  }

  void _buscarEncomiendas(ViajeModel viaje) {
    setState(() {
      _viajeSeleccionado = viaje;
    });
    context.read<EncomiendaViewModel>().buscarEncomiendasParaViajero(
      origen: viaje.origen,
      destino: viaje.destino,
    );
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
        final viajes = viajeVM.viajes;
        if (viajes.isNotEmpty) {
          _buscarEncomiendas(viajes.first);
        }
      });
    }

    final viajeVM = context.watch<ViajeViewModel>();
    final encomiendaVM = context.watch<EncomiendaViewModel>();
    final userVM = context.watch<UserViewModel>();

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
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (viajeVM.cargandoLista)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator(color: LapticonColors.acento)),
            )
          else if (viajeVM.viajes.isEmpty)
            const _Mensaje(
              icon: Icons.luggage_rounded,
              titulo: 'Aún no tienes viajes registrados',
              texto: 'Registra tu próximo viaje para encontrar encomiendas en tu misma ruta.',
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
                      avatar: Icon(
                        Icons.flight_takeoff_rounded,
                        size: 16,
                        color: esSel ? Colors.black : Colors.white,
                      ),
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
            const SizedBox(height: 24),
            if (_viajeSeleccionado != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_rounded, color: Color(0xFF38BDF8), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Filtrando encomiendas para la ruta:\n${_viajeSeleccionado!.origen}  ➔  ${_viajeSeleccionado!.destino}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Encomiendas en tu Ruta',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (encomiendaVM.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (encomiendaVM.encomiendasDisponiblesRuta.isEmpty)
                _Mensaje(
                  icon: Icons.search_off_rounded,
                  titulo: 'Sin solicitudes coincidentes',
                  texto: 'No hay encomiendas registradas para la ruta ${_viajeSeleccionado!.origen} → ${_viajeSeleccionado!.destino} en este momento.',
                )
              else
                ...encomiendaVM.encomiendasDisponiblesRuta.map(
                  (enc) => _EncomiendaCoincidenteCard(
                    encomienda: enc,
                    onAceptar: () async {
                      final viajeroNombre = userVM.userProfile?.nombreCompleto ?? 'Viajero';
                      final ok = await encomiendaVM.tomarEncomienda(
                        encomienda: enc,
                        viajeroNombre: viajeroNombre,
                      );
                      if (context.mounted) {
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.white),
                                  SizedBox(width: 10),
                                  Expanded(child: Text('¡Encomienda aceptada! Se ha habilitado el chat con el remitente.')),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _EncomiendaCoincidenteCard extends StatelessWidget {
  final EncomiendaModel encomienda;
  final VoidCallback onAceptar;

  const _EncomiendaCoincidenteCard({
    required this.encomienda,
    required this.onAceptar,
  });

  @override
  Widget build(BuildContext context) {
    final aceptada = !encomienda.estaDisponible;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: aceptada
                ? Colors.green.withValues(alpha: 0.4)
                : const Color(0xFF38BDF8).withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_pin_circle_rounded, color: Color(0xFF38BDF8), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      encomienda.nombreRemitente,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '\$${encomienda.valorPagar.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              encomienda.descripcion,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.scale_outlined, color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Peso: ${encomienda.peso}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.event_outlined, color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Vence: ${encomienda.fechaVencimiento}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (aceptada)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
                          SizedBox(width: 6),
                          Text('Encomienda Aceptada',
                              style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () {
                      context.push(
                        AppRoutes.chat,
                        extra: {
                          'chatId': encomienda.id,
                          'receiverName': encomienda.nombreRemitente,
                        },
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF38BDF8)),
                    tooltip: 'Abrir Chat',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: onAceptar,
                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Aceptar Llevar Encomienda',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          texto: 'El registro y búsqueda de viajes es para viajeros. Cambia tu rol si vas a viajar y quieres llevar encomiendas.',
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
          if (accion case final Widget a) a,
        ],
      ),
    );
  }
}
