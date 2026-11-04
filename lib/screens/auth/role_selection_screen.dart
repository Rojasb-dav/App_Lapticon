import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/role_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../router/app_router.dart';

/// Pantalla que aparece después del login.
/// El usuario desliza un switch para elegir si entra como Remitente o Viajero.
/// El rol se guarda en el backend (PUT /api/users/:uid) mediante RoleViewModel,
/// que además lo deja en SharedPreferences solo como caché.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  /// true = Viajero, false = Remitente.
  late bool _esViajero;

  /// Posición del círculo del switch: 0 = izquierda (Remitente), 1 = derecha (Viajero).
  double _posicion = 0;

  @override
  void initState() {
    super.initState();
    // Preselecciona el rol que ya estaba guardado (lo cargó el login con cargarRol).
    _esViajero = context.read<RoleViewModel>().esViajero;
    _posicion = _esViajero ? 1 : 0;
  }

  /// Fija el rol elegido y mueve el switch al lado correspondiente.
  void _seleccionar(bool viajero) {
    setState(() {
      _esViajero = viajero;
      _posicion = viajero ? 1 : 0;
    });
  }

  /// Guarda el rol en el backend y, si sale bien, entra a Inicio.
  Future<void> _continuar() async {
    final roleVM = context.read<RoleViewModel>();
    final profile = context.read<UserViewModel>().userProfile;

    // Sin perfil no se puede hacer el PUT: primero hay que completarlo.
    if (profile == null) {
      context.go(AppRoutes.completeProfile);
      return;
    }

    final rol = _esViajero ? AppRoles.viajero : AppRoles.remitente;
    final ok = await roleVM.guardarRol(rol, profile);
    if (!mounted) return;

    if (ok) {
      context.go(AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(roleVM.errorMessage ?? 'No se pudo guardar el rol'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<RoleViewModel>().isLoading;

    return Scaffold(
      body: Container(
        // Mismo degradado del login.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.swap_horiz_rounded, size: 64, color: Color(0xFF38BDF8)),
                  const SizedBox(height: 16),
                  const Text(
                    '¿Cómo quieres usar Lapticon hoy?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Desliza para elegir tu rol. Puedes cambiarlo cada vez que ingreses.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 32),

                  // Tarjeta translúcida con el switch.
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    child: Column(
                      children: [
                        _buildSwitch(),
                        const SizedBox(height: 20),
                        Text(
                          _esViajero
                              ? 'Como Viajero registras tus vuelos y llevas encomiendas.'
                              : 'Como Remitente publicas encomiendas para que un viajero las lleve.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón con degradado igual al del login.
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _continuar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                            : const Text(
                          'Continuar',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
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

  /// Switch deslizable: se puede arrastrar el círculo o tocar un lado.
  Widget _buildSwitch() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final mitad = ancho / 2;

        return GestureDetector(
          // Tocar un lado selecciona ese rol.
          onTapUp: (d) => _seleccionar(d.localPosition.dx > mitad),
          // Arrastrar mueve el círculo siguiendo el dedo.
          onHorizontalDragUpdate: (d) {
            setState(() => _posicion = (_posicion + d.delta.dx / mitad).clamp(0.0, 1.0));
          },
          // Al soltar, se queda en el lado más cercano.
          onHorizontalDragEnd: (_) => _seleccionar(_posicion > 0.5),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Stack(
              children: [
                // Textos de fondo.
                const Row(
                  children: [
                    Expanded(child: Center(child: Text('Remitente', style: TextStyle(color: Colors.white38)))),
                    Expanded(child: Center(child: Text('Viajero', style: TextStyle(color: Colors.white38)))),
                  ],
                ),
                // Círculo que se desliza.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  left: _posicion * mitad,
                  top: 4,
                  bottom: 4,
                  width: mitad,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF2563EB)]),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _posicion > 0.5 ? Icons.flight_takeoff_rounded : Icons.inventory_2_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _posicion > 0.5 ? 'Viajero' : 'Remitente',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
