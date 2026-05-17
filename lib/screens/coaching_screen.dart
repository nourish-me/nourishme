import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/meal_providers.dart';
import '../services/claude_client.dart';

class CoachingScreen extends ConsumerStatefulWidget {
  const CoachingScreen({super.key});

  @override
  ConsumerState<CoachingScreen> createState() => _CoachingScreenState();
}

class _CoachingScreenState extends ConsumerState<CoachingScreen> {
  final List<ChatTurn> _messages = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _buildContext() {
    final today = ref.read(todayMealsProvider);
    final target = ref.read(calorieTargetProvider);
    final profile = ref.read(userProfileProvider).valueOrNull;
    final total = today.fold<int>(0, (s, m) => s + m.kcal);
    final remaining = target - total;
    final hour = DateTime.now().hour;
    final mealsLine = today.isEmpty
        ? 'Heute noch keine Einträge.'
        : today
            .map((m) =>
                '- ${m.summary} (${m.kcal} kcal${m.safetyWarnings.isEmpty ? '' : ', Warnung: ${m.safetyWarnings.join("; ")}'})')
            .join('\n');

    final buffer = StringBuffer();
    if (profile != null) {
      buffer.writeln(ClaudeClient.describeProfile(
          profile.numChildrenNursing, profile.milkSharePercent));
    }
    buffer
      ..writeln('Aktuelle Uhrzeit: $hour Uhr.')
      ..writeln(
          'Tagesziel: $target kcal. Bisher heute gegessen: $total kcal. Verbleibend: $remaining kcal.')
      ..writeln('Mahlzeiten heute:')
      ..writeln(mealsLine);
    return buffer.toString();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _messages.add(ChatTurn(isUser: true, text: text));
      _loading = true;
      _error = null;
    });
    _input.clear();
    _scrollToBottom();
    try {
      final reply = await ref.read(claudeClientProvider).chat(
            history: _messages,
            todayContext: _buildContext(),
          );
      if (!mounted) return;
      setState(() {
        _messages.add(ChatTurn(isUser: false, text: reply.trim()));
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Coaching'),
            Text(
              'Fragen und Tipps',
              style: textTheme.labelSmall?.copyWith(color: scheme.outline),
            ),
          ],
        ),
        centerTitle: false,
        toolbarHeight: 72,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && !_loading
                ? _CoachingEmptyState(scheme: scheme, textTheme: textTheme)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return _ChatBubble(message: _messages[i]);
                    },
                  ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Frage stellen...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _loading ? null : _send,
                    icon: const Icon(Icons.send),
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

class _CoachingEmptyState extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;
  const _CoachingEmptyState({required this.scheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 48, color: scheme.outline),
            const SizedBox(height: 12),
            Text(
              'Frag mich was',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Mahlzeitenideen, Sicherheits-Fragen, oder einfach was du gerade brauchst. Den Tagesüberblick findest du auf Heute.',
              style: textTheme.bodyMedium?.copyWith(color: scheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatTurn message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    final fg = isUser ? scheme.onPrimaryContainer : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: isUser
                ? Text(message.text, style: TextStyle(color: fg))
                : MarkdownBody(
                    data: message.text,
                    styleSheet:
                        MarkdownStyleSheet.fromTheme(Theme.of(context))
                            .copyWith(
                      p: TextStyle(color: fg, height: 1.35),
                      strong: TextStyle(color: fg, fontWeight: FontWeight.w700),
                      em: TextStyle(color: fg, fontStyle: FontStyle.italic),
                      listBullet: TextStyle(color: fg),
                      h1: TextStyle(
                          color: fg,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                      h2: TextStyle(
                          color: fg,
                          fontSize: 17,
                          fontWeight: FontWeight.w700),
                      h3: TextStyle(
                          color: fg,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                      blockSpacing: 6,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
