import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/lapticon_ui.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatViewModel>().cargarMensajes(widget.chatId).then((_) {
        _scrollToBottom();
      });
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _enviar() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    _msgCtrl.clear();
    final userVM = context.read<UserViewModel>();
    final authVM = context.read<AuthViewModel>();
    final senderName = userVM.userProfile?.nombreCompleto ??
        authVM.currentUser?.email?.split('@').first ??
        'Usuario';

    await context.read<ChatViewModel>().enviarMensaje(
      chatId: widget.chatId,
      texto: text,
      nombreRemitente: senderName,
    );

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatVM = context.watch<ChatViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final myUid = authVM.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF0284C7),
              child: Text(
                widget.receiverName.isNotEmpty ? widget.receiverName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Chat de Coordinación',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: lapticonFondo,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: chatVM.isLoading && chatVM.mensajes.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                    : chatVM.mensajes.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(30),
                              child: Text(
                                '¡Comienza la conversación para coordinar los detalles de entrega!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white60, fontSize: 14),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.all(16),
                            itemCount: chatVM.mensajes.length,
                            itemBuilder: (context, index) {
                              final msg = chatVM.mensajes[index];
                              final esMio = msg.senderUid == myUid;

                              return Align(
                                alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    color: esMio ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(esMio ? 16 : 4),
                                      bottomRight: Radius.circular(esMio ? 4 : 16),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      if (!esMio)
                                        Text(
                                          msg.senderName,
                                          style: const TextStyle(
                                            color: Color(0xFF38BDF8),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      Text(
                                        msg.text,
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),

              // Bottom Input Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _enviar(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF0284C7),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: _enviar,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
