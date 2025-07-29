import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardSection1 extends StatefulWidget {
  const DashboardSection1({super.key});

  @override
  State<DashboardSection1> createState() => _DashboardSection1State();
}

class _DashboardSection1State extends State<DashboardSection1> {
  int totalKaryawan = 0;
  int sudahAbsen = 0;
  int belumAbsen = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(
      now.year,
      now.month,
      now.day + 1,
    ); // jam 00:00 besok

    // Ambil semua user dengan role karyawan
    final karyawanSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'karyawan')
        .get();

    // Ambil semua absen hari ini berdasarkan timestamp time
    final absensiSnapshot = await FirebaseFirestore.instance
        .collection('absensi')
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('time', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    // Ambil user_id dari absensi hari ini
    final userIdsYangSudahAbsen = absensiSnapshot.docs
        .map((doc) => doc['user_id'])
        .toSet();

    // Hitung yang sudah absen dan yang belum
    final total = karyawanSnapshot.docs.length;
    final sudah = karyawanSnapshot.docs
        .where((doc) => userIdsYangSudahAbsen.contains(doc.id))
        .length;
    final belum = total - sudah;

    setState(() {
      totalKaryawan = total;
      sudahAbsen = sudah;
      belumAbsen = belum;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tanggalHariIni = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            const Text(
              "Total Karyawan",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text("$totalKaryawan Orang", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            const Divider(thickness: 1),
            const SizedBox(height: 12),
            // Tambahan tanggal
            Text(
              'Statistik Kehadiran Hari Ini ($tanggalHariIni)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.5,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: Colors.green[500],
                      value: sudahAbsen.toDouble(),
                      title: 'Hadir\n$sudahAbsen',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.red[500],
                      value: belumAbsen.toDouble(),
                      title: 'Belum\n$belumAbsen',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Keterangan:",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "• Hadir: Karyawan yang sudah melakukan absensi masuk hari ini.",
              style: TextStyle(fontSize: 13),
            ),
            const Text(
              "• Belum: Karyawan yang belum melakukan absensi masuk hari ini.",
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
