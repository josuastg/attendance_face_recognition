import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DetailPerDivisiScreen extends StatelessWidget {
  final Map<String, int> dataPerDepartemen = {
    'Accounting': 8,
    'Engineering': 12,
    'HRD': 5,
    'MIS': 7,
    'Marketing': 10,
    'PPIC': 6,
    'Produksi': 15,
    'Purchasing': 4,
    'QA': 5,
    'Others': 3,
  };

  @override
  Widget build(BuildContext context) {
    final List<BarChartGroupData> barGroups = [];
    int index = 0;
    dataPerDepartemen.forEach((departemen, jumlah) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: jumlah.toDouble(),
              color: Colors.blue,
              width: 18,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      );
      index++;
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Jumlah Karyawan per Divisi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Distribusi Karyawan Berdasarkan Divisi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        reservedSize: 28,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < dataPerDepartemen.keys.length) {
                            final departemen = dataPerDepartemen.keys.elementAt(
                              index,
                            );
                            return SideTitleWidget(
                              meta: meta,
                              child: Transform.rotate(
                                angle: -0.6,
                                child: Text(
                                  departemen,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                  gridData: FlGridData(show: false),
                  barTouchData: BarTouchData(enabled: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
