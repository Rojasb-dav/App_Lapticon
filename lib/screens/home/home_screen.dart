import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';
import '../../viewmodels/chat_viewmodel.dart';
import 'tabs/home_tab.dart';
import 'tabs/viajes_tab.dart';
import 'tabs/encomiendas_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [HomeTab(), ViajesTab(), EncomiendasTab()];
  final List<String> _titles = const [
    'Inicio - Lapticon',
    'Módulo de Viajes',
    'Módulo de Encomiendas',
  ];

  @override
  void initState() {
    super.initState();
    // Escuchar mis chats en tiempo real apenas entra al Home.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ChatViewModel>().escucharMisChats();
    });
  }

  void _abrirChat(ChatViewModel chatVM, String chatId, String nombre) {
    chatVM.marcarMatchVisto(chatId);
    context.push(AppRoutes.chat,
        extra: {'chatId': chatId, 'receiverName': nombre});
  }

  /// Aviso verde para el remitente cuando un viajero acepta su encomienda.
  Widget _bannerMatch(ChatViewModel chatVM) {
    final c = chatVM.matchesNuevos.first;
    final viajero = c.nombreViajero.isEmpty ? 'Un viajero' : c.nombreViajero;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF0D9488)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('¡Hiciste match!',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text(
                  '$viajero aceptó llevar tu encomienda'
                      '${c.ruta.isEmpty ? '' : ' (${c.ruta})'}.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF059669),
            ),
            onPressed: () =>
                _abrirChat(chatVM, c.chatId, c.nombreDelOtro(chatVM.miUid)),
            child: const Text('Abrir chat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatVM = context.watch<ChatViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: false,
        actions: [
          // 💬 Mis chats, con globito rojo si hay match o mensaje nuevo.
          IconButton(
            tooltip: 'Mis chats',
            onPressed: () => context.push(AppRoutes.misChats),
            icon: Badge(
              isLabelVisible: chatVM.pendientes > 0,
              label: Text('${chatVM.pendientes}'),
              child: const Icon(Icons.chat_bubble_rounded,
                  color: Color(0xFF38BDF8)),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi_rounded, size: 14, color: Color(0xFF38BDF8)),
                SizedBox(width: 4),
                Text('En vivo',
                    style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (chatVM.matchesNuevos.isNotEmpty) _bannerMatch(chatVM),
          Expanded(child: IndexedStack(index: _currentIndex, children: _tabs)),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF38BDF8),
          unselectedItemColor: Colors.white38,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                activeIcon: Icon(Icons.home_rounded, size: 28),
                label: 'Inicio'),
            BottomNavigationBarItem(
                icon: Icon(Icons.directions_bus_filled_rounded),
                activeIcon: Icon(Icons.directions_bus_filled_rounded, size: 28),
                label: 'Viajes'),
            BottomNavigationBarItem(
                icon: Icon(Icons.local_shipping_rounded),
                activeIcon: Icon(Icons.local_shipping_rounded, size: 28),
                label: 'Encomiendas'),
          ],
        ),
      ),
    );
  }
}
