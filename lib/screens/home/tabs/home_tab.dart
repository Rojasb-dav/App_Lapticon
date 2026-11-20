import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../models/viaje_model.dart';
import '../../../models/encomienda_model.dart';
import '../../../models/chat_model.dart';
import '../../../router/app_router.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/user_viewmodel.dart';
import '../../../viewmodels/role_viewmodel.dart';
import '../../../viewmodels/viaje_viewmodel.dart';
import '../../../viewmodels/encomienda_viewmodel.dart';
import '../../../viewmodels/chat_viewmodel.dart';

/// Pestaña "Inicio".
/// Saludo + rol, banner con el lema, "pase de abordar" con el próximo viaje
/// (viajero) o la última encomienda (remitente), acción principal, contadores,
/// actividad reciente (chats de Firestore) y perfil plegable.
class HomeTab extends StatefulWidget {
  /// Permite saltar a otra pestaña del Home (1 = Viajes, 2 = Encomiendas).
  final ValueChanged<int>? onIrATab;
  const HomeTab({super.key, this.onIrATab});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  // Colores de la app
  static const _celeste = Color(0xFF38BDF8);
  static const _tarjeta = Color(0xFF1E293B);
  static const _naranja = Color(0xFFF59E0B);

  late final AnimationController _anim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
  late final Animation<double> _fade =
  CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  late final Animation<Offset> _slide =
  Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
      .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _anim.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  /// Carga viajes, encomiendas y empieza a escuchar los chats.
  Future<void> _cargar() async {
    if (!mounted) return;
    context.read<ChatViewModel>().escucharMisChats();
    final viajeVM = context.read<ViajeViewModel>();
    final encVM = context.read<EncomiendaViewModel>();
    await Future.wait([viajeVM.cargarMisViajes(), encVM.cargarMisEncomiendas()]);
  }

  void _irATab(int i) => widget.onIrATab?.call(i);

  void _abrirChat(ChatResumen c, String miUid) {
    if (c.soyRemitente(miUid) && !c.matchVisto) {
      context.read<ChatViewModel>().marcarMatchVisto(c.chatId);
    }
    context.push(AppRoutes.chat,
        extra: {'chatId': c.chatId, 'receiverName': c.nombreDelOtro(miUid)});
  }

  Future<void> _accionPrincipal(bool esViajero) async {
    final ok = await context
        .push<bool>(esViajero ? AppRoutes.registrarViaje : AppRoutes.crearEncomienda);
    if (ok == true && mounted) await _cargar();
  }

  Future<void> _cerrarSesion() async {
    final authVM = context.read<AuthViewModel>();
    final userVM = context.read<UserViewModel>();
    context.read<ChatViewModel>().detener();
    await authVM.signOut();
    userVM.clearProfile();
    if (mounted) context.go(AppRoutes.login);
  }

  // ---------------- Utilidades ----------------

  static String _norm(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');

  /// Código de aeropuerto para mostrar en el pase (BOG, MDE...).
  static String _iata(String ciudad) {
    final enParentesis = RegExp(r'\(([A-Z]{3})\)').firstMatch(ciudad);
    if (enParentesis != null) return enParentesis.group(1)!;
    const codigos = {
      'bogota': 'BOG',
      'medellin': 'MDE',
      'cali': 'CLO',
      'miami': 'MIA',
      'madrid': 'MAD',
      'cartagena': 'CTG',
      'barranquilla': 'BAQ',
    };
    final n = _norm(ciudad);
    for (final e in codigos.entries) {
      if (n.contains(e.key)) return e.value;
    }
    final limpio = ciudad.trim();
    return limpio.length >= 3 ? limpio.substring(0, 3).toUpperCase() : limpio.toUpperCase();
  }

  static String _fecha(DateTime? d) {
    if (d == null) return '—';
    const m = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  static String _fechaTexto(String f) => f.length > 10 ? f.substring(0, 10) : f;

  static String _hace(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'ahora';
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'hace ${d.inHours} h';
    return 'hace ${d.inDays} d';
  }

  /// El viaje con la fecha más cercana.
  static ViajeModel? _proximoViaje(List<ViajeModel> viajes) {
    if (viajes.isEmpty) return null;
    final lista = [...viajes]
      ..sort((a, b) => (a.fecha ?? DateTime(2100)).compareTo(b.fecha ?? DateTime(2100)));
    return lista.first;
  }

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserViewModel>().userProfile;
    final authVM = context.watch<AuthViewModel>();
    final roleVM = context.watch<RoleViewModel>();
    final viajeVM = context.watch<ViajeViewModel>();
    final encVM = context.watch<EncomiendaViewModel>();
    final chatVM = context.watch<ChatViewModel>();

    final miUid = chatVM.miUid;
    final esViajero = roleVM.esViajero;

    final nombre = user?.nombre.isNotEmpty == true
        ? user!.nombre
        : (authVM.currentUser?.email?.split('@').first ?? 'Usuario');
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

    // Datos para el pase y los contadores
    final aceptadas =
    chatVM.misChats.where((c) => c.soyRemitente(miUid) && c.tieneViajero).toList();
    final llevo = chatVM.misChats
        .where((c) => c.uidViajero == miUid && !c.soyRemitente(miUid))
        .toList();
    final idsAceptadas = aceptadas.map((c) => c.chatId).toSet();
    final buscando = encVM.misEncomiendas
        .where((e) => !idsAceptadas.contains(e.id) && !e.estaVencida)
        .toList();

    final pase = esViajero
        ? _paseViajero(viajeVM.viajes, llevo.length)
        : _paseRemitente(aceptadas, buscando, miUid);

    return RefreshIndicator(
      color: _celeste,
      onRefresh: _cargar,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _saludo(nombre, inicial, esViajero),
              const SizedBox(height: 18),
              _bannerLema(),
              const SizedBox(height: 22),
              _tituloSeccion(esViajero ? 'Tu próximo viaje' : 'Tu encomienda'),
              const SizedBox(height: 10),
              pase != null ? _PaseAbordar(pase: pase) : _tresPasos(esViajero),
              const SizedBox(height: 16),
              _botonPrincipal(esViajero),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _Contador(
                      icono: Icons.flight_takeoff_rounded,
                      color: _celeste,
                      valor: viajeVM.viajes.length,
                      texto: 'Viajes',
                      onTap: () => _irATab(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Contador(
                      icono: Icons.inventory_2_rounded,
                      color: _naranja,
                      valor: buscando.length + aceptadas.length,
                      texto: 'Encomiendas',
                      onTap: () => _irATab(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Contador(
                      icono: Icons.chat_bubble_rounded,
                      color: Colors.greenAccent,
                      valor: chatVM.misChats.length,
                      texto: 'Chats',
                      alerta: chatVM.pendientes,
                      onTap: () => context.push(AppRoutes.misChats),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _tituloSeccion('Actividad reciente'),
                  if (chatVM.misChats.isNotEmpty)
                    TextButton(
                      onPressed: () => context.push(AppRoutes.misChats),
                      child: const Text('Ver todos',
                          style: TextStyle(color: _celeste, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (chatVM.misChats.isEmpty)
                _vacio('Aún no tienes conversaciones. Cuando hagas match, aparecerán aquí.')
              else
                ...chatVM.misChats.take(3).map((c) => _ActividadTile(
                  chat: c,
                  miUid: miUid,
                  hace: _hace(c.actualizado),
                  onTap: () => _abrirChat(c, miUid),
                )),
              const SizedBox(height: 22),
              _perfil(user, authVM),
              const SizedBox(height: 22),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: const Text('Cerrar sesión',
                      style: TextStyle(
                          color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Secciones ----------------

  Widget _saludo(String nombre, String inicial, bool esViajero) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF4F46E5)]),
          ),
          child: Text(inicial,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¡Hola, $nombre! 👋',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.push(AppRoutes.roleSelection),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (esViajero ? _celeste : _naranja).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: (esViajero ? _celeste : _naranja).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(esViajero ? '✈️ Viajero' : '📦 Remitente',
                          style: TextStyle(
                              color: esViajero ? _celeste : _naranja,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Icon(Icons.swap_horiz_rounded,
                          size: 14, color: esViajero ? _celeste : _naranja),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bannerLema() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LAPTICON',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('Envía con viajeros,\nviaja ganando',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.2,
                        fontWeight: FontWeight.w900)),
                SizedBox(height: 8),
                Text(
                    'Conectamos a quienes envían paquetes con viajeros que van al mismo destino.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.connecting_airports_rounded,
                color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }

  _Pase? _paseViajero(List<ViajeModel> viajes, int encomiendasQueLlevo) {
    final v = _proximoViaje(viajes);
    if (v == null) return null;
    final enCurso = !['disponible', 'activo'].contains(v.estado.toLowerCase());
    return _Pase(
      etiqueta: 'PASE DE VIAJE',
      origen: v.origen,
      destino: v.destino,
      codigoOrigen: _iata(v.origen),
      codigoDestino: _iata(v.destino),
      estado: enCurso ? 'En curso' : 'Disponible',
      colorEstado: enCurso ? Colors.greenAccent : _celeste,
      detalles: [
        MapEntry('VUELO', v.numeroVuelo),
        MapEntry('FECHA', _fecha(v.fecha)),
        MapEntry('A BORDO', '$encomiendasQueLlevo enc.'),
      ],
      onTap: () => _irATab(1),
    );
  }

  _Pase? _paseRemitente(
      List<ChatResumen> aceptadas, List<EncomiendaModel> buscando, String miUid) {
    if (aceptadas.isNotEmpty) {
      final c = aceptadas.first;
      final partes = c.ruta.split('→');
      final origen = partes.first.trim();
      final destino = partes.length > 1 ? partes[1].trim() : '';
      return _Pase(
        etiqueta: 'GUÍA DE ENVÍO',
        origen: origen,
        destino: destino,
        codigoOrigen: _iata(origen),
        codigoDestino: destino.isEmpty ? '—' : _iata(destino),
        estado: 'Aceptada',
        colorEstado: Colors.greenAccent,
        detalles: [
          MapEntry('VIAJERO', c.nombreDelOtro(miUid)),
          MapEntry('CHAT', c.tieneMensajeNuevo(miUid) ? 'Mensaje nuevo' : 'Al día'),
          const MapEntry('ACCIÓN', 'Abrir chat'),
        ],
        onTap: () => _abrirChat(c, miUid),
      );
    }
    if (buscando.isNotEmpty) {
      final e = buscando.first;
      return _Pase(
        etiqueta: 'GUÍA DE ENVÍO',
        origen: e.origen,
        destino: e.destino,
        codigoOrigen: _iata(e.origen),
        codigoDestino: _iata(e.destino),
        estado: 'Buscando viajero',
        colorEstado: _naranja,
        detalles: [
          MapEntry('CONTENIDO', e.descripcion),
          MapEntry('PAGO', '\$${e.valorPagar.toStringAsFixed(0)}'),
          MapEntry('VENCE', _fechaTexto(e.fechaVencimiento)),
        ],
        onTap: () => _irATab(2),
      );
    }
    return null;
  }

  /// Se muestra cuando aún no hay viaje o encomienda.
  Widget _tresPasos(bool esViajero) {
    final pasos = esViajero
        ? const [
      (Icons.flight_takeoff_rounded, 'Registra tu viaje', 'Número de vuelo, fecha y ruta.'),
      (Icons.handshake_rounded, 'Haz match', 'Acepta encomiendas de tu misma ruta.'),
      (Icons.chat_rounded, 'Coordina y gana', 'Acuerda la entrega por chat.'),
    ]
        : const [
      (Icons.inventory_2_rounded, 'Publica tu encomienda', 'Ruta, contenido y valor a pagar.'),
      (Icons.handshake_rounded, 'Haz match', 'Un viajero de tu ruta la acepta.'),
      (Icons.chat_rounded, 'Coordina la entrega', 'Habla con el viajero por chat.'),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _tarjeta,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _celeste.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Empieza en 3 pasos',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          for (var i = 0; i < pasos.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _celeste.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text('${i + 1}',
                        style: const TextStyle(color: _celeste, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Icon(pasos[i].$1, color: Colors.white70, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pasos[i].$2,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600)),
                        Text(pasos[i].$3,
                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _botonPrincipal(bool esViajero) {
    final colores = esViajero
        ? const [Color(0xFF0284C7), Color(0xFF2563EB)]
        : const [Color(0xFFD97706), Color(0xFFF59E0B)];
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colores),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colores.first.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _accionPrincipal(esViajero),
        icon: Icon(esViajero ? Icons.add_rounded : Icons.add_box_rounded, color: Colors.white),
        label: Text(esViajero ? 'Registrar un viaje' : 'Publicar una encomienda',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _perfil(dynamic user, AuthViewModel authVM) {
    final email = (user?.email?.isNotEmpty == true)
        ? user!.email as String
        : (authVM.currentUser?.email ?? 'N/A');
    final telefono =
    (user?.telefono?.isNotEmpty == true) ? user!.telefono as String : 'Sin registrar';
    final nacionalidad = (user?.nacionalidad?.isNotEmpty == true)
        ? user!.nacionalidad as String
        : 'Sin registrar';
    final uid = authVM.currentUser?.uid ?? 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: _tarjeta,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          iconColor: _celeste,
          collapsedIconColor: Colors.white54,
          leading: const Icon(Icons.person_rounded, color: _celeste),
          title: const Text('Mis datos',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(email,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          children: [
            _filaDato(Icons.email_outlined, 'Correo', email),
            _filaDato(Icons.phone_outlined, 'Teléfono', telefono),
            _filaDato(Icons.flag_outlined, 'Nacionalidad', nacionalidad),
            Row(
              children: [
                Expanded(child: _filaDato(Icons.fingerprint_rounded, 'UID', uid)),
                IconButton(
                  tooltip: 'Copiar UID',
                  icon: const Icon(Icons.copy_rounded, color: _celeste, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: uid));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('UID copiado'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.completeProfile),
                icon: const Icon(Icons.edit_rounded, size: 16, color: _celeste),
                label: const Text('Editar perfil',
                    style: TextStyle(color: _celeste, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _celeste),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaDato(IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icono, color: _celeste, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                Text(valor,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tituloSeccion(String texto) => Text(texto,
      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold));

  Widget _vacio(String texto) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _tarjeta,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.forum_outlined, color: Colors.white38),
        const SizedBox(width: 12),
        Expanded(
            child: Text(texto,
                style: const TextStyle(color: Colors.white54, fontSize: 13))),
      ],
    ),
  );
}

// ======================= Widgets auxiliares =======================

/// Datos que muestra el pase de abordar.
class _Pase {
  final String etiqueta;
  final String origen;
  final String destino;
  final String codigoOrigen;
  final String codigoDestino;
  final String estado;
  final Color colorEstado;
  final List<MapEntry<String, String>> detalles;
  final VoidCallback onTap;

  const _Pase({
    required this.etiqueta,
    required this.origen,
    required this.destino,
    required this.codigoOrigen,
    required this.codigoDestino,
    required this.estado,
    required this.colorEstado,
    required this.detalles,
    required this.onTap,
  });
}

/// Tarjeta tipo "pase de abordar": BOG ✈ MDE + detalles.
class _PaseAbordar extends StatelessWidget {
  final _Pase pase;
  const _PaseAbordar({required this.pase});

  static const _celeste = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: pase.onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF172036)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _celeste.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              // Encabezado: etiqueta + estado
              Row(
                children: [
                  Text(pase.etiqueta,
                      style: const TextStyle(
                          color: _celeste,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: pase.colorEstado.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(pase.estado,
                        style: TextStyle(
                            color: pase.colorEstado,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Ruta: BOG ✈ MDE
              Row(
                children: [
                  _Ciudad(codigo: pase.codigoOrigen, nombre: pase.origen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        const Expanded(child: _LineaPunteada()),
                        Transform.rotate(
                          angle: 1.5708,
                          child: const Icon(Icons.flight_rounded, color: _celeste, size: 26),
                        ),
                        const Expanded(child: _LineaPunteada()),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _Ciudad(codigo: pase.codigoDestino, nombre: pase.destino, alFinal: true),
                ],
              ),
              const SizedBox(height: 16),
              const _LineaPunteada(),
              const SizedBox(height: 14),
              // Detalles
              Row(
                children: pase.detalles
                    .map((d) => Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.key,
                          style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text(d.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ciudad extends StatelessWidget {
  final String codigo;
  final String nombre;
  final bool alFinal;
  const _Ciudad({required this.codigo, required this.nombre, this.alFinal = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alFinal ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(codigo,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 1)),
        SizedBox(
          width: 90,
          child: Text(nombre,
              textAlign: alFinal ? TextAlign.end : TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ),
      ],
    );
  }
}

class _LineaPunteada extends StatelessWidget {
  const _LineaPunteada();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final n = (c.maxWidth / 9).floor().clamp(1, 200);
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
            n, (_) => Container(width: 4, height: 1.5, color: Colors.white24)),
      );
    });
  }
}

/// Contador con ícono (Viajes, Encomiendas, Chats).
class _Contador extends StatelessWidget {
  final IconData icono;
  final Color color;
  final int valor;
  final String texto;
  final int alerta;
  final VoidCallback onTap;
  const _Contador({
    required this.icono,
    required this.color,
    required this.valor,
    required this.texto,
    required this.onTap,
    this.alerta = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Badge(
                isLabelVisible: alerta > 0,
                label: Text('$alerta'),
                child: Icon(icono, color: color, size: 26),
              ),
              const SizedBox(height: 8),
              Text('$valor',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              Text(texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de actividad reciente (un chat).
class _ActividadTile extends StatelessWidget {
  final ChatResumen chat;
  final String miUid;
  final String hace;
  final VoidCallback onTap;
  const _ActividadTile(
      {required this.chat, required this.miUid, required this.hace, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nombre = chat.nombreDelOtro(miUid);
    final nuevo = chat.tieneMensajeNuevo(miUid) ||
        (chat.soyRemitente(miUid) && !chat.matchVisto);
    final detalle = chat.ultimoMensaje.isNotEmpty
        ? chat.ultimoMensaje
        : (chat.soyRemitente(miUid) ? '¡Aceptó tu encomienda!' : 'Aceptaste su encomienda');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF38BDF8),
            child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          title: Text(nombre,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(
            [if (chat.ruta.isNotEmpty) chat.ruta, detalle].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(hace, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 4),
              if (nuevo)
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                  const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
