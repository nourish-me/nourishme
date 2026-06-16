/// Distinguishes the kinds of coach responses the app can render
/// (Task #88.5 - typed response handling).
///
/// `normal` is a regular LLM-generated reply. The other three short-
/// circuit the LLM call and carry a fixed canned response from the
/// safety layer:
/// - `emergency` from the input-classifier when an acute-risk keyword
///   matches (heavy bleeding, preterm labour, etc.). Renders with the
///   most prominent styling + tel:112 affordance (added separately).
/// - `escalation` from the input-classifier when a medical-handoff
///   keyword matches (medication, gestational diabetes, mastitis,
///   postpartum depression, etc.). Renders with a distinct
///   "consult midwife/doctor" framing.
/// - `blocked` from the output-post-check (Task #88.4) when the model
///   recommended a blocklist item; the response is the safe fallback.
///
/// Wire shape: the Worker sets `nourishme_response_type` on its
/// Anthropic-shaped JSON envelope, ClaudeClient parses it back to this
/// enum, ThreadItem persists it, CoachBubble switches styling on it.
enum CoachResponseType {
  normal,
  emergency,
  escalation,
  blocked;

  /// Lossy parse for the wire string. Unknown values fall back to
  /// `normal` so a future Worker that adds a new type doesn't crash
  /// an older client - it just won't get the specialised styling.
  static CoachResponseType fromWire(String? value) {
    switch (value) {
      case 'emergency':
        return CoachResponseType.emergency;
      case 'escalation':
        return CoachResponseType.escalation;
      case 'blocked':
        return CoachResponseType.blocked;
      default:
        return CoachResponseType.normal;
    }
  }

  String get wire => name;
}
