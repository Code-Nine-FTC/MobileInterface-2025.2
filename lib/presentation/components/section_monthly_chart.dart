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

    final minY = 0.0;
    double maxY = 0.0;
    for (final v in safeSeries.values.expand((e) => e)) {
      if (v > maxY) maxY = v;
    }
    if (maxY <= 0) maxY = 1.0; // keep positive bounds to show the grid/axes even when zeros

    final spotsByLabel = <String, List<FlSpot>>{};
    for (final entry in safeSeries.entries) {
      final values = entry.value;
      final spots = <FlSpot>[];
      for (int i = 0; i < months.length; i++) {
        final y = i < values.length ? values[i] : 0.0;
        spots.add(FlSpot(i.toDouble(), y));
      }
      spotsByLabel[entry.key] = spots;
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY * 1.2,
          gridData: FlGridData(show: true, horizontalInterval: maxY / 4),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
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
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((s) {
                  final label = spotsByLabel.keys.elementAt(spots.indexOf(s));
                  final i = s.x.toInt();
                  final m = months[i];
                  return LineTooltipItem(
                    '$label\n${m.month.toString().padLeft(2, '0')}/${m.year}: ${s.y.toStringAsFixed(0)}',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            for (int idx = 0; idx < spotsByLabel.length; idx++)
              LineChartBarData(
                isCurved: false,
                color: palette[idx % palette.length],
                barWidth: 2,
                dotData: FlDotData(show: false),
                spots: spotsByLabel.values.elementAt(idx),
              ),
          ],
          // Keep space even if only zeros
          clipData: const FlClipData.all(),
        ),
      ),
    );
  }
}
