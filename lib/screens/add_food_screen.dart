import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/food_entry.dart';
import '../providers/refresh_provider.dart';
import '../services/database_helper.dart';
import '../theme/app_colors.dart';
import '../widgets/layered_card.dart';

class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({super.key});

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  double _calories = 0;
  double _protein = 0;
  double _carbs = 0;
  double _fat = 0;
  MealType _mealType = MealType.breakfast;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Yemek Ekle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Yemek adı'),
              style: const TextStyle(color: AppColors.textPrimary),
              validator: (v) => v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
              onSaved: (v) => _name = v!.trim(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MealType>(
              value: _mealType,
              dropdownColor: AppColors.surfaceElevated,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Öğün'),
              items: MealType.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                  .toList(),
              onChanged: (v) => setState(() => _mealType = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Kalori (kcal)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              validator: (v) => _validatePositive(v),
              onSaved: (v) => _calories = double.parse(v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Protein (g)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              onSaved: (v) => _protein = double.tryParse(v ?? '') ?? 0,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Karbonhidrat (g)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              onSaved: (v) => _carbs = double.tryParse(v ?? '') ?? 0,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Yağ (g)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              onSaved: (v) => _fat = double.tryParse(v ?? '') ?? 0,
            ),
            const SizedBox(height: 32),
            GradientButton(
              label: 'Kaydet',
              expanded: true,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  String? _validatePositive(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) return 'Geçerli bir değer girin';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final date = ref.read(selectedDateProvider);
    await DatabaseHelper.instance.insertFood(FoodEntry(
      date: date,
      mealType: _mealType,
      name: _name,
      calories: _calories,
      protein: _protein,
      carbs: _carbs,
      fat: _fat,
    ));

    bumpRefresh(ref);
    if (!mounted) return;
    Navigator.pop(context);
  }
}
