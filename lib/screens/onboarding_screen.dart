import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart' as intl;

import '../models/user_profile_settings.dart';
import '../models/weight_entry.dart';
import '../providers/meal_providers.dart';
import '../providers/ui_providers.dart';
import '../services/calorie_target.dart';
import '../l10n/app_localizations.dart';
import '../models/reminder_settings.dart';
import '../services/nutrition_facts.dart';
import '../services/notification_scheduler.dart';
import '../utils/number_format.dart';
import '../utils/profile_labels.dart';
import '../widgets/child_age_input.dart';
import '../widgets/info_button.dart';
import '../widgets/nm_icons.dart';
import '../widgets/supplement_setup.dart';
import 'main_scaffold.dart';

// First-launch setup. Five steps with a thin progress bar at the top. Each
// step explains why we ask for the data via ⓘ-bottom-sheets so the user
// understands the scientific basis. Saves the profile at the end and routes
// to the main scaffold.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // Stable, language-independent names for funnel analytics. Index matches
  // the order of the PageView children in build().
  static const _stepNames = [
    'welcome',
    'phase',
    'goal',
    'body',
    'phase_details',
    'supplement',
    'summary',
  ];

  // Step indices we branch on. Keeping these in one place keeps the
  // skip branching readable when the step list grows.
  static const _phaseDetailsStepIndex = 4;
  static const _supplementStepIndex = 5;
  static const _summaryStepIndex = 6;

  final _controller = PageController();
  int _step = 0;

  // Phase
  bool _isPregnant = false;
  bool _isLactating = true;
  // Becomes true the moment the user actively picks "neither" on the
  // phase step. Lets us treat "both toggles off" as a valid choice the
  // user really made, distinct from "user hasn't answered yet".
  bool _phaseExplicitlyNeither = false;
  // Coach focus chosen during onboarding. Defaults to nutrients so a user
  // who just taps through gets the safer no-deficit-talk coach.
  String _goal = CoachGoal.nutrients;
  // Supplements captured during onboarding via Vision-parse. Empty list
  // when the user skipped the step.
  List<ActiveSupplement> _supplements = const [];
  int _trimester = 1;

  // Body fields are pre-filled with neutral defaults so the user can advance
  // straight away. Birthdate defaults to 30 years ago (matching old age=30
  // default) and is editable via date picker.
  DateTime _birthdate =
      DateTime(DateTime.now().year - 30, DateTime.now().month, DateTime.now().day);
  late final TextEditingController _height = TextEditingController(text: '165');
  late final TextEditingController _weight = TextEditingController(text: '65');
  double _activityFactor = 1.375;

  // Lactation
  int _numChildren = 1;
  int _childAgeGroup = 0;
  // Optional youngest-child birth date. When set, _childAgeGroup is
  // re-derived from it instead of hand-picked.
  DateTime? _youngestChildBirthdate;
  int _milkSharePercent = 100;
  // Meal-reminder opt-in on the final summary step. Defaults to true so most
  // users land in the app with reminders set up; if iOS denies the system
  // permission we honestly flip the persisted master flag back to off.
  bool _remindersOptIn = true;
  int _dailyVolumeMl =
      UserProfileSettings.estimatedDailyVolumeMl(
          numChildren: 1, ageGroup: 0, sharePercent: 100);

  @override
  void initState() {
    super.initState();
    // Top of the activation funnel. Pairs with onboarding_completed so we can
    // measure drop-off between first launch and finishing setup.
    ref.read(analyticsServiceProvider).capture('onboarding_started');
    _trackStepView();
  }

  // Per-step funnel telemetry. Fires when a step becomes visible (initial
  // load, _next, _restart). Back navigation does not re-fire so the funnel
  // stays a clean forward sequence.
  void _trackStepView() {
    ref.read(analyticsServiceProvider).capture(
      'onboarding_step_view',
      properties: {
        'step_index': _step,
        'step_name': _stepNames[_step],
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  int get _totalSteps => 7;

  bool get _canAdvance {
    switch (_step) {
      case 1:
        // Phase: at least one of pregnant/lactating/neither must be picked.
        return _isPregnant || _isLactating || _phaseExplicitlyNeither;
      case 2:
        // Goal: any of nutrients/body/both is valid; default 'nutrients'
        // so the user can keep tapping through without forced choice.
        return true;
      case 3:
        // Body: birthdate is pre-filled, height/weight defaults exist.
        return double.tryParse(_height.text.replaceAll(',', '.')) != null &&
            double.tryParse(_weight.text.replaceAll(',', '.')) != null;
      case _summaryStepIndex:
        // Summary step: disclaimer is shown as plain text (no longer gated
        // by a checkbox - that confused more users than it protected).
        // Tapping "Los geht's" still records the acceptance timestamp in
        // _finish so we have an audit trail.
        return true;
      default:
        return true;
    }
  }

  static int _ageFromBirthdate(DateTime b) {
    final now = DateTime.now();
    var age = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) {
      age--;
    }
    return age;
  }

  // Step 3 (_PhaseDetailsStep) is empty when the user picked "neither" on
  // the phase step - no trimester, no nursing-volume sliders to fill in.
  // We skip over it in both directions so the user doesn't have to tap
  // through a blank page.
  bool get _skipPhaseDetails =>
      !_isPregnant && !_isLactating && _phaseExplicitlyNeither;

  void _next() {
    if (_step < _totalSteps - 1) {
      var target = _step + 1;
      // PhaseDetails + Supplement are both skipped for the "neither" phase
      // (no nursing context to configure, no supplements relevant when
      // there's no baby).
      while ((target == _phaseDetailsStepIndex && _skipPhaseDetails) ||
          (target == _supplementStepIndex && _skipPhaseDetails)) {
        target += 1;
      }
      setState(() => _step = target);
      _trackStepView();
      _controller.animateToPage(
        _step,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step == 0) return;
    var target = _step - 1;
    while ((target == _phaseDetailsStepIndex && _skipPhaseDetails) ||
        (target == _supplementStepIndex && _skipPhaseDetails)) {
      target -= 1;
    }
    setState(() => _step = target);
    _controller.animateToPage(
      _step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _restart() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.onboardingRestartTitle),
        content: Text(l10n.onboardingRestartBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.onboardingRestartConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _step = 0;
      _isPregnant = false;
      _isLactating = true;
      _phaseExplicitlyNeither = false;
      _goal = CoachGoal.nutrients;
      _supplements = const [];
      _trimester = 1;
      _birthdate = DateTime(
          DateTime.now().year - 30, DateTime.now().month, DateTime.now().day);
      _height.clear();
      _weight.clear();
      _activityFactor = 1.375;
      _numChildren = 1;
      _childAgeGroup = 0;
      _youngestChildBirthdate = null;
      _milkSharePercent = 100;
      _dailyVolumeMl = UserProfileSettings.estimatedDailyVolumeMl(
        numChildren: 1,
        ageGroup: 0,
        sharePercent: 100,
      );
    });
    _controller.jumpToPage(0);
    _trackStepView();
  }

  Future<void> _pickYoungestChildBirthdate() async {
    final now = DateTime.now();
    final initial = _youngestChildBirthdate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      helpText: AppLocalizations.of(context).settingsMilkBirthdatePickerHelp,
    );
    if (picked != null) {
      setState(() {
        _youngestChildBirthdate = picked;
        final months = (now.year - picked.year) * 12 +
            (now.month - picked.month) -
            (now.day < picked.day ? 1 : 0);
        _childAgeGroup = months < 6 ? 0 : (months < 12 ? 1 : 2);
        _dailyVolumeMl = UserProfileSettings.estimatedDailyVolumeMl(
          numChildren: _numChildren,
          ageGroup: _childAgeGroup,
          sharePercent: _milkSharePercent,
        );
      });
    }
  }

  UserProfileSettings _buildProfile() => UserProfileSettings(
        ageYears: _ageFromBirthdate(_birthdate),
        birthdate: _birthdate,
        heightCm:
            double.tryParse(_height.text.replaceAll(',', '.')) ?? 167,
        weightKg:
            double.tryParse(_weight.text.replaceAll(',', '.')) ?? 56,
        activityFactor: _activityFactor,
        isPregnant: _isPregnant,
        trimester: _isPregnant ? _trimester : null,
        numChildrenNursing: _isLactating ? _numChildren : 0,
        milkSharePercent: _milkSharePercent,
        childrenAgeGroup: _childAgeGroup,
        youngestChildBirthdate: _youngestChildBirthdate,
        dailyMilkVolumeMl: _isLactating ? _dailyVolumeMl : 0,
        milkSupplementKcal: 0, // derived from volume
        goal: _goal,
        activeSupplements: List<ActiveSupplement>.from(_supplements),
      );

  Future<void> _finish() async {
    final profile = _buildProfile();
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.saveProfile(profile);
    // Persist the disclaimer acceptance with the actual tap-through time.
    // The CTA guard (_canAdvance case 4) means this can only fire after the
    // user has explicitly ticked the checkbox.
    await settingsRepo.setDisclaimerAcceptedAt(DateTime.now());
    // Seed the weight history with the onboarding value so the Trends-tab
    // chart has a starting point. Subsequent edits in Settings append.
    await ref.read(weightRepositoryProvider).save(WeightEntry(
          id: 'w-${DateTime.now().microsecondsSinceEpoch}',
          weightKg: profile.weightKg,
          recordedAt: DateTime.now(),
        ));
    ref.read(analyticsServiceProvider).capture('onboarding_completed');
    ref.read(analyticsServiceProvider).capture('weight_logged',
        properties: {'source': 'onboarding'});
    ref.invalidate(userProfileProvider);

    // If the user kept the meal-reminders opt-in on, request iOS permission
    // now (in onboarding context, so it doesn't feel like an ambush later)
    // and persist the final state honestly: enabled only if the system
    // actually granted. Either way the slot defaults are saved so the
    // Settings → Erinnerungen UI can toggle them back on without rebuild.
    var reminders = ReminderSettings.defaults;
    if (_remindersOptIn) {
      final granted = await NotificationScheduler.requestPermissions();
      reminders = reminders.copyWith(masterEnabled: granted);
    }
    await settingsRepo.saveReminders(reminders);
    if (!mounted) return;
    await NotificationScheduler.rescheduleFor(
        reminders, AppLocalizations.of(context));

    if (!mounted) return;
    // First-launch UX: after onboarding the user has just told us their
    // entire setup, so the next step is almost always logging their first
    // meal. Bump the focus signal so the home input pulls focus once
    // MainScaffold renders.
    ref.read(mealInputFocusRequestProvider.notifier).state++;
    // Always land on the Diary tab after onboarding. The tab index is
    // in-memory Riverpod state that survives an app reset, so without this a
    // reset + re-onboarding would reopen whatever tab was last active.
    ref.read(selectedTabProvider.notifier).state = 0;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScaffold()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _ProgressHeader(
                step: _step,
                total: _totalSteps,
                onBack: _step > 0 ? _back : null,
                onRestart: _restart,
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _WelcomeStep(scheme: scheme),
                    _PhaseStep(
                      isPregnant: _isPregnant,
                      isLactating: _isLactating,
                      isNeither: _phaseExplicitlyNeither &&
                          !_isPregnant &&
                          !_isLactating,
                      onChange: (preg, lact) => setState(() {
                        _isPregnant = preg;
                        _isLactating = lact;
                        // Any active toggle invalidates the "neither" pick.
                        if (preg || lact) _phaseExplicitlyNeither = false;
                      }),
                      onPickNeither: () => setState(() {
                        _isPregnant = false;
                        _isLactating = false;
                        _phaseExplicitlyNeither = true;
                      }),
                    ),
                    _GoalStep(
                      goal: _goal,
                      onChanged: (v) => setState(() => _goal = v),
                    ),
                    _BodyStep(
                      birthdate: _birthdate,
                      onBirthdateChanged: (d) =>
                          setState(() => _birthdate = d),
                      height: _height,
                      weight: _weight,
                      activityFactor: _activityFactor,
                      onActivityChanged: (v) =>
                          setState(() => _activityFactor = v),
                    ),
                    _PhaseDetailsStep(
                      isPregnant: _isPregnant,
                      isLactating: _isLactating,
                      trimester: _trimester,
                      onTrimesterChanged: (v) =>
                          setState(() => _trimester = v),
                      numChildren: _numChildren,
                      onChildrenChanged: (v) {
                        setState(() {
                          _numChildren = v;
                          _dailyVolumeMl =
                              UserProfileSettings.estimatedDailyVolumeMl(
                            numChildren: v,
                            ageGroup: _childAgeGroup,
                            sharePercent: _milkSharePercent,
                          );
                        });
                      },
                      childAgeGroup: _childAgeGroup,
                      onAgeGroupChanged: (v) {
                        setState(() {
                          _childAgeGroup = v;
                          _dailyVolumeMl =
                              UserProfileSettings.estimatedDailyVolumeMl(
                            numChildren: _numChildren,
                            ageGroup: v,
                            sharePercent: _milkSharePercent,
                          );
                        });
                      },
                      youngestChildBirthdate: _youngestChildBirthdate,
                      onPickBirthdate: _pickYoungestChildBirthdate,
                      onClearBirthdate: () =>
                          setState(() => _youngestChildBirthdate = null),
                      milkSharePercent: _milkSharePercent,
                      onSharePercentChanged: (v) {
                        setState(() {
                          _milkSharePercent = v;
                          _dailyVolumeMl =
                              UserProfileSettings.estimatedDailyVolumeMl(
                            numChildren: _numChildren,
                            ageGroup: _childAgeGroup,
                            sharePercent: v,
                          );
                        });
                      },
                      dailyVolumeMl: _dailyVolumeMl,
                      onVolumeChanged: (v) =>
                          setState(() => _dailyVolumeMl = v),
                    ),
                    _SupplementStep(
                      supplements: _supplements,
                      onAdd: () async {
                        final result =
                            await runSupplementSetup(context, ref);
                        if (result != null && mounted) {
                          setState(() =>
                              _supplements = [..._supplements, result]);
                        }
                      },
                      onEdit: (index, edited) =>
                          setState(() => _supplements = [
                                for (var i = 0; i < _supplements.length; i++)
                                  if (i == index) edited else _supplements[i],
                              ]),
                      onRemove: (index) =>
                          setState(() => _supplements = [
                                for (var i = 0; i < _supplements.length; i++)
                                  if (i != index) _supplements[i],
                              ]),
                      onSkip: _next,
                    ),
                    _SummaryStep(
                      profile: _buildProfile(),
                      remindersOptIn: _remindersOptIn,
                      onRemindersToggled: (v) =>
                          setState(() => _remindersOptIn = v),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_step == _totalSteps - 1) ...[
                        Text(
                          AppLocalizations.of(context)
                              .onboardingFooterEditLater,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.outline,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                      ],
                      FilledButton(
                        onPressed: _canAdvance ? _next : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          _step < _totalSteps - 1
                              ? AppLocalizations.of(context).onboardingButtonNext
                              : AppLocalizations.of(context).onboardingButtonStart,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int step;
  final int total;
  final VoidCallback? onBack;
  final VoidCallback onRestart;
  const _ProgressHeader({
    required this.step,
    required this.total,
    required this.onBack,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              // Keep a 48-px slot so the progress dots stay centered even
              // on the first step where the back button isn't shown.
              if (onBack != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)
                        .onboardingStepIndicator(step + 1, total),
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.outline,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: AppLocalizations.of(context).onboardingRestartTooltip,
                onPressed: onRestart,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Pill-style step dots: current step is a wide pine pill, others are
          // small dots in the rule color. Direct visual translation of the
          // TestFlight 1.1 spec.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == step ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == step ? scheme.primary : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final ColorScheme scheme;
  const _WelcomeStep({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        Center(
          child: SvgPicture.asset(
            'assets/logo/bowl-mark.svg',
            width: 120,
            height: 120,
          ),
        ),
        const SizedBox(height: 24),
        // Wordmark: "NourishMe." in editorial italic with the amber dot.
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: textTheme.displaySmall?.copyWith(
                color: scheme.onSurface,
                fontSize: 40,
              ),
              children: [
                const TextSpan(text: 'Nourish'),
                TextSpan(
                  text: 'Me',
                  style: TextStyle(color: scheme.primary),
                ),
                TextSpan(
                  text: '.',
                  style: TextStyle(color: scheme.secondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              AppLocalizations.of(context).onboardingTagline,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 22,
                height: 1.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              AppLocalizations.of(context).onboardingSubline,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhaseStep extends StatelessWidget {
  final bool isPregnant;
  final bool isLactating;
  final bool isNeither;
  final void Function(bool pregnant, bool lactating) onChange;
  final VoidCallback onPickNeither;
  const _PhaseStep({
    required this.isPregnant,
    required this.isLactating,
    required this.isNeither,
    required this.onChange,
    required this.onPickNeither,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.onboardingPhaseQuestion,
              style: textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingPhaseExplainer,
            style: textTheme.bodyMedium?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 24),
          _PhaseChoice(
            label: l10n.onboardingPhaseLactation,
            description: l10n.onboardingPhaseLactationHint,
            selected: isLactating,
            onTap: () => onChange(isPregnant, !isLactating),
            fact: energyLactationFact(l10n),
            leading: NMIcons.nursing(size: 28),
          ),
          const SizedBox(height: 12),
          _PhaseChoice(
            label: l10n.onboardingPhasePregnancy,
            description: l10n.onboardingPhasePregnancyHint,
            selected: isPregnant,
            onTap: () => onChange(!isPregnant, isLactating),
            fact: energyPregnancyFact(l10n),
            leading: NMIcons.pregnancy(size: 28),
          ),
          const SizedBox(height: 12),
          _PhaseChoice(
            label: l10n.onboardingPhaseNeither,
            description: l10n.onboardingPhaseNeitherHint,
            selected: isNeither,
            onTap: onPickNeither,
            fact: null,
            leading: const Icon(Icons.remove_circle_outline, size: 28),
          ),
          const SizedBox(height: 16),
          if (isPregnant && isLactating)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: scheme.onTertiaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.onboardingPhaseBothNote,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PhaseChoice extends StatelessWidget {
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  // Nullable: the "neither" choice has no associated nutrition fact.
  final NutritionFact? fact;
  final Widget? leading;
  const _PhaseChoice({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
    required this.fact,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: leading,
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (fact != null) InfoButton(fact: fact!),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyStep extends StatelessWidget {
  final DateTime birthdate;
  final ValueChanged<DateTime> onBirthdateChanged;
  final TextEditingController height;
  final TextEditingController weight;
  final double activityFactor;
  final ValueChanged<double> onActivityChanged;

  const _BodyStep({
    required this.birthdate,
    required this.onBirthdateChanged,
    required this.height,
    required this.weight,
    required this.activityFactor,
    required this.onActivityChanged,
  });

  Future<void> _pickBirthdate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: birthdate,
      firstDate: DateTime(now.year - 80),
      lastDate: now,
      helpText: AppLocalizations.of(context).settingsBirthdatePickerHelp,
    );
    if (picked != null) onBirthdateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final labels = activityLabelsOf(l10n);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.onboardingBasicsTitle,
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            InfoButton(
              fact: NutritionFact(
                topic: l10n.onboardingBasicsInfoTopic,
                summary: l10n.onboardingBasicsInfoSummary,
                detail: l10n.onboardingBasicsInfoDetail,
                source: l10n.onboardingBasicsInfoSource,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _pickBirthdate(context),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.settingsFieldBirthdate,
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              _formatBirthdate(context, birthdate),
              style: textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: height,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.settingsFieldHeight,
                  border: const OutlineInputBorder(),
                  suffixText: l10n.settingsFieldHeightSuffix,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: weight,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.settingsFieldWeight,
                  border: const OutlineInputBorder(),
                  suffixText: l10n.settingsFieldWeightSuffix,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(l10n.settingsSectionActivity,
                  style: textTheme.titleSmall),
            ),
            InfoButton(
              fact: NutritionFact(
                topic: l10n.settingsSectionActivity,
                summary: l10n.settingsActivityInfoSummary,
                detail:
                    '${l10n.settingsActivityInfoDetail} ${l10n.onboardingActivityHintBaby}',
                source: l10n.settingsActivityInfoSource,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<double>(
            segments: ActivityLevel.allFor(labels)
                .map((l) =>
                    ButtonSegment(value: l.factor, label: Text(l.label)))
                .toList(),
            selected: {ActivityLevel.closestTo(activityFactor, labels).factor},
            showSelectedIcon: false,
            onSelectionChanged: (s) => onActivityChanged(s.first),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          ActivityLevel.closestTo(activityFactor, labels).hint,
          style: textTheme.bodySmall?.copyWith(color: scheme.outline),
        ),
      ],
    );
  }
}

class _PhaseDetailsStep extends StatelessWidget {
  final bool isPregnant;
  final bool isLactating;
  final int trimester;
  final ValueChanged<int> onTrimesterChanged;
  final int numChildren;
  final ValueChanged<int> onChildrenChanged;
  final int childAgeGroup;
  final ValueChanged<int> onAgeGroupChanged;
  final DateTime? youngestChildBirthdate;
  final VoidCallback onPickBirthdate;
  final VoidCallback onClearBirthdate;
  final int milkSharePercent;
  final ValueChanged<int> onSharePercentChanged;
  final int dailyVolumeMl;
  final ValueChanged<int> onVolumeChanged;

  const _PhaseDetailsStep({
    required this.isPregnant,
    required this.isLactating,
    required this.trimester,
    required this.onTrimesterChanged,
    required this.numChildren,
    required this.onChildrenChanged,
    required this.childAgeGroup,
    required this.onAgeGroupChanged,
    required this.youngestChildBirthdate,
    required this.onPickBirthdate,
    required this.onClearBirthdate,
    required this.milkSharePercent,
    required this.onSharePercentChanged,
    required this.dailyVolumeMl,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.onboardingDetailsTitle,
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            InfoButton(
              fact: isPregnant
                  ? energyPregnancyFact(l10n)
                  : energyLactationFact(l10n),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!isPregnant && !isLactating)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              l10n.onboardingPhaseNeitherHint,
              style: textTheme.bodyMedium?.copyWith(color: scheme.outline),
            ),
          ),
        if (isPregnant) ...[
          Row(
            children: [
              Expanded(
                child: Text(l10n.settingsPhaseTrimester,
                    style: textTheme.titleSmall),
              ),
              InfoButton(fact: energyPregnancyFact(l10n)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1. T')),
                ButtonSegment(value: 2, label: Text('2. T')),
                ButtonSegment(value: 3, label: Text('3. T')),
              ],
              selected: {trimester},
              showSelectedIcon: false,
              onSelectionChanged: (s) => onTrimesterChanged(s.first),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (isLactating) ...[
          Row(
            children: [
              Expanded(
                child: Text(l10n.settingsMilkChildren,
                    style: textTheme.titleSmall),
              ),
              InfoButton(fact: energyLactationFact(l10n)),
            ],
          ),
          const SizedBox(height: 8),
          _NumberStepper(
            value: numChildren,
            min: 1,
            max: 4,
            onChanged: onChildrenChanged,
          ),
          const SizedBox(height: 20),
          Text(
            numChildren == 1
                ? l10n.settingsMilkChildSingular
                : l10n.settingsMilkChildPlural,
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ChildAgeInput(
            bucket: childAgeGroup,
            onBucketChanged: onAgeGroupChanged,
            birthdate: youngestChildBirthdate,
            onPickBirthdate: onPickBirthdate,
            onClearBirthdate: onClearBirthdate,
          ),
          const SizedBox(height: 20),
          Text(
            numChildren == 1
                ? l10n.onboardingVolumeShareQuestionSingular
                : l10n.onboardingVolumeShareQuestionPlural,
            style: textTheme.titleSmall,
          ),
          Slider(
            value: milkSharePercent.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            label: '$milkSharePercent%',
            onChanged: (v) => onSharePercentChanged(v.round()),
          ),
          Text(
            numChildren == 1
                ? l10n.settingsMilkShareSingular(milkSharePercent)
                : l10n.settingsMilkSharePlural(milkSharePercent),
            style: textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(l10n.settingsMilkVolume,
                    style: textTheme.titleSmall),
              ),
              InfoButton(
                fact: NutritionFact(
                  topic: l10n.settingsMilkVolumeInfoTopic,
                  summary: l10n.settingsMilkVolumeInfoTitle,
                  detail: l10n.onboardingVolumeInfoDetail,
                  source: l10n.settingsMilkVolumeInfoSource,
                ),
              ),
            ],
          ),
          Slider(
            value: dailyVolumeMl.toDouble().clamp(0, 3000),
            min: 0,
            max: 3000,
            divisions: 60,
            label: '$dailyVolumeMl ml',
            onChanged: (v) => onVolumeChanged(v.round()),
          ),
          Text(
            l10n.settingsMilkVolumePerDayLabel(
              dailyVolumeMl,
              UserProfileSettings.volumeBasedSupplement(dailyVolumeMl),
            ),
            style: textTheme.bodySmall?.copyWith(
              color: scheme.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryStep extends StatelessWidget {
  final UserProfileSettings profile;
  final bool remindersOptIn;
  final ValueChanged<bool> onRemindersToggled;
  const _SummaryStep({
    required this.profile,
    required this.remindersOptIn,
    required this.onRemindersToggled,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final bmrTdee = calculateBmrTdee(profile);
    final pregSupp = calculatePregnancySupplement(profile);
    final lactSupp = calculateLactationSupplement(profile);
    final total = bmrTdee + pregSupp + lactSupp;
    final macros = calculateMacroTargets(profile, total);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text(
          l10n.onboardingResultEyebrow,
          style: textTheme.labelSmall?.copyWith(
            color: scheme.outline,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.settingsTodayTarget,
          style: textTheme.titleLarge?.copyWith(
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        // Editorial result card with the big italic kcal hero.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatKcal(total),
                    style: textTheme.displaySmall?.copyWith(
                      color: scheme.primary,
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'kcal',
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _buildLede(context, profile, bmrTdee, pregSupp, lactSupp),
                style: textTheme.titleLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: scheme.outlineVariant, height: 1),
              const SizedBox(height: 16),
              Text(
                l10n.onboardingResultMacrosEyebrow,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.outline,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _MacroRow(
                  label: l10n.settingsMacroProtein,
                  value: '${macros.proteinG} g'),
              Divider(color: scheme.outlineVariant, height: 1),
              _MacroRow(
                  label: l10n.settingsMacroCarbs,
                  value: '${macros.carbsG} g'),
              Divider(color: scheme.outlineVariant, height: 1),
              _MacroRow(
                  label: l10n.settingsMacroFat, value: '${macros.fatG} g'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Spacer(),
            InfoButton(fact: proteinLactationFact(l10n)),
          ],
        ),
        const SizedBox(height: 16),
        // Meal-reminder opt-in card. Default on; explicit toggle so the user
        // sees they're opting in to iOS notifications before "Tagebuch öffnen"
        // triggers the system permission prompt.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.notifications_active_outlined,
                  size: 22, color: scheme.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsReminderToggleTitle,
                      style: textTheme.bodyLarge
                          ?.copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.onboardingRemindersDetail,
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: remindersOptIn,
                onChanged: onRemindersToggled,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Medical disclaimer: shown as plain informational copy. Tapping
        // the Loslegen CTA records the acceptance timestamp in _finish so
        // we keep an audit trail without a separate checkbox UI.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 20, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    l10n.onboardingDisclaimerTitle,
                    style: textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onboardingDisclaimerBody,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildLede(BuildContext context, UserProfileSettings p, int bmr,
      int preg, int lact) {
    final l10n = AppLocalizations.of(context);
    final parts = <String>[l10n.onboardingLedeBase(formatKcal(bmr))];
    if (preg > 0) {
      parts.add(l10n.onboardingLedePregnancy(formatKcal(preg), p.trimester ?? 0));
    }
    if (lact > 0) parts.add(l10n.onboardingLedeLactation(formatKcal(lact)));
    return parts.join(' · ');
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final String value;
  const _MacroRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
            ),
          ),
          Text(
            value,
            style: textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _NumberStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Text(value.toString(), style: textTheme.titleLarge),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

String _formatBirthdate(BuildContext context, DateTime d) => intl.DateFormat.yMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(d);

class _GoalStep extends StatelessWidget {
  final String goal;
  final ValueChanged<String> onChanged;
  const _GoalStep({required this.goal, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.onboardingGoalTitle,
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              InfoButton(fact: goalFact(l10n)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settingsGoalHint,
            style: textTheme.bodyMedium?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                    value: CoachGoal.nutrients,
                    label: Text(l10n.settingsGoalNutrients)),
                ButtonSegment(
                    value: CoachGoal.body,
                    label: Text(l10n.settingsGoalBody)),
                ButtonSegment(
                    value: CoachGoal.both,
                    label: Text(l10n.settingsGoalBoth)),
              ],
              selected: {goal},
              showSelectedIcon: false,
              onSelectionChanged: (s) => onChanged(s.first),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingGoalSubtitle,
            style: textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
  }
}

class _SupplementStep extends StatelessWidget {
  final List<ActiveSupplement> supplements;
  final VoidCallback onAdd;
  final void Function(int index, ActiveSupplement edited) onEdit;
  final void Function(int index) onRemove;
  // "Nein, nehme keins" should feel like a real skip target, not just a
  // text label - parent wires this up to advance past this step directly.
  final VoidCallback onSkip;
  const _SupplementStep({
    required this.supplements,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.supplementOnboardingTitle,
            style: textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.supplementOnboardingBody,
            style: textTheme.bodyMedium?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < supplements.length; i++) ...[
            _OnboardingSupplementListItem(
              supplement: supplements[i],
              onEdit: () async {
                final edited =
                    await showSupplementEditSheet(context, supplements[i]);
                if (edited != null) onEdit(i, edited);
              },
              onRemove: () => onRemove(i),
            ),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.medication_outlined, size: 18),
              label: Text(supplements.isEmpty
                  ? l10n.supplementAddCta
                  : l10n.supplementAddAnotherCta),
            ),
          ),
          if (supplements.isEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onSkip,
                child: Text(l10n.supplementSkipCta),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OnboardingSupplementListItem extends StatelessWidget {
  final ActiveSupplement supplement;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  const _OnboardingSupplementListItem({
    required this.supplement,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplement.name,
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  l10n.supplementCurrentDoses(supplement.dosesPerDay),
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.outline),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: l10n.supplementEdit,
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: l10n.supplementRemove,
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

