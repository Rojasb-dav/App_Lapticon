import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';
import '../../viewmodels/chat_viewmodel.dart';

/// Lista de todos mis chats, como remitente o como viajero.
class MisChatsScreen extends StatelessWidget {
  const MisChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    final uid = vm.miUid;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text('Mis chats',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: vm.misChats.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Todavía no tienes chats.\nAparecen cuando un viajero acepta tu encomienda o cuando tú aceptas una.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: vm.misChats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final c = vm.misChats[i];
          final nombre = c.nombreDelOtro(uid);
          final nuevoMatch =
              c.soyRemitente(uid) && c.tieneViajero && !c.matchVisto;
          final nuevo = nuevoMatch || c.tieneMensajeNuevo(uid);
          return Material(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF38BDF8),
                child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(nombre,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(
                [
                  if (c.ruta.isNotEmpty) c.ruta,
                  c.soyRemitente(uid) ? 'Eres remitente' : 'Eres viajero',
                  if (c.ultimoMensaje.isNotEmpty) c.ultimoMensaje,
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60),
              ),
              trailing: nuevo
                  ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(nuevoMatch ? 'Nuevo match' : 'Nuevo',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11)),
              )
                  : const Icon(Icons.chevron_right, color: Colors.white38),
              onTap: () {
                if (nuevoMatch) vm.marcarMatchVisto(c.chatId);
                context.push(AppRoutes.chat,
                    extra: {'chatId': c.chatId, 'receiverName': nombre});
              },
            ),
          );
        },
      ),
    );
  }
}
