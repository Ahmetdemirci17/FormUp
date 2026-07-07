import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/daily_stats.dart';
import '../providers/statistics_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/layered_card.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(statisticsRangeProvider);
    final chartAsync = ref.watch(statisticsChartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('İstatistikler')),
      body: chartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Hata: $e', style: const TextStyle(color: Colors.red))),
        data: (data) {
          final points = data.points;
          if (points.isEmpty || points.every((point) => point.consumed == 0)) {
            return Center(
              child: Text(
                'Henüz veri yok',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _RangeSegmentedControl(
                range: range,
                onChanged: (value) => ref.read(statisticsRangeProvider.notifier).state = value,
              ),
              const SizedBox(height: 18),
              if (data.weightProjectionText != null) ...[
                LayeredCard(
                  child: Row(
                    children: [
                      const Icon(Icons.timeline_rounded, color: AppColors.success),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data.weightProjectionText!,
                          style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              _ChartPanel(
                title: 'Kalori ve hedef',
                child: _CalorieLineChart(points: points, range: range),
              ),
              const SizedBox(height: 18),
              _ChartPanel(
                title: 'Öğün katkısı',
                child: _MealStackedBarChart(points: points, range: range),
              ),
              const SizedBox(height: 18),
              _ChartPanel(
                title: 'Makro oran trendi',
                child: _MacroAreaChart(points: points, range: range),
              ),
              const SizedBox(height: 14),
              const Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _LegendDot(color: AppColors.primary, label: 'Tüketilen'),
                  _LegendDot(color: AppColors.textSecondary, label: 'Hedef'),
                  _LegendDot(color: AppColors.success, label: 'Protein'),
                  _LegendDot(color: AppColors.warning, label: 'Karb'),
                  _LegendDot(color: AppColors.primaryLight, label: 'Yağ'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RangeSegmentedControl extends StatelessWidget {
  const _RangeSegmentedControl({required this.range, required this.onChanged});

  final int range;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final item in const [(7, '7 Gün'), (30, '30 Gün'), (90, '90 Gün')])
            Expanded(
              child: _SegmentButton(
                label: item.$2,
                selected: range == item.$1,
                onTap: () => onChanged(item.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayeredCard(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(height: 260, child: child),
        ],
      ),
    );
  }
}

class _CalorieLineChart extends StatelessWidget {
  const _CalorieLineChart({required this.points, required this.range});

  final List<DayCaloriePoint> points;
  final int range;

  @override
  Widget build(BuildContext context) {
    final maxY = points.map((p) => max(p.consumed, p.quota)).reduce(max) * 1.18;
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY <= 0 ? 100 : maxY,
        gridData: _gridData(),
        titlesData: _titlesData(points, range),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final index = spot.x.toInt().clamp(0, points.length - 1);
              final point = points[index];
              final diff = point.consumed - point.quota;
              return LineTooltipItem(
                '${_shortDate(point.date)}\n${point.consumed.round()} kcal\nHedef ${point.quota.round()}\nFark ${diff.round()}',
                GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 11),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].consumed)],
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: FlDotData(show: range == 7),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [AppColors.primary.withValues(alpha: 0.24), AppColors.primary.withValues(alpha: 0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          LineChartBarData(
            spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].quota)],
            isCurved: false,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            barWidth: 2,
            dashArray: [8, 5],
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
    );
  }
}

class _MealStackedBarChart extends StatelessWidget {
  const _MealStackedBarChart({required this.points, required this.range});

  final List<DayCaloriePoint> points;
  final int range;

  @override
  Widget build(BuildContext context) {
    final maxY = points.map((p) => max(p.consumed, p.quota)).reduce(max) * 1.2;
    final interval = max(1, points.length / (range == 7 ? 7 : 6)).ceil();
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY <= 0 ? 100 : maxY,
        gridData: _gridData(),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final point = points[group.x.toInt().clamp(0, points.length - 1)];
              return BarTooltipItem(
                '${_shortDate(point.date)}\nKahvaltı ${point.breakfast.round()}\nÖğle ${point.lunch.round()}\nAkşam ${point.dinner.round()}\nAra ${point.snack.round()}',
                GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 11),
              );
            },
          ),
        ),
        titlesData: _titlesData(points, range, bottomInterval: interval.toDouble()),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].consumed,
                  width: range == 7 ? 18 : 7,
                  borderRadius: BorderRadius.circular(4),
                  rodStackItems: _stackItems(points[i]),
                ),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
    );
  }

  List<BarChartRodStackItem> _stackItems(DayCaloriePoint point) {
    var from = 0.0;
    BarChartRodStackItem item(double value, Color color) {
      final stack = BarChartRodStackItem(from, from + value, color);
      from += value;
      return stack;
    }

    return [
      item(point.breakfast, AppColors.primary),
      item(point.lunch, AppColors.warning),
      item(point.dinner, AppColors.primaryLight),
      item(point.snack, AppColors.success),
    ];
  }
}

class _MacroAreaChart extends StatelessWidget {
  const _MacroAreaChart({required this.points, required this.range});

  final List<DayCaloriePoint> points;
  final int range;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: _gridData(),
        borderData: FlBorderData(show: false),
        titlesData: _titlesData(points, range, leftSuffix: '%'),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final index = spot.x.toInt().clamp(0, points.length - 1);
              final point = points[index];
              return LineTooltipItem(
                '${_shortDate(point.date)}\nProtein ${point.proteinRatio.round()}%\nKarb ${point.carbsRatio.round()}%\nYağ ${point.fatRatio.round()}%',
                GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 11),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          _macroLine(points, (p) => p.proteinRatio, AppColors.success),
          _macroLine(points, (p) => p.carbsRatio, AppColors.warning),
          _macroLine(points, (p) => p.fatRatio, AppColors.primaryLight),
        ],
      ),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
    );
  }

  LineChartBarData _macroLine(List<DayCaloriePoint> points, double Function(DayCaloriePoint) value, Color color) {
    return LineChartBarData(
      spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), value(points[i]))],
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }
}

FlGridData _gridData() {
  return FlGridData(
    show: true,
    drawVerticalLine: false,
    getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
  );
}

FlTitlesData _titlesData(
  List<DayCaloriePoint> points,
  int range, {
  double? bottomInterval,
  String leftSuffix = '',
}) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 42,
        getTitlesWidget: (value, _) => Text(
          '${value.round()}$leftSuffix',
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
        ),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        interval: bottomInterval ?? (range == 7 ? 1 : range == 30 ? 5 : 15),
        getTitlesWidget: (value, _) {
          final index = value.toInt();
          if (index < 0 || index >= points.length) return const SizedBox.shrink();
          return Text(
            '${points[index].date.day}',
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
          );
        },
      ),
    ),
  );
}

String _shortDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
