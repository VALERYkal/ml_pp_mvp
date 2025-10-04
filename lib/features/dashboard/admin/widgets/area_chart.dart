import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../providers/admin_trends_provider.dart';

class AreaChart extends StatelessWidget {
  final List<DayPoint> points;
  const AreaChart({super.key, required this.points});

  // Helper pour formater les volumes intelligemment
  String _formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(0)} 000 L';
    }
    return '${volume.toStringAsFixed(0)} L';
  }

  // Helper pour calculer la variation jour/jour
  double? _getVariation(int index, bool isReceptions) {
    if (index <= 0) return null;
    final current = isReceptions ? points[index].rec : points[index].sort;
    final previous = isReceptions ? points[index - 1].rec : points[index - 1].sort;
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous * 100);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spotsRec = <FlSpot>[];
    final spotsSort = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spotsRec.add(FlSpot(i.toDouble(), points[i].rec));
      spotsSort.add(FlSpot(i.toDouble(), points[i].sort));
    }
    return Column(
      children: [
        // Légende
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Réceptions', theme.colorScheme.primary),
              const SizedBox(width: 24),
              _buildLegendItem('Sorties', theme.colorScheme.secondary),
            ],
          ),
        ),
        // Graphique
        Expanded(
          child: LineChart(
            LineChartData(
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: theme.dividerColor.withOpacity(0.3), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(_formatVolume(value), style: theme.textTheme.labelSmall),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i >= points.length) return const SizedBox.shrink();
                      final d = points[i].day;
                      return Text('${d.day}/${d.month}', style: theme.textTheme.labelSmall);
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  spots: spotsRec,
                  barWidth: 3,
                  belowBarData: BarAreaData(
                    show: true,
                    cutOffY: 0,
                    applyCutOffY: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.3),
                        theme.colorScheme.primary.withOpacity(0.1),
                      ],
                    ),
                  ),
                  color: theme.colorScheme.primary,
                ),
                LineChartBarData(
                  isCurved: true,
                  spots: spotsSort,
                  barWidth: 3,
                  belowBarData: BarAreaData(
                    show: true,
                    cutOffY: 0,
                    applyCutOffY: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.secondary.withOpacity(0.3),
                        theme.colorScheme.secondary.withOpacity(0.1),
                      ],
                    ),
                  ),
                  color: theme.colorScheme.secondary,
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: theme.colorScheme.surface,
                  tooltipBorder: BorderSide(color: theme.dividerColor),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((s) {
                      final i = s.x.toInt();
                      final d = points[i].day;
                      final isReceptions = s.barIndex == 0;
                      final label = isReceptions ? 'Réceptions' : 'Sorties';
                      final volume = _formatVolume(s.y);
                      final variation = _getVariation(i, isReceptions);

                      String tooltipText = '$label\n${d.day}/${d.month} : $volume';
                      if (variation != null) {
                        final variationText = variation >= 0
                            ? '+${variation.toStringAsFixed(1)}%'
                            : '${variation.toStringAsFixed(1)}%';
                        final variationColor = variation >= 0 ? Colors.green : Colors.red;
                        tooltipText += '\nVar: $variationText';
                      }

                      return LineTooltipItem(
                        tooltipText,
                        TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget pour construire les éléments de légende
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
