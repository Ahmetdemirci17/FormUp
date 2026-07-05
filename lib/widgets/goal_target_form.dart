import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/enums.dart';
import '../models/user_profile.dart';
import '../services/calorie_calculator.dart';
import '../theme/app_colors.dart';

/// Hedef kilo ver/al seçildiğinde kg + gün girişi.
class GoalTargetForm extends StatelessWidget {
  const GoalTargetForm({
    super.key,
    required this.profile,
    required this.onGoalKgChanged,
    required this.onGoalDaysChanged,
  });

  final UserProfile profile;
  final ValueChanged<double> onGoalKgChanged;
  final ValueChanged<int> onGoalDaysChanged;

  @override
  Widget build(BuildContext context) {
    if (profile.goalType == GoalType.maintain) {
      return const SizedBox.shrink();
    }

    final weeklyRate = CalorieCalculator.weeklyChangeRateKg(profile);
    final calc = CalorieCalculator.calculate(profile);
    final belowMin = profile.goalKg > 0 &&
        profile.goalDays > 0 &&
        CalorieCalculator.isBelowMinimumSafeCalories(profile, calc.dailyQuota);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(
          'Hedef detayları',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('kg-${profile.goalType.name}'),
                initialValue: profile.goalKg > 0 ? _formatKg(profile.goalKg) : '',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Kaç kg?',
                  suffixText: 'kg',
                ),
                onChanged: (v) => onGoalKgChanged(double.tryParse(v.replaceAll(',', '.')) ?? 0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                key: ValueKey('days-${profile.goalType.name}'),
                initialValue: profile.goalDays > 0 ? profile.goalDays.toString() : '',
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Kaç günde?',
                  suffixText: 'gün',
                ),
                onChanged: (v) => onGoalDaysChanged(int.tryParse(v) ?? 0),
              ),
            ),
          ],
        ),
        if (weeklyRate != null) ...[
          const SizedBox(height: 10),
          Text(
            '≈ ${weeklyRate.toStringAsFixed(1)} kg/hafta',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
        if (belowMin) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: Text(
              'Bu hedefe bu sürede ulaşmak sağlıklı değil, süreyi uzatmanı öneririz. '
              'Güvenli minimum: ${CalorieCalculator.minimumSafeCalories(profile.gender).round()} kcal/gün.',
              style: GoogleFonts.inter(color: AppColors.warning, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ],
    );
  }

  String _formatKg(double kg) {
    return kg == kg.roundToDouble() ? kg.round().toString() : kg.toString();
  }
}

bool isGoalTargetComplete(UserProfile profile) {
  if (profile.goalType == GoalType.maintain) return true;
  return profile.goalKg > 0 && profile.goalDays > 0;
}

UserProfile resetGoalTarget(UserProfile profile, GoalType goalType) {
  return profile.copyWith(
    goalType: goalType,
    goalKg: 0,
    goalDays: 0,
  );
}
