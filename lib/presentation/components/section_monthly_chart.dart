import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SectionMonthlyChart extends StatelessWidget {
  final List<DateTime> months; // first day of each month
  final Map<String, List<double>> series; // label -> values aligned to months
  final double height;

  const SectionMonthlyChart({
    super.key,
    required this.months,
    required this.series,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Ensure at least one series with zeros
    final Map<String, List<double>> safeSeries = series.isNotEmpty
        ? series
        : {
            'Sem dados': List<double>.filled(months.length, 0),
          };

    // Colors cycle
    final palette = <Color>[
      theme.colorScheme.primary,
      Colors.teal,
      Colors.deepPurple,
      Colors.orange,
      Colors.indigo,
      Colors.pink,
      Colors.brown,
    ];

    // Compute Y bounds
    final minY = 0.0;
    double maxY = 0.0;
    for (final v in safeSeries.values.expand((e) => e)) {
      if (v > maxY) maxY = v;
    }
    if (maxY <= 0) maxY = 1.0; // keep positive bounds to show axes even when zeros

    // Build grouped bar data: one group per month, one rod per series
    final labels = safeSeries.keys.toList();
    final valuesByLabel = safeSeries; // label -> list of values per month

    final barGroups = <BarChartGroupData>[];
    for (int monthIdx = 0; monthIdx < months.length; monthIdx++) {
      final rods = <BarChartRodData>[];
      for (int sIdx = 0; sIdx < labels.length; sIdx++) {
        final label = labels[sIdx];
        final values = valuesByLabel[label] ?? const <double>[];
        final y = monthIdx < values.length ? (values[monthIdx]) : 0.0;
        rods.add(
          BarChartRodData(
            toY: y,
            color: palette[sIdx % palette.length],
            width: 10,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }
      barGroups.add(
        BarChartGroupData(
          x: monthIdx,
          barsSpace: 6,
          barRods: rods,
        ),
      );
    }

    // Integer tick step for Y axis
    final double yInterval = () {
      final step = (maxY / 5).ceil();
      return step <= 0 ? 1.0 : step.toDouble();
    }();

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          minY: minY,
          maxY: (maxY + yInterval), // add headroom
          gridData: FlGridData(show: true, horizontalInterval: yInterval),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  // Show only integer labels
                  final intVal = value.round();
                  if ((value - intVal).abs() > 1e-6) {
                    return const SizedBox.shrink();
                  }
                  if (intVal < 0) return const SizedBox.shrink();
                  return Text('$intVal', style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= months.length) return const SizedBox.shrink();
                  final m = months[i];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '${m.month.toString().padLeft(2, '0')}/${m.year % 100}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          barGroups: barGroups,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = labels[rodIndex];
                final m = months[group.x.toInt()];
                final y = rod.toY;
                return BarTooltipItem(
                  '$label\n${m.month.toString().padLeft(2, '0')}/${m.year}: ${y.toStringAsFixed(0)}',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
