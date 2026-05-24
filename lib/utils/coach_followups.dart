// Splits a coach response into the visible body and an optional list of
// follow-up chip labels. The coach is instructed to append a section like
//   **Fragen:**
//   - I rarely eat fish
//   - I need on-the-go ideas
// (or **Follow-ups:** in English). We find the last occurrence of either
// marker, take everything below as bullet lines, and strip the marker plus
// items from the body so the bubble doesn't show them as plain markdown.

class CoachResponseSplit {
  final String body;
  final List<String> followUps;
  const CoachResponseSplit({required this.body, required this.followUps});
}

final _markerRegex = RegExp(
  r'^\s*\*\*(?:Follow-ups?|Fragen|Nachfragen):\*\*\s*$',
  multiLine: true,
  caseSensitive: false,
);

final _bulletRegex = RegExp(r'^\s*(?:[-*]|\d+\.)\s+(.+?)\s*$');

CoachResponseSplit splitCoachResponse(String raw) {
  final matches = _markerRegex.allMatches(raw).toList();
  if (matches.isEmpty) {
    return CoachResponseSplit(body: raw, followUps: const []);
  }
  final last = matches.last;
  final body = raw.substring(0, last.start).trimRight();
  final tail = raw.substring(last.end);
  final items = <String>[];
  for (final line in tail.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      if (items.isNotEmpty) break;
      continue;
    }
    final m = _bulletRegex.firstMatch(line);
    if (m == null) break;
    final label = m.group(1)!.trim();
    if (label.isNotEmpty) items.add(label);
  }
  return CoachResponseSplit(body: body, followUps: items);
}
