import 'dart:io';
import 'package:attendance_face_recognition/screens/admin/attendance_history/detailattendance.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:open_file/open_file.dart';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  final bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("List Kehadiran Karyawan"),
        leading: BackButton(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchKeyword = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari nama karyawan',
                suffixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                hintStyle: TextStyle(fontSize: 13),
              ),
            ),
          ),
          const Text(
            "Data yang diambil adalah 1 bulan terakhir.",
            style: TextStyle(fontSize: 12),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'karyawan')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  final name = doc['name'].toString().toLowerCase();
                  return name.contains(_searchKeyword);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada karyawan ditemukan.'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final user = filteredDocs[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailAttendanceScreen(
                              userId: user['id'],
                              userName: user['name'],
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(
                            12,
                          ), // Tambahkan padding agar lebih lega
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Konten Kiri (Nama, Departemen, Email)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['name'],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Departemen : ${user['departement']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Email : ${user['email']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),

                              // Tombol Export File di Kanan
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.download),
                                    onPressed: () {
                                      final userData =
                                          user.data() as Map<String, dynamic>;
                                      userData['id'] = user.id;
                                      exportFile(context, userData);
                                    },
                                  ),
                                  const Text(
                                    "Export File",
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isExporting)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Future<void> exportFile(
    BuildContext context,
    Map<String, dynamic> user,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uid = user['id'];
      final nik = user['nik'];
      final name = user['name'];
      final department = user['departement'];
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 1, now.day);

      final snapshot = await FirebaseFirestore.instance
          .collection('absensi')
          .where('user_id', isEqualTo: uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('date')
          .get();

      if (snapshot.docs.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data absensi ditemukan')),
        );
        return;
      }

      // Buat map pairing masuk & keluar berdasarkan tanggal
      Map<String, Map<String, String>> dailyAbsensi = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final time = (data['time'] as Timestamp).toDate();
        final type = data['type'];
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        dailyAbsensi.putIfAbsent(
          dateKey,
          () => {
            'tanggal': DateFormat('dd/MM/yyyy').format(date),
            'hari': DateFormat('EEEE', 'id_ID').format(time),
            'masuk': '',
            'keluar': '',
            'bulan': DateFormat('MMMM yyyy', 'id_ID').format(time),
          },
        );

        if (type == 'absen_masuk') {
          dailyAbsensi[dateKey]!['masuk'] = DateFormat('HH:mm').format(time);
        } else if (type == 'absen_keluar') {
          dailyAbsensi[dateKey]!['keluar'] = DateFormat('HH:mm').format(time);
        }
      }

      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      sheet.appendRow([
        TextCellValue('NIK'),
        TextCellValue('Nama'),
        TextCellValue('Departemen'),
        TextCellValue('Tanggal'),
        TextCellValue('Hari'),
        TextCellValue('Scan Masuk'),
        TextCellValue('Scan Keluar'),
        TextCellValue('Bulan'),
      ]);

      dailyAbsensi.forEach((key, data) {
        sheet.appendRow([
          TextCellValue(nik),
          TextCellValue(name),
          TextCellValue(department),
          TextCellValue(data['tanggal'] ?? ''),
          TextCellValue(data['hari'] ?? ''),
          TextCellValue(data['masuk'] ?? ''),
          TextCellValue(data['keluar'] ?? ''),
          TextCellValue(data['bulan'] ?? ''),
        ]);
      });

      final directory = Directory('/storage/emulated/0/Download');
      final filePath =
          '${directory.path}/absensi_${name.replaceAll(" ", "_")}_$nik.xlsx';
      final fileBytes = excel.encode();

      if (fileBytes != null) {
        final file = File(filePath)..createSync(recursive: true);
        file.writeAsBytesSync(fileBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File berhasil disimpan di: $filePath')),
        );
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        await OpenFile.open(filePath);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengekspor: $e')));
    } finally {}
  }
}
