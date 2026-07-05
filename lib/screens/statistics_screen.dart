import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/statistics_provider.dart';
import '../theme/app_colors.dart';

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
        data: (points) {
          if (points.isEmpty) {
            return Center(
              child: Text(
                'Henüz veri yok',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            );
          }

          final maxY = points
              .map((p) => p.consumed > p.quota ? p.consumed : p.quota)
              .reduce((a, b) => a > b ? a : b);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  _RangeChip(
                    label: '7 gün',
                    selected: range == 7,
                    onTap: () => ref.read(statisticsRangeProvider.notifier).state = 7,
                  ),
                  const SizedBox(width: 8),
                  _RangeChip(
                    label: '30 gün',
                    selected: range == 30,
                    onTap: () => ref.read(statisticsRangeProvider.notifier).state = 30,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 280,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxY * 1.15,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, _) => Text(
                            value.round().toString(),
                            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: range == 7 ? 1 : 5,
                          getTitlesWidget: (value, _) {
                            final index = value.toInt();
                            if (index < 0 || index >= points.length) return const SizedBox.shrink();
                            final day = points[index].date.day;
                            return Text(
                              '$day',
                              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < points.length; i++)
                            FlSpot(i.toDouble(), points[i].consumed),
                        ],
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: range == 7,
                          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.primary,
                            strokeWidth: 0,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.25),
                              AppColors.primary.withValues(alpha: 0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < points.length; i++)
                            FlSpot(i.toDouble(), points[i].quota),
                        ],
                        isCurved: false,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                        barWidth: 2,
                        dashArray: [6, 4],
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _LegendDot(color: AppColors.primary, label: 'Tüketilen'),
                  const SizedBox(width: 16),
                  _LegendDot(color: AppColors.textSecondary, label: 'Hedef kota'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
