import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/activity_entry.dart';
import '../models/enums.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../providers/refresh_provider.dart';
import '../services/calorie_calculator.dart';
import '../services/database_helper.dart';
import '../theme/app_colors.dart';
import '../widgets/layered_card.dart';

enum _WalkingInputMode { duration, steps }

class AddActivityScreen extends ConsumerStatefulWidget {
  const AddActivityScreen({super.key});

  @override
  ConsumerState<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends ConsumerState<AddActivityScreen> {
  ActivityType _type = ActivityType.walking;
  _WalkingInputMode _walkingMode = _WalkingInputMode.duration;

  int _durationMinutes = 30;
  int _steps = 0;

  bool _durationOverridden = false;
  bool _distanceOverridden = false;
  double? _manualDistanceKm;
  int? _manualDurationMinutes;

  bool _manualCalories = false;
  double _manualValue = 0;

  final _stepsController = TextEditingController();
  final _distanceController = TextEditingController();
  final _durationController = TextEditingController();
  final _manualCalorieController = TextEditingController();

  @override
  void dispose() {
    _stepsController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    _manualCalorieController.dispose();
    super.dispose();
  }

  UserProfile? get _profile => ref.watch(profileProvider).value;

  bool get _profileReady {
    final p = _profile;
    return p != null && CalorieCalculator.hasCompleteBodyMetrics(p);
  }

  double get _effectiveDistanceKm {
    if (_distanceOverridden && _manualDistanceKm != null) return _manualDistanceKm!;
    final p = _profile;
    if (p == null || _steps <= 0) return 0;
    return CalorieCalculator.distanceKmFromSteps(heightCm: p.heightCm, steps: _steps);
  }

  int get _effectiveDurationMinutes {
    if (_durationOverridden && _manualDurationMinutes != null) {
      return _manualDurationMinutes!;
    }
    if (_type == ActivityType.walking && _walkingMode == _WalkingInputMode.steps) {
      return CalorieCalculator.durationFromDistanceKm(_effectiveDistanceKm);
    }
    return _durationMinutes;
  }

  double get _calculatedCalories {
    final profile = _profile;
    if (profile == null) return 0;
    return CalorieCalculator.calculateActivityCalories(
      profile: profile,
      type: _type,
      durationMinutes: _effectiveDurationMinutes,
    );
  }

  double get _finalCalories => _manualCalories ? _manualValue : _calculatedCalories;

  void _syncDerivedFieldsFromSteps() {
    if (_type != ActivityType.walking || _walkingMode != _WalkingInputMode.steps) return;
    if (_distanceOverridden || _durationOverridden) return;

    final distance = _effectiveDistanceKm;
    final duration = CalorieCalculator.durationFromDistanceKm(distance);
    _distanceController.text = distance > 0 ? distance.toStringAsFixed(2) : '';
    _durationController.text = duration > 0 ? duration.toString() : '';
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Aktivite Ekle')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (!_profileReady)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Aktivite kalorisi profilinizdeki gerçek yaş, boy ve kilo ile hesaplanır. '
                'Lütfen önce profil bilgilerinizi tamamlayın.',
                style: GoogleFonts.inter(color: AppColors.warning, fontSize: 13, height: 1.4),
              ),
            ),
          Text('Aktivite türü', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...ActivityType.values.map((type) {
            final selected = _type == type;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LayeredCard(
                onTap: () => setState(() {
                  _type = type;
                  _walkingMode = _WalkingInputMode.duration;
                  _steps = 0;
                  _stepsController.clear();
                  _durationOverridden = false;
                  _distanceOverridden = false;
                  _manualDistanceKm = null;
                  _manualDurationMinutes = null;
                }),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(type.label, style: GoogleFonts.inter(color: AppColors.textPrimary)),
                    ),
                    Text('MET ${type.metValue}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    if (selected) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          if (_type == ActivityType.walking) ...[
            SegmentedButton<_WalkingInputMode>(
              segments: const [
                ButtonSegment(value: _WalkingInputMode.duration, label: Text('Süre gir')),
                ButtonSegment(value: _WalkingInputMode.steps, label: Text('Adım sayısı gir')),
              ],
              selected: {_walkingMode},
              onSelectionChanged: (selection) {
                setState(() {
                  _walkingMode = selection.first;
                  _durationOverridden = false;
                  _distanceOverridden = false;
                  _manualDistanceKm = null;
                  _manualDurationMinutes = null;
                  _steps = 0;
                  _stepsController.clear();
                  _distanceController.clear();
                  _durationController.clear();
                });
              },
            ),
            const SizedBox(height: 16),
          ],
          if (_type == ActivityType.walking && _walkingMode == _WalkingInputMode.steps) ...[
            TextFormField(
              controller: _stepsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Adım sayısı',
                hintText: 'örn: 8000',
              ),
              onChanged: (v) {
                setState(() {
                  _steps = int.tryParse(v.trim()) ?? 0;
                  if (!_distanceOverridden && !_durationOverridden) {
                    _syncDerivedFieldsFromSteps();
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            if (_steps > 0 && profile != null) ...[
              LayeredCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DerivedRow('Adım', '$_steps'),
                    _DerivedRow('Mesafe', '${_effectiveDistanceKm.toStringAsFixed(2)} km'),
                    _DerivedRow('Süre', '$_effectiveDurationMinutes dk'),
                    _DerivedRow(
                      'Tahmini yakım',
                      '${_calculatedCalories.round()} kcal',
                      highlight: true,
                    ),
                    if (profile.heightCm > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Adım uzunluğu: ${CalorieCalculator.stepLengthMeters(profile.heightCm).toStringAsFixed(2)} m',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'İsterseniz otomatik hesaplanan değerleri düzenleyebilirsiniz:',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _distanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Mesafe (km)', suffixText: 'km'),
                onChanged: (v) {
                  setState(() {
                    _distanceOverridden = true;
                    _manualDistanceKm = double.tryParse(v.trim().replaceAll(',', '.'));
                    if (!_durationOverridden && _manualDistanceKm != null) {
                      final d = CalorieCalculator.durationFromDistanceKm(_manualDistanceKm!);
                      _manualDurationMinutes = null;
                      _durationController.text = d > 0 ? d.toString() : '';
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Süre (dk)', suffixText: 'dk'),
                onChanged: (v) {
                  setState(() {
                    _durationOverridden = true;
                    _manualDurationMinutes = int.tryParse(v.trim());
                  });
                },
              ),
            ],
          ] else ...[
            Text('Süre (dakika)', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Slider(
              value: _durationMinutes.toDouble().clamp(5, 180),
              min: 5,
              max: 180,
              divisions: 35,
              activeColor: AppColors.primary,
              label: '$_durationMinutes dk',
              onChanged: _profileReady
                  ? (v) => setState(() => _durationMinutes = v.round())
                  : null,
            ),
          ],
          const SizedBox(height: 8),
          if (profile != null && _profileReady)
            Text(
              'Hesap: ${profile.weightKg.toStringAsFixed(1)} kg, ${profile.age} yaş '
              '(katsayı ${CalorieCalculator.ageFactor(profile.age).toStringAsFixed(2)})',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Manuel kalori gir', style: TextStyle(color: AppColors.textPrimary)),
            value: _manualCalories,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => setState(() => _manualCalories = v),
          ),
          if (_manualCalories)
            TextFormField(
              controller: _manualCalorieController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Yakılan kalori (kcal)'),
              onChanged: (v) => setState(() => _manualValue = double.tryParse(v.trim()) ?? 0),
            )
          else
            LayeredCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tahmini yakım', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                  Text(
                    '${_calculatedCalories.round()} kcal',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.success),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          GradientButton(
            label: 'Kaydet',
            expanded: true,
            onPressed: _profileReady && _finalCalories > 0 && _effectiveDurationMinutes > 0 ? _save : null,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final date = ref.read(selectedDateProvider);
    await DatabaseHelper.instance.insertActivity(ActivityEntry(
      date: date,
      type: _type,
      durationMinutes: _effectiveDurationMinutes,
      caloriesBurned: _finalCalories,
    ));

    bumpRefresh(ref);
    if (!mounted) return;
    Navigator.pop(context);
  }
}

class _DerivedRow extends StatelessWidget {
  const _DerivedRow(this.label, this.value, {this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary)),
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              color: highlight ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
