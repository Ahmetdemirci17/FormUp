import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/enums.dart';
import '../models/user_profile.dart';
import '../providers/onboarding_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/refresh_provider.dart';
import '../services/calorie_calculator.dart';
import '../theme/app_colors.dart';
import '../widgets/goal_target_form.dart';
import '../widgets/layered_card.dart';
import '../widgets/validated_number_field.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserProfile? _draft;
  bool _controllersReady = false;
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

  void _initControllers(UserProfile profile) {
    if (_controllersReady) return;
    _ageController.text = formatSavedInt(profile.age);
    _heightController.text = formatSavedDouble(profile.heightCm, decimals: 0);
    _weightController.text = formatSavedDouble(profile.weightKg);
    _draft = profile;
    _controllersReady = true;
  }

  bool _canSave(UserProfile draft) {
    return CalorieCalculator.hasCompleteBodyMetrics(draft) && isGoalTargetComplete(draft);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil & Ayarlar')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profil bulunamadı'));
          }
          _initControllers(profile);
          final draft = _draft!;

          final calc = CalorieCalculator.calculate(draft);
          final belowMin = CalorieCalculator.isBelowMinimumSafeCalories(draft, calc.dailyQuota);
          final canSave = _canSave(draft);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              LayeredCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Metabolizma', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    _InfoRow('BMR', '${calc.bmr.round()} kcal'),
                    _InfoRow('TDEE', '${calc.tdee.round()} kcal'),
                    _InfoRow('Günlük kota', '${calc.dailyQuota.round()} kcal'),
                  ],
                ),
              ),
              if (belowMin && draft.goalType != GoalType.maintain) ...[
                const SizedBox(height: 12),
                Text(
                  'Bu hedefe bu sürede ulaşmak sağlıklı değil, süreyi uzatmanı öneririz.',
                  style: GoogleFonts.inter(color: AppColors.warning, fontSize: 13, height: 1.4),
                ),
              ],
              const SizedBox(height: 24),
              DropdownButtonFormField<Gender>(
                initialValue: draft.gender,
                dropdownColor: AppColors.surfaceElevated,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Cinsiyet'),
                items: Gender.values.map((g) => DropdownMenuItem(value: g, child: Text(g.label))).toList(),
                onChanged: (v) => setState(() => _draft = _draft!.copyWith(gender: v)),
              ),
              const SizedBox(height: 12),
              ValidatedNumberField(
                controller: _ageController,
                label: 'Yaş',
                hintText: 'örn: 25',
                showError: _validationAttempted && draft.age < 10,
                onChanged: (v) => setState(
                  () => _draft = _draft!.copyWith(age: int.tryParse(v.trim()) ?? 0),
                ),
              ),
              const SizedBox(height: 12),
              ValidatedNumberField(
                controller: _heightController,
                label: 'Boy (cm)',
                hintText: 'örn: 170',
                suffixText: 'cm',
                showError: _validationAttempted && draft.heightCm < 100,
                onChanged: (v) => setState(
                  () => _draft = _draft!.copyWith(
                    heightCm: double.tryParse(v.trim().replaceAll(',', '.')) ?? 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ValidatedNumberField(
                controller: _weightController,
                label: 'Kilo (kg)',
                hintText: 'örn: 70',
                suffixText: 'kg',
                decimal: true,
                showError: _validationAttempted && draft.weightKg < 30,
                onChanged: (v) => setState(
                  () => _draft = _draft!.copyWith(
                    weightKg: double.tryParse(v.trim().replaceAll(',', '.')) ?? 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GoalType>(
                initialValue: draft.goalType,
                dropdownColor: AppColors.surfaceElevated,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Hedef'),
                items: GoalType.values.map((g) => DropdownMenuItem(value: g, child: Text(g.label))).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _draft = resetGoalTarget(_draft!, v));
                },
              ),
              GoalTargetForm(
                profile: draft,
                onGoalKgChanged: (kg) => setState(() => _draft = _draft!.copyWith(goalKg: kg)),
                onGoalDaysChanged: (days) => setState(() => _draft = _draft!.copyWith(goalDays: days)),
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: 'Kaydet',
                expanded: true,
                onPressed: () async {
                  setState(() => _validationAttempted = true);
                  if (!canSave) return;

                  await ref.read(profileProvider.notifier).saveProfile(_draft!);
                  bumpRefresh(ref);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil güncellendi')),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await ref.read(profileProvider.notifier).deleteProfile();
                  ref.read(onboardingDraftProvider.notifier).state = UserProfile.initial();
                },
                child: Text(
                  'Profili sıfırla',
                  style: GoogleFonts.inter(color: AppColors.accent),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
