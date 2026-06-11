import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/date_format.dart';

// Bottom sheet opened when the user taps an empty past day in the diary.
// Wraps a text field + date + time picker. Pops with a (text, day, time)
// record so the parent (HomeScreen) can run the normal parseMeal →
// ConfirmScreen flow with the chosen day + time.
//
// The date is editable IN the sheet so a user who tapped Donnerstag in
// the diary but actually meant Freitag doesn't have to back out and
// re-pick - they switch the day right here.
class PastDayInputSheet extends StatefulWidget {
  final TextEditingController controller;
  final DateTime day;
  const PastDayInputSheet(
      {super.key, required this.controller, required this.day});

  @override
  State<PastDayInputSheet> createState() => _PastDayInputSheetState();
}

class _PastDayInputSheetState extends State<PastDayInputSheet> {
  late DateTime _day;
  // Defaults to noon so the entry lands somewhere reasonable if the user
  // doesn't bother to set a time.
  TimeOfDay _time = const TimeOfDay(hour: 12, minute: 0);

  @override
  void initState() {
    super.initState();
    _day = widget.day;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: AppLocalizations.of(context).homeTimePickerHelp,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: AppLocalizations.of(context).homeDatePickerHelp,
    );
    if (picked != null) setState(() => _day = picked);
  }

  void _submit() {
    Navigator.of(context).pop(
      (text: widget.controller.text, day: _day, time: _time),
    );
  }

  String _formatTime(TimeOfDay t, String suffix) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}$suffix';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homePastDayHeader(formatDayHeader(context, _day)),
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                l10n.homePastDayBody,
                style: textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: widget.controller,
                autofocus: true,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: l10n.homePastDayInputHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Day pill: lets the user fix the case where they
                  // tapped Donnerstag in the diary but meant Freitag,
                  // without having to back out of the sheet and re-pick.
                  InkWell(
                    onTap: _pickDay,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 6),
                      child: Row(
                        children: [
                          Icon(Icons.event_outlined,
                              size: 18, color: scheme.outline),
                          const SizedBox(width: 8),
                          Text(
                            formatDayHeader(context, _day),
                            style: textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurface),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.edit_outlined,
                              size: 14, color: scheme.outline),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 6),
                      child: Row(
                        children: [
                          Icon(Icons.schedule_outlined,
                              size: 18, color: scheme.outline),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(_time, l10n.homeTimeSuffix),
                            style: textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurface),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.edit_outlined,
                              size: 14, color: scheme.outline),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(l10n.homeContinue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
