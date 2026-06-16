import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

// Replaces the abstract 0-100 slider for "how much of your child's intake
// is your own milk" with 4 lived-scenario radios + a custom-value slider.
// Beta tester #82 reported the slider was hard to estimate; the scenarios
// describe the real Beikost-Übergang stages parents recognise from their
// own routine instead of asking them to put a number on it.
//
// Mapping: 100 -> only, 70 -> mostly, 50 -> half, 20 -> little.
// Any other value -> custom, slider is shown and the user picks freely.
// Existing profiles whose stored value happens to land on a preset get
// auto-selected on that preset; close-but-not-equal values fall through
// to custom (slider visible, value preserved) so we never silently shift.
//
// Multiples-only: when numChildren > 1, a fifth "per child" scenario is
// surfaced. Tapping it opens a modal with one slider per child and stores
// a List<int> on the profile via [onPerChildChanged]. The single
// [sharePercent] stays untouched so toggling back to a preset keeps the
// previous single value.
class MilkShareSelector extends StatefulWidget {
  final int sharePercent;
  final int numChildren;
  final ValueChanged<int> onChanged;
  // Active per-child share-list (multiples only). null/empty = single-mode.
  // Length should equal [numChildren] when non-null; the parent maintains
  // the length as numChildren changes.
  final List<int>? perChildShares;
  // Receives the new per-child list (length = numChildren, each 0..100),
  // or null when the user switches back to a single preset. Required when
  // numChildren > 1; ignored otherwise.
  final ValueChanged<List<int>?>? onPerChildChanged;
  // Optional InfoButton (the existing call sites pass an energy-fact
  // popover next to the section title - we keep it as the trailing slot
  // so the layout doesn't lose that affordance).
  final Widget? trailing;
  // Optional title override; defaults to the question "Was bekommt dein
  // Kind?" / "What does your child get?".
  final String? title;

  const MilkShareSelector({
    super.key,
    required this.sharePercent,
    required this.numChildren,
    required this.onChanged,
    this.perChildShares,
    this.onPerChildChanged,
    this.trailing,
    this.title,
  });

  @override
  State<MilkShareSelector> createState() => _MilkShareSelectorState();
}

// Preset values shared between the build method and the initial-locked
// inference in initState (file-level const so the initState can avoid
// touching widget-tree state).
const _kPresetShareValues = {100, 70, 50, 20};

class _MilkShareSelectorState extends State<MilkShareSelector> {
  // True once the user has explicitly picked the "Custom" tile. Stays true
  // even when the slider lands on a preset value (100/70/50/20) so the
  // slider doesn't visually snap back to a preset row mid-drag. Cleared
  // when the user taps any preset or "per child" option.
  //
  // Vanessa's Build+25 feedback: "lässt sich verschieben, springt aber
  // sofort auf eine der optionen um nach verschieben" - the slider's
  // 5-step divisions hit preset values, which then auto-selected the
  // matching preset row and hid the slider. This lock makes the user's
  // intent ("I want to set a value myself") the source of truth.
  late bool _customLocked;

  @override
  void initState() {
    super.initState();
    // Seed the lock from the initial value: a stored non-preset value
    // means the user was already in custom-mode last time.
    _customLocked = !_kPresetShareValues.contains(widget.sharePercent) &&
        (widget.perChildShares == null || widget.perChildShares!.isEmpty);
  }

  bool get _isPerChildMode {
    final list = widget.perChildShares;
    return list != null && list.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final scenarios = <_Scenario>[
      _Scenario(
          value: 100,
          label: l10n.settingsMilkShareScenarioOnly,
          hint: l10n.settingsMilkShareScenarioOnlyHint),
      _Scenario(
          value: 70,
          label: l10n.settingsMilkShareScenarioMostly,
          hint: l10n.settingsMilkShareScenarioMostlyHint),
      _Scenario(
          value: 50,
          label: l10n.settingsMilkShareScenarioHalf,
          hint: l10n.settingsMilkShareScenarioHalfHint),
      _Scenario(
          value: 20,
          label: l10n.settingsMilkShareScenarioLittle,
          hint: l10n.settingsMilkShareScenarioLittleHint),
    ];

    final presetValues = scenarios.map((s) => s.value).toSet();
    final isPerChild = _isPerChildMode;
    // Custom mode is active when either (a) the user explicitly tapped
    // Custom (_customLocked), OR (b) the stored value isn't a preset
    // anyway (legacy non-preset value). Per-child mode wins over both.
    final isCustom = !isPerChild &&
        (_customLocked || !presetValues.contains(widget.sharePercent));
    final showPerChildOption =
        widget.numChildren > 1 && widget.onPerChildChanged != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title ?? l10n.settingsMilkShareQuestion,
                style: textTheme.titleSmall,
              ),
            ),
            ?widget.trailing,
          ],
        ),
        if (widget.numChildren > 1) ...[
          const SizedBox(height: 4),
          Text(
            l10n.settingsMilkShareMultipleChildrenHint,
            style: textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
        ],
        const SizedBox(height: 8),
        for (final s in scenarios)
          _ScenarioTile(
            label: s.label,
            hint: s.hint,
            selected: !isPerChild && !isCustom && widget.sharePercent == s.value,
            onTap: () {
              // Tapping a preset commits to single-mode + clears any per-
              // child override + releases the custom lock.
              if (isPerChild) widget.onPerChildChanged?.call(null);
              setState(() => _customLocked = false);
              widget.onChanged(s.value);
            },
          ),
        _ScenarioTile(
          label: l10n.settingsMilkShareScenarioCustom,
          hint: null,
          selected: isCustom,
          onTap: () {
            if (isCustom) return;
            if (isPerChild) widget.onPerChildChanged?.call(null);
            // Lock custom mode FIRST so the slider stays visible even if
            // the (unchanged) value happens to be a preset.
            setState(() => _customLocked = true);
            widget.onChanged(widget.sharePercent);
          },
        ),
        if (showPerChildOption)
          _ScenarioTile(
            label: l10n.settingsMilkSharePerChildScenario,
            hint: l10n.settingsMilkSharePerChildScenarioHint,
            selected: isPerChild,
            onTap: () async {
              final initial = isPerChild
                  ? List<int>.from(widget.perChildShares!)
                  : List<int>.filled(widget.numChildren, widget.sharePercent);
              // Pad/truncate when the parent changed numChildren since the
              // last save so the modal always has exactly N rows.
              final padded = List<int>.generate(
                  widget.numChildren,
                  (i) =>
                      i < initial.length ? initial[i] : widget.sharePercent);
              final result = await showModalBottomSheet<List<int>>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                showDragHandle: true,
                builder: (_) => _PerChildSharesSheet(initial: padded),
              );
              if (result != null) {
                setState(() => _customLocked = false);
                widget.onPerChildChanged?.call(result);
              }
            },
          ),
        if (isCustom) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              widget.numChildren <= 1
                  ? l10n.settingsMilkShareSingular(widget.sharePercent)
                  : l10n.settingsMilkSharePlural(widget.sharePercent),
              style: textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
          ),
          Slider(
            value: widget.sharePercent.toDouble().clamp(0, 100),
            min: 0,
            max: 100,
            divisions: 100,
            label: '${widget.sharePercent}%',
            onChanged: (v) => widget.onChanged(v.round()),
          ),
        ],
        if (isPerChild) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _perChildSummary(widget.perChildShares!, l10n),
              style: textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
          ),
        ],
      ],
    );
  }

  static String _perChildSummary(List<int> shares, AppLocalizations l10n) {
    final parts = <String>[];
    for (var i = 0; i < shares.length; i++) {
      parts.add(l10n.settingsMilkSharePerChildSummaryEntry(i + 1, shares[i]));
    }
    final avg = (shares.fold<int>(0, (a, b) => a + b) / shares.length).round();
    return '${parts.join(' · ')}  ·  Ø $avg%';
  }
}

class _Scenario {
  final int value;
  final String label;
  final String hint;
  const _Scenario({
    required this.value,
    required this.label,
    required this.hint,
  });
}

class _ScenarioTile extends StatelessWidget {
  final String label;
  final String? hint;
  final bool selected;
  final VoidCallback onTap;

  const _ScenarioTile({
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final borderColor = selected ? scheme.primary : scheme.outlineVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.30)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor,
                width: selected ? 1.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? scheme.primary : scheme.outline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (hint != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          hint!,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Bottom sheet that lets the user set a separate share% per child for the
// multiples case ("Carl bekommt 100% deine Milch, Leo halb-halb"). Returns
// the full list on Save; null on dismiss.
class _PerChildSharesSheet extends StatefulWidget {
  final List<int> initial;
  const _PerChildSharesSheet({required this.initial});

  @override
  State<_PerChildSharesSheet> createState() => _PerChildSharesSheetState();
}

class _PerChildSharesSheetState extends State<_PerChildSharesSheet> {
  late List<int> _values;

  @override
  void initState() {
    super.initState();
    _values = List<int>.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.settingsMilkSharePerChildSheetTitle,
            style: textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.settingsMilkSharePerChildSheetHint,
            style: textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _values.length; i++) ...[
            Row(
              children: [
                Text(
                  l10n.settingsMilkSharePerChildLabel(i + 1),
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text('${_values[i]}%',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
            Slider(
              value: _values[i].toDouble().clamp(0, 100),
              min: 0,
              max: 100,
              divisions: 20,
              label: '${_values[i]}%',
              onChanged: (v) =>
                  setState(() => _values[i] = v.round()),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.commonCancel),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(List<int>.from(_values)),
                child: Text(l10n.settingsButtonSave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
