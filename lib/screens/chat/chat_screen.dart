import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_model.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';

/// Pantalla de conversación entre remitente y viajero (tiempo real).
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverName;
  const ChatScreen(
      {super.key, required this.chatId, required this.receiverName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController();
  late final ChatViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<ChatViewModel>();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _vm.abrirChat(widget.chatId));
  }

  @override
  void dispose() {
    _vm.cerrarChat();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _textCtrl.text.trim();
    if (texto.isEmpty) return;
    _textCtrl.clear();
    final nombre =
        context.read<UserViewModel>().userProfile?.nombreCompleto ?? 'Usuario';
    final error = await _vm.enviarMensaje(
        chatId: widget.chatId, texto: texto, nombreRemitente: nombre);
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    final miUid = vm.miUid;
    // Lista invertida: el mensaje más nuevo queda abajo sin manejar scroll.
    final mensajes = vm.mensajes.reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName,
                style:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const Text('Chat de la encomienda',
                style: TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
      ),
      body: Column(
        children: [
          if (vm.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.redAccent.withValues(alpha: 0.2),
              child: Text(vm.error!,
                  style: const TextStyle(color: Colors.redAccent)),
            ),
          Expanded(
            child: vm.isLoading && mensajes.isEmpty
                ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                : mensajes.isEmpty
                ? const Center(
                child: Text('Aún no hay mensajes. ¡Saluda! 👋',
                    style: TextStyle(color: Colors.white54)))
                : ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: mensajes.length,
              itemBuilder: (_, i) => _Burbuja(
                mensaje: mensajes[i],
                esMio: mensajes[i].senderUid == miUid,
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      style: const TextStyle(color: Colors.white),
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _enviar(),
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF2563EB)]),
                    ),
                    child: IconButton(
                      onPressed: _enviar,
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Burbuja de mensaje: azul a la derecha (mío), gris a la izquierda (del otro).
class _Burbuja extends StatelessWidget {
  final ChatMessageModel mensaje;
  final bool esMio;
  const _Burbuja({required this.mensaje, required this.esMio});

  @override
  Widget build(BuildContext context) {
    final h = mensaje.timestamp;
    final hora =
        '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: esMio ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!esMio)
              Text(mensaje.senderName,
                  style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            Text(mensaje.text,
                style: const TextStyle(color: Colors.white, fontSize: 15)),
            const SizedBox(height: 2),
            Text(hora,
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
