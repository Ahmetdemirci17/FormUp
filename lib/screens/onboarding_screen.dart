import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/enums.dart';
import '../models/user_profile.dart';
import '../providers/onboarding_provider.dart';
import '../providers/profile_provider.dart';
import '../services/calorie_calculator.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_scale_button.dart';
import '../widgets/goal_target_form.dart';
import '../widgets/layered_card.dart';
import '../widgets/validated_number_field.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  static const _totalSteps = 5;
  bool _validationAttempted = false;

  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingDraftProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kalori Takip',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hedefine uygun günlük kalori kotanı hesaplayalım',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / _totalSteps,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceElevated,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adım ${_step + 1} / $_totalSteps',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: _buildStep(draft),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: AnimatedScaleButton(
                        onPressed: () => setState(() {
                          _validationAttempted = false;
                          _step--;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'Geri',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(
                      label: _step == _totalSteps - 1 ? 'Başla' : 'İleri',
                      expanded: true,
                      onPressed: _onNext,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed(UserProfile draft) {
    return switch (_step) {
      0 => draft.age >= 10 && draft.age <= 100,
      1 => draft.heightCm >= 100 && draft.weightKg >= 30,
      2 => true,
      3 => isGoalTargetComplete(draft),
      _ => CalorieCalculator.hasCompleteBodyMetrics(draft),
    };
  }

  Future<void> _onNext() async {
    setState(() => _validationAttempted = true);
    final draft = ref.read(onboardingDraftProvider);
    if (!_canProceed(draft)) return;

    if (_step < _totalSteps - 1) {
      setState(() {
        _validationAttempted = false;
        _step++;
      });
      return;
    }

    await ref.read(profileProvider.notifier).saveProfile(draft);
  }

  Widget _buildStep(UserProfile draft) {
    return switch (_step) {
      0 => _StepGenderAge(
          key: const ValueKey(0),
          draft: draft,
          ageController: _ageController,
          showErrors: _validationAttempted,
        ),
      1 => _StepBody(
          key: const ValueKey(1),
          draft: draft,
          heightController: _heightController,
          weightController: _weightController,
          showErrors: _validationAttempted,
        ),
      2 => _StepActivity(draft: draft, key: const ValueKey(2)),
      3 => _StepGoal(draft: draft, key: const ValueKey(3)),
      _ => _StepSummary(draft: draft, key: const ValueKey(4)),
    };
  }
}

class _StepGenderAge extends ConsumerWidget {
  const _StepGenderAge({
    super.key,
    required this.draft,
    required this.ageController,
    required this.showErrors,
  });

  final UserProfile draft;
  final TextEditingController ageController;
  final bool showErrors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ageInvalid = showErrors && (draft.age < 10 || draft.age > 100);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Cinsiyet', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: Gender.values.map((g) {
            final selected = draft.gender == g;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: g == Gender.female ? 0 : 8),
                child: AnimatedScaleButton(
                  onPressed: () => ref.read(onboardingDraftProvider.notifier).update(
                        (s) => s.copyWith(gender: g),
                      ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(
                      g.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        ValidatedNumberField(
          controller: ageController,
          label: 'Yaş',
          hintText: 'örn: 25',
          showError: ageInvalid,
          onChanged: (v) => ref.read(onboardingDraftProvider.notifier).update(
                (s) => s.copyWith(age: int.tryParse(v.trim()) ?? 0),
              ),
        ),
      ],
    );
  }
}

class _StepBody extends ConsumerWidget {
  const _StepBody({
    super.key,
    required this.draft,
    required this.heightController,
    required this.weightController,
    required this.showErrors,
  });

  final UserProfile draft;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final bool showErrors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heightInvalid = showErrors && draft.heightCm < 100;
    final weightInvalid = showErrors && draft.weightKg < 30;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ValidatedNumberField(
          controller: heightController,
          label: 'Boy (cm)',
          hintText: 'örn: 170',
          suffixText: 'cm',
          showError: heightInvalid,
          onChanged: (v) => ref.read(onboardingDraftProvider.notifier).update(
                (s) => s.copyWith(heightCm: double.tryParse(v.trim().replaceAll(',', '.')) ?? 0),
              ),
        ),
        const SizedBox(height: 16),
        ValidatedNumberField(
          controller: weightController,
          label: 'Kilo (kg)',
          hintText: 'örn: 70',
          suffixText: 'kg',
          decimal: true,
          showError: weightInvalid,
          onChanged: (v) => ref.read(onboardingDraftProvider.notifier).update(
                (s) => s.copyWith(weightKg: double.tryParse(v.trim().replaceAll(',', '.')) ?? 0),
              ),
        ),
      ],
    );
  }
}

class _StepActivity extends ConsumerWidget {
  const _StepActivity({super.key, required this.draft});
  final UserProfile draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: ActivityLevel.values.map((level) {
        final selected = draft.activityLevel == level;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedScaleButton(
            onPressed: () => ref.read(onboardingDraftProvider.notifier).update(
                  (s) => s.copyWith(activityLevel: level),
                ),
            child: LayeredCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(level.label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        Text(
                          'Çarpan: ${level.multiplier}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StepGoal extends ConsumerWidget {
  const _StepGoal({super.key, required this.draft});
  final UserProfile draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ...GoalType.values.map((goal) {
          final selected = draft.goalType == goal;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AnimatedScaleButton(
              onPressed: () => ref.read(onboardingDraftProvider.notifier).update(
                    (s) => resetGoalTarget(s, goal),
                  ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                ),
                child: Text(
                  goal.label,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
            ),
          );
        }),
        GoalTargetForm(
          profile: draft,
          onGoalKgChanged: (kg) => ref.read(onboardingDraftProvider.notifier).update(
                (s) => s.copyWith(goalKg: kg),
              ),
          onGoalDaysChanged: (days) => ref.read(onboardingDraftProvider.notifier).update(
                (s) => s.copyWith(goalDays: days),
              ),
        ),
      ],
    );
  }
}

class _StepSummary extends StatelessWidget {
  const _StepSummary({super.key, required this.draft});
  final UserProfile draft;

  @override
  Widget build(BuildContext context) {
    final calc = CalorieCalculator.calculate(draft);
    final belowMin = CalorieCalculator.isBelowMinimumSafeCalories(draft, calc.dailyQuota);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        LayeredCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow('BMR', '${calc.bmr.round()} kcal'),
              _SummaryRow('TDEE', '${calc.tdee.round()} kcal'),
              _SummaryRow('Günlük kota', '${calc.dailyQuota.round()} kcal', highlight: true),
            ],
          ),
        ),
        if (belowMin) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: Text(
              'Bu hedefe bu sürede ulaşmak sağlıklı değil, süreyi uzatmanı öneririz.',
              style: GoogleFonts.inter(color: AppColors.warning, height: 1.4, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary)),
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              fontSize: highlight ? 20 : 16,
              color: highlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
