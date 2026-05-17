import 'package:flutter/material.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInsights());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _buildContext({bool includeYesterday = false}) {
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

    if (includeYesterday) {
      final yesterday = ref.read(yesterdayMealsProvider);
      final yTotal = yesterday.fold<int>(0, (s, m) => s + m.kcal);
      final yLine = yesterday.isEmpty
          ? 'Gestern keine Einträge erfasst.'
          : yesterday
              .map((m) => '- ${m.summary} (${m.kcal} kcal)')
              .join('\n');
      buffer
        ..writeln()
        ..writeln('Mahlzeiten gestern (Gesamt: $yTotal kcal von $target kcal):')
        ..writeln(yLine);
    }

    return buffer.toString();
  }

  Future<void> _loadInsights() async {
    setState(() => _loading = true);

    final repo = ref.read(settingsRepositoryProvider);
    final lastOpen = repo.getLastCoachingOpenDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstOpenToday = lastOpen == null || lastOpen.isBefore(today);
    final yesterday = ref.read(yesterdayMealsProvider);
    final showYesterday = firstOpenToday && yesterday.isNotEmpty;

    final initialPrompt = showYesterday
        ? '''
Strukturiere deine Antwort in vier kurzen Abschnitten:
1. Tagesabschluss von gestern: kurzer Rückblick auf gestrige Kalorien gegen Ziel und Auffälligkeiten.
2. Spiegle mir, was ich heute schon gegessen habe.
3. Sag mir, was jetzt für den Rest des Tages noch fehlt.
4. Schließe mit 1-2 konkreten Empfehlungen ab.
'''
        : '''
Strukturiere deine Antwort in drei kurzen Abschnitten:
1. Spiegle mir kurz, was ich heute schon gegessen habe.
2. Sag mir, was jetzt für den Rest des Tages noch fehlt (Kalorien, Protein, Wasser, etc.).
3. Schließe mit 1-2 konkreten Empfehlungen ab.
''';

    _messages.add(ChatTurn(isUser: true, text: initialPrompt));
    try {
      final reply = await ref.read(claudeClientProvider).chat(
            history: _messages,
            todayContext: _buildContext(includeYesterday: showYesterday),
          );
      if (!mounted) return;
      setState(() {
        _messages.add(ChatTurn(isUser: false, text: reply.trim()));
        _loading = false;
      });
      _scrollToBottom();
      await repo.setLastCoachingOpenDate(today);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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
    final visible = _messages.where((m) => !(m.isUser && _messages.indexOf(m) == 0)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Coaching'),
            Text(
              'Fragen und Tipps',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
        centerTitle: false,
        toolbarHeight: 72,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: visible.length + (_loading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == visible.length) {
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
                final msg = visible[i];
                return _ChatBubble(message: msg);
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

class _ChatBubble extends StatelessWidget {
  final ChatTurn message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;
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
              color: isUser ? scheme.primaryContainer : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isUser ? scheme.onPrimaryContainer : scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
