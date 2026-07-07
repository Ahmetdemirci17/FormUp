import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/enums.dart';
import '../models/food_entry.dart';
import '../models/recognized_food.dart';
import '../providers/refresh_provider.dart';
import '../services/database_helper.dart';
import '../services/food_recognition_service.dart';
import '../theme/app_colors.dart';
import '../widgets/layered_card.dart';

class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({super.key});

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _recognitionService = FoodRecognitionService();

  String _name = '';
  double _calories = 0;
  double _protein = 0;
  double _carbs = 0;
  double _fat = 0;
  MealType _mealType = MealType.breakfast;

  bool _isAnalyzing = false;
  int _loadingMessageIndex = 0;
  Timer? _loadingTimer;
  final _loadingMessages = const [
    'Yemek analiz ediliyor...',
    'Görsel inceleniyor...',
    'Besin değerleri hesaplanıyor...',
  ];

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Yemek Ekle')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      icon: Icons.edit_rounded,
                      label: 'Manuel Ekle',
                      selected: true,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeButton(
                      icon: Icons.photo_camera_rounded,
                      label: 'Fotoğraf ile Ekle',
                      selected: false,
                      onTap: _showImageSourceSheet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Yemek adı'),
                      style: const TextStyle(color: AppColors.textPrimary),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
                      onSaved: (v) => _name = v!.trim(),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<MealType>(
                      initialValue: _mealType,
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
            ],
          ),
          if (_isAnalyzing)
            Container(
              color: AppColors.background.withValues(alpha: 0.86),
              child: Center(
                child: LayeredCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 18),
                      Text(
                        _loadingMessages[_loadingMessageIndex],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String? _validatePositive(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) return 'Geçerli bir değer girin';
    return null;
  }

  Future<void> _showImageSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
                title: const Text('Kamera', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Galeri', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final image = await _picker.pickImage(source: source, imageQuality: 82, maxWidth: 1400);
    if (image == null) return;
    await _analyzeImage(File(image.path));
  }

  Future<void> _analyzeImage(File imageFile) async {
    setState(() {
      _isAnalyzing = true;
      _loadingMessageIndex = 0;
    });
    _loadingTimer?.cancel();
    _loadingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() => _loadingMessageIndex = (_loadingMessageIndex + 1) % _loadingMessages.length);
    });

    try {
      final recognized = await _recognitionService.analyzeImage(imageFile);
      if (!mounted) return;
      await _showRecognizedFoodSheet(recognized);
    } on FoodRecognitionException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Analiz yapılamadı, manuel giriş yapabilirsiniz.');
    } finally {
      _loadingTimer?.cancel();
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _showRecognizedFoodSheet(RecognizedFood recognized) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RecognizedFoodConfirmation(
        recognizedFood: recognized,
        initialMealType: _mealType,
        onConfirm: _insertRecognizedFood,
      ),
    );

    if (added == true && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _insertRecognizedFood(RecognizedFood food, MealType mealType) async {
    final date = ref.read(selectedDateProvider);
    await DatabaseHelper.instance.insertFood(FoodEntry(
      date: date,
      mealType: mealType,
      name: food.foodName,
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
    ));
    bumpRefresh(ref);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? AppColors.primary : AppColors.textPrimary,
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
        backgroundColor: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _RecognizedFoodConfirmation extends StatefulWidget {
  const _RecognizedFoodConfirmation({
    required this.recognizedFood,
    required this.initialMealType,
    required this.onConfirm,
  });

  final RecognizedFood recognizedFood;
  final MealType initialMealType;
  final Future<void> Function(RecognizedFood food, MealType mealType) onConfirm;

  @override
  State<_RecognizedFoodConfirmation> createState() => _RecognizedFoodConfirmationState();
}

class _RecognizedFoodConfirmationState extends State<_RecognizedFoodConfirmation> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late MealType _mealType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final food = widget.recognizedFood;
    _nameController = TextEditingController(text: food.foodName);
    _caloriesController = TextEditingController(text: food.calories.round().toString());
    _proteinController = TextEditingController(text: food.protein.toStringAsFixed(1));
    _carbsController = TextEditingController(text: food.carbs.toStringAsFixed(1));
    _fatController = TextEditingController(text: food.fat.toStringAsFixed(1));
    _mealType = widget.initialMealType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Analiz sonucu',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(widget.recognizedFood.source.label),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                      labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12),
                      side: BorderSide.none,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Yemek adı'),
                  style: const TextStyle(color: AppColors.textPrimary),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Zorunlu alan' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MealType>(
                  initialValue: _mealType,
                  dropdownColor: AppColors.surfaceElevated,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Öğün'),
                  items: MealType.values.map((m) => DropdownMenuItem(value: m, child: Text(m.label))).toList(),
                  onChanged: (value) => setState(() => _mealType = value!),
                ),
                const SizedBox(height: 12),
                _NumberField(controller: _caloriesController, label: 'Kalori (kcal)', requiredPositive: true),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _NumberField(controller: _proteinController, label: 'Protein')),
                    const SizedBox(width: 10),
                    Expanded(child: _NumberField(controller: _carbsController, label: 'Karb')),
                    const SizedBox(width: 10),
                    Expanded(child: _NumberField(controller: _fatController, label: 'Yağ')),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.pop(context, false),
                        child: const Text('İptal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        label: _saving ? 'Ekleniyor...' : 'Onayla ve Ekle',
                        onPressed: _saving ? null : _confirm,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final food = widget.recognizedFood.copyWith(
      foodName: _nameController.text.trim(),
      calories: double.parse(_caloriesController.text),
      protein: double.tryParse(_proteinController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      fat: double.tryParse(_fatController.text) ?? 0,
    );
    await widget.onConfirm(food, _mealType);
    if (!mounted) return;
    Navigator.pop(context, true);
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    this.requiredPositive = false,
  });

  final TextEditingController controller;
  final String label;
  final bool requiredPositive;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: AppColors.textPrimary),
      validator: (value) {
        final parsed = double.tryParse(value ?? '');
        if (requiredPositive && (parsed == null || parsed <= 0)) return 'Geçersiz';
        if (!requiredPositive && value != null && value.isNotEmpty && parsed == null) return 'Geçersiz';
        return null;
      },
    );
  }
}
