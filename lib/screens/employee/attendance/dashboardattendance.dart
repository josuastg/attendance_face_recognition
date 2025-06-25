import 'dart:async';
import 'package:attendance_face_recognition/screens/employee/attendance/faceattendance.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboarAttendanceScreen extends StatefulWidget {
  const DashboarAttendanceScreen({super.key});

  @override
  State<DashboarAttendanceScreen> createState() =>
      _DashboarAttendanceScreenState();
}

class _DashboarAttendanceScreenState extends State<DashboarAttendanceScreen> {
  List<Map<String, dynamic>> todayAbsensi = [];
  bool isLoading = true;
  bool _blink = true;
  final user = FirebaseAuth.instance.currentUser;
  late Timer _blinkTimer;
  @override
  void initState() {
    super.initState();
    // Timer untuk blink
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _blink = !_blink;
      });
    });
    fetchTodayAbsensi();
  }

  @override
  void dispose() {
    _blinkTimer.cancel();
    super.dispose();
  }

  Future<void> fetchTodayAbsensi() async {
    try {
      if (user == null) return;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await FirebaseFirestore.instance
          .collection('absensi')
          .where('user_id', isEqualTo: user?.uid)
          .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('time', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('time')
          .get();

      final list = snapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        todayAbsensi = List<Map<String, dynamic>>.from(list);
        isLoading = false;
      });
    } catch (e) {
      print('🔥 Error fetching absensi: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildPresensiList() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (todayAbsensi.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Tidak ada log aktivitas hari ini',
            style: TextStyle(fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      children: todayAbsensi.map((absen) {
        final type = absen['type'] == 'absen_masuk'
            ? 'Absen Masuk'
            : 'Absen Keluar';
        final date = (absen['time'] as Timestamp).toDate();
        final formattedDate = DateFormat('dd MMM yyyy').format(date);
        final formattedTime = DateFormat('HH:mm').format(date);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5FB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Center(
                child: Text(
                  type,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.left,
              ),
              Text(
                formattedTime,
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeNow = DateFormat('HH:mm').format(now);
    final dateNow = DateFormat(
      'EEE, dd MMM yyyy',
      'id_ID',
    ).format(now); // gunakan 'id_ID'

    return Scaffold(
      appBar: AppBar(title: const Text("Live Attendance"), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black54),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    "LIVE\nATTENDANCE",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                    ), // beri ruang di bawah
                    child: AnimatedOpacity(
                      opacity: _blink ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 1000),
                      child: Text(
                        timeNow, // misalnya: 23:51
                        style: const TextStyle(
                          fontSize: 35, // cukup besar
                          fontWeight: FontWeight.bold,
                          height: 1.5, // jarak baris jika perlu
                        ),
                      ),
                    ),
                  ),
                  Text(dateNow, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  const Text("08:00 - 17:00", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FaceAttendanceScreen(
                                type: 'absen_masuk',// dari Firebase Auth
                              ),
                            ),
                          );
                          Navigator.pushNamed(context, '/faceattendance');
                        },
                        child: const Text("Absen Masuk"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FaceAttendanceScreen(
                                type: 'absen_keluar' // dari Firebase Auth
                              ),
                            ),
                          );
                        },
                        child: const Text("Absen Keluar"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black45),
                color: const Color(0xFFF9F9FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Riwayat Presensi",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  buildPresensiList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
