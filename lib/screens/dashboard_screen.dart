import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/activity_entry.dart';
import '../models/food_entry.dart';
import '../providers/activity_provider.dart';
import '../providers/daily_stats_provider.dart';
import '../providers/food_provider.dart';
import '../providers/insight_provider.dart';
import '../providers/refresh_provider.dart';
import '../services/database_helper.dart';
import '../theme/app_colors.dart';
import '../utils/page_transitions.dart';
import '../widgets/animated_counter.dart';
import '../widgets/circular_progress_ring.dart';
import '../widgets/empty_state.dart';
import '../widgets/layered_card.dart';
import '../widgets/macro_card.dart';
import 'add_activity_screen.dart';
import 'add_food_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final statsAsync = ref.watch(dailyStatsProvider(date));
    final foodsAsync = ref.watch(foodsByDateProvider(date));
    final activitiesAsync = ref.watch(activitiesByDateProvider(date));
    final insightsAsync = ref.watch(insightMessagesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Text('Hata: $e', style: const TextStyle(color: Colors.red))),
          data: (stats) => RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => bumpRefresh(ref),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bugün',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              _formatDate(date),
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: date,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              ref.read(selectedDateProvider.notifier).state = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                              );
                            }
                          },
                          icon: const Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressRing(
                        progress: stats.progress,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedCounter(value: stats.consumed),
                            Text(
                              '/ ${stats.effectiveQuota.round()} kcal',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            if (stats.burned > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                '+${stats.burned.round()} yakıldı',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.success),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        MacroCard(label: 'Protein', value: stats.protein, unit: 'g', color: AppColors.primary),
                        const SizedBox(width: 12),
                        MacroCard(label: 'Karb', value: stats.carbs, unit: 'g', color: AppColors.primaryLight),
                        const SizedBox(width: 12),
                        MacroCard(label: 'Yağ', value: stats.fat, unit: 'g', color: AppColors.primaryDark),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _InsightsSection(
                    insightsAsync: insightsAsync,
                    onRefresh: () => refreshInsights(ref),
                  ),
                ),
                const SliverToBoxAdapter(child: SectionTitle(title: 'Öğünler')),
                foodsAsync.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(child: Text('Hata: $e')),
                  data: (foods) {
                    if (foods.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.restaurant_rounded,
                          title: 'Henüz yemek eklenmedi',
                          subtitle: 'Bugün tükettiğin yemekleri ekleyerek kalori takibine başla.',
                          actionLabel: 'Yemek Ekle',
                          onAction: () => _openAddFood(context),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _AnimatedListTile(
                          index: index,
                          child: _FoodTile(
                            entry: foods[index],
                            onDelete: () async {
                              await DatabaseHelper.instance.deleteFood(foods[index].id!);
                              bumpRefresh(ref);
                            },
                          ),
                        ),
                        childCount: foods.length,
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SectionTitle(title: 'Aktiviteler')),
                activitiesAsync.when(
                  loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (e, _) => SliverToBoxAdapter(child: Text('Hata: $e')),
                  data: (activities) {
                    if (activities.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: LayeredCard(
                            child: Row(
                              children: [
                                const Icon(Icons.directions_run_rounded, color: AppColors.textSecondary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Aktivite ekleyerek kotanı artır',
                                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _openAddActivity(context),
                                  child: const Text('Ekle'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _AnimatedListTile(
                          index: index,
                          child: _ActivityTile(
                            entry: activities[index],
                            onDelete: () async {
                              await DatabaseHelper.instance.deleteActivity(activities[index].id!);
                              bumpRefresh(ref);
                            },
                          ),
                        ),
                        childCount: activities.length,
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.restaurant_rounded, color: AppColors.primary),
                title: const Text('Yemek Ekle', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _openAddFood(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.directions_run_rounded, color: AppColors.primary),
                title: const Text('Aktivite Ekle', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _openAddActivity(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddFood(BuildContext context) {
    Navigator.of(context).push(fadeSlideRoute(const AddFoodScreen()));
  }

  void _openAddActivity(BuildContext context) {
    Navigator.of(context).push(fadeSlideRoute(const AddActivityScreen()));
  }
}

class _AnimatedListTile extends StatelessWidget {
  const _AnimatedListTile({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 50),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.entry, required this.onDelete});
  final FoodEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: LayeredCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(
                    '${entry.mealType.label} · ${entry.calories.round()} kcal',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.entry, required this.onDelete});
  final ActivityEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: LayeredCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.type.label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(
                    '${entry.durationMinutes} dk · +${entry.caloriesBurned.round()} kcal',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.success),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}


class _InsightsSection extends StatelessWidget {
  const _InsightsSection({required this.insightsAsync, required this.onRefresh});

  final AsyncValue<List<dynamic>> insightsAsync;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'İçgörüler',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Yenile',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
              ),
            ],
          ),
          insightsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(color: AppColors.primary),
            ),
            error: (_, _) => const _InsightFallbackCard(),
            data: (insights) {
              if (insights.isEmpty) return const _InsightFallbackCard();
              return SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: insights.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final insight = insights[index];
                    return SizedBox(
                      width: 270,
                      child: LayeredCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: insight.type.color.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(insight.type.icon, color: insight.type.color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                insight.text,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InsightFallbackCard extends StatelessWidget {
  const _InsightFallbackCard();

  @override
  Widget build(BuildContext context) {
    return LayeredCard(
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Daha net öneriler için birkaç günlük yemek kaydı ekle.',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
