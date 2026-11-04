import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../router/app_router.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _telefonoController;
  String? _selectedNacionalidad;

  final List<String> _paises = const [
    'Ecuador',
    'Colombia',
    'Perú',
    'Venezuela',
    'México',
    'Argentina',
    'Chile',
    'Bolivia',
    'Brasil',
    'Uruguay',
    'Paraguay',
    'Costa Rica',
    'Panamá',
    'Guatemala',
    'Honduras',
    'Nicaragua',
    'El Salvador',
    'República Dominicana',
    'Cuba',
    'Puerto Rico',
    'España',
    'Estados Unidos',
    'Canadá',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final profile = userVM.userProfile;

    _nombreController = TextEditingController(text: profile?.nombre ?? '');
    _apellidoController = TextEditingController(text: profile?.apellido ?? '');
    _telefonoController = TextEditingController(text: profile?.telefono ?? '');

    if (profile?.nacionalidad.isNotEmpty == true) {
      if (_paises.contains(profile!.nacionalidad)) {
        _selectedNacionalidad = profile.nacionalidad;
      } else {
        _selectedNacionalidad = 'Otro';
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final isEditing = userVM.hasProfile;

    final success = await userVM.completeProfile(
      nombre: _nombreController.text,
      apellido: _apellidoController.text,
      telefono: _telefonoController.text,
      nacionalidad: _selectedNacionalidad ?? 'Ecuador',
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? '¡Perfil actualizado exitosamente!'
              : '¡Perfil registrado exitosamente!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.go(AppRoutes.home);
    } else {
      final error = userVM.errorMessage ?? 'Error al guardar el perfil.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final userVM = Provider.of<UserViewModel>(context, listen: false);

    await authVM.signOut();
    userVM.clearProfile();

    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userVM = Provider.of<UserViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final firebaseEmail = authVM.currentUser?.email ?? '';
    final isEditing = userVM.hasProfile;

    // Regla de Nacionalidad:
    // 1. Si es usuario nuevo -> Se elige en la creación (canEditNacionalidad = true)
    // 2. Si es usuario existente sin país definido -> Se habilita por ÚNICA VEZ para seleccionarlo de la lista.
    // 3. Una vez guardada la nacionalidad -> Queda bloqueada permanentemente.
    final savedNacionalidad = userVM.userProfile?.nacionalidad ?? '';
    final hasValidNacionalidad = savedNacionalidad.isNotEmpty &&
        savedNacionalidad != 'Sin registrar' &&
        _paises.contains(savedNacionalidad);

    final canEditNacionalidad = !isEditing || !hasValidNacionalidad;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Perfil' : 'Completar Perfil',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Cerrar Sesión',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Header Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isEditing
                        ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                        : Colors.blueAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isEditing
                          ? const Color(0xFF38BDF8).withValues(alpha: 0.3)
                          : Colors.blueAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isEditing ? Icons.lock_person_rounded : Icons.info_outline_rounded,
                        color: const Color(0xFF38BDF8),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Información del Perfil' : 'Un último paso',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEditing
                                  ? (canEditNacionalidad
                                      ? 'Puedes seleccionar tu nacionalidad por única vez y actualizar tu teléfono ($firebaseEmail).'
                                      : 'Nombre, Apellido y Nacionalidad no se pueden modificar. Puedes actualizar tu teléfono ($firebaseEmail).')
                                  : 'Selecciona tu país e ingresa tus datos personales para activar tu cuenta ($firebaseEmail).',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      // Nombre (Disabled if editing)
                      TextFormField(
                        controller: _nombreController,
                        enabled: !isEditing,
                        style: TextStyle(
                          color: isEditing ? Colors.white54 : Colors.white,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Nombre',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: Icon(
                            isEditing ? Icons.lock_outline : Icons.person_outline,
                            color: isEditing ? Colors.white38 : const Color(0xFF38BDF8),
                          ),
                          filled: true,
                          fillColor: isEditing ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa tu nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Apellido (Disabled if editing)
                      TextFormField(
                        controller: _apellidoController,
                        enabled: !isEditing,
                        style: TextStyle(
                          color: isEditing ? Colors.white54 : Colors.white,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Apellido',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: Icon(
                            isEditing ? Icons.lock_outline : Icons.badge_outlined,
                            color: isEditing ? Colors.white38 : const Color(0xFF38BDF8),
                          ),
                          filled: true,
                          fillColor: isEditing ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa tu apellido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Nacionalidad (Dropdown list of countries)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedNacionalidad,
                        dropdownColor: const Color(0xFF1E293B),
                        style: TextStyle(
                          color: canEditNacionalidad ? Colors.white : Colors.white54,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Nacionalidad (País)',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: Icon(
                            canEditNacionalidad ? Icons.flag_outlined : Icons.lock_outline,
                            color: canEditNacionalidad ? const Color(0xFF38BDF8) : Colors.white38,
                          ),
                          suffixIcon: !canEditNacionalidad
                              ? const Icon(Icons.lock_rounded, color: Colors.white38, size: 18)
                              : null,
                          filled: true,
                          fillColor: canEditNacionalidad ? const Color(0xFF0F172A) : const Color(0xFF0F172A).withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _paises.map((pais) {
                          return DropdownMenuItem<String>(
                            value: pais,
                            child: Text(pais),
                          );
                        }).toList(),
                        onChanged: canEditNacionalidad
                            ? (val) {
                                setState(() {
                                  _selectedNacionalidad = val;
                                });
                              }
                            : null,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Selecciona tu nacionalidad';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Teléfono (ALWAYS EDITABLE)
                      TextFormField(
                        controller: _telefonoController,
                        enabled: true,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Teléfono de Contacto',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF38BDF8)),
                          suffixIcon: isEditing
                              ? const Icon(Icons.edit_rounded, color: Color(0xFF38BDF8), size: 18)
                              : null,
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa tu número de teléfono';
                          }
                          if (value.trim().length < 7) {
                            return 'Ingresa un número telefónico válido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: userVM.isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: userVM.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            isEditing ? 'Guardar Cambios de Perfil' : 'Guardar Perfil Completo',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
