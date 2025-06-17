import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyDetailAttendanceScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const MyDetailAttendanceScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  Future<List<Map<String, dynamic>>> getAttendanceStream() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - 1, now.day);
    final snapshot = await FirebaseFirestore.instance
        .collection('absensi')
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('date')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Kehadiran"),
        leading: BackButton(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Center(
              child: Text(
                userName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: getAttendanceStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Terjadi kesalahan: ${snapshot.error}'),
                  );
                }

                final listAbsensi = snapshot.data ?? [];

                if (listAbsensi.isEmpty) {
                  return const Center(child: Text('Belum ada data absensi.'));
                }

                return ListView.builder(
                  itemCount: listAbsensi.length,
                  itemBuilder: (context, index) {
                    final data = listAbsensi[index];
                    final type = data['type'] == 'absen_masuk'
                        ? 'Absen Masuk'
                        : 'Absen Keluar';
                    ;
                    final time = (data['time'] as Timestamp).toDate();
                    final formattedDate = DateFormat(
                      'dd MMM yyyy',
                      'id_ID',
                    ).format(time);
                    final formattedTime = DateFormat('HH:mm').format(time);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Text(
                              type,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        subtitle: Text(
                          "$formattedDate\n$formattedTime",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
