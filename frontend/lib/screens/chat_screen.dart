import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../services/auth_provider.dart';
import '../theme.dart';
import '../widgets.dart';
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _sending = false;
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }
  Future<void> _loadHistory() async {
    try {
      final h = await context.read<AuthProvider>().api.chatHistory();
      if (mounted) setState(() => _messages.addAll(h));
      _scrollToEnd();
    } catch (_) {}
  }
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }
  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(ChatMessage('user', text));
      _sending = true;
      _input.clear();
    });
    _scrollToEnd();
    try {
      final reply = await context.read<AuthProvider>().api.chat(text);
      setState(() => _messages.add(ChatMessage('assistant', reply)));
    } catch (e) {
      setState(() => _messages.add(ChatMessage('assistant',
          'No pude responder ahora. Verifica tu conexión o la configuración de IA.')));
    } finally {
      setState(() => _sending = false);
      _scrollToEnd();
    }
  }
  @override
  Widget build(BuildContext context) {
    return PastelBackground(
      child: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 900,
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.lavender]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      GradientText('Asistente de salud',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      Text('Pregúntame sobre tus signos vitales',
                          style: TextStyle(
                              color: AppColors.inkSoft, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _messages.isEmpty
                  ? _intro()
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _bubble(_messages[i]),
                    ),
            ),
            if (_sending)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Escribiendo...',
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 12)),
              ),
            _composer(),
          ],
          ),
        ),
      ),
    );
  }
  Widget _intro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 56, color: AppColors.primary),
            SizedBox(height: 16),
            Text('Hola, soy tu asistente de salud',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            SizedBox(height: 8),
            Text(
              'Puedo ayudarte a entender tus mediciones y darte hábitos '
              'saludables. Recuerda: no sustituyo a un médico.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
  Widget _bubble(ChatMessage m) {
    final isUser = m.isUser;
    final sw = MediaQuery.of(context).size.width;
    final bubbleMax = sw > 760 ? 560.0 : sw * 0.78;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: bubbleMax),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: MarkdownText(
          m.content,
          color: isUser ? Colors.white : AppColors.ink,
        ),
      ),
    );
  }
  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: 'Escribe tu pregunta...',
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: _sending ? null : _send,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
            ),
            child: const Icon(Icons.send_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}