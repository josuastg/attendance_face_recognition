import 'dart:io';
import 'package:attendance_face_recognition/screens/admin/attendance_history/detailattendance.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  final bool _isExporting = false;

  Widget buildAvatar(user) {
    final List<dynamic>? photoUrls = user['photo_url'];
    final bool hasPhoto = photoUrls != null && photoUrls.isNotEmpty;
    if (hasPhoto) {
      return ClipOval(
        child: Image.network(
          photoUrls[0],
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ Gagal load foto: $error');
            return const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            );
          },
        ),
      );
    } else {
      return const CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      );
    }
  }

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
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // agar sejajar di atas
              children: [
                // TextField diperlebar agar fleksibel
                Expanded(
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
                const SizedBox(
                  width: 5,
                ), // jarak antara TextField dan tombol download
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () {
                        exportAllFile(context); // panggil fungsi export
                      },
                    ),
                    const Text("Export All", style: TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
          ),

          const Text(
            "Data yang diambil adalah 1 bulan terakhir.",
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 5),
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
                              // 👉 Avatar Karyawan (Foto dari photo_url[0])
                              buildAvatar(user), // 👈 panggil fungsi avatar
                              const SizedBox(width: 12),

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
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    Text(
                                      'Email : ${user['email']}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),

                              // Tombol Export File di Kanan
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
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
                                    style: TextStyle(fontSize: 8),
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

  Future<void> exportAllFile(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // final uid = user['id'];

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 1, now.day);

      final snapshot = await FirebaseFirestore.instance
          .collection('absensi')
          .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('time', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('time')
          .get();

      if (snapshot.docs.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data absensi ditemukan')),
        );
        return;
      }

      // final excel = Excel.createExcel();
      // final sheet = excel['Sheet1'];

      // Buat map pairing masuk & keluar berdasarkan tanggal
      final rawAbsensi = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        // print(data);
        final time = (data['time'] as Timestamp).toDate();
        rawAbsensi.add({
          'nik': data['nik'],
          'name': data['name'],
          'departement': data['departement'],
          'type': data['type'],
          'time': time,
          'tanggal': DateFormat('dd/MM/yyyy').format(time),
          'hari': DateFormat('EEEE', 'id_ID').format(time),
          'bulan': DateFormat('MMMM yyyy', 'id_ID').format(time),
          'lokasi': '${data['latitude']}, ${data['longitude']}',
        });
      }

      // Kelompokkan berdasarkan tanggal
      final groupedByDate = <String, List<Map<String, dynamic>>>{};
      for (var item in rawAbsensi) {
        final key = item['tanggal'];
        // print(key);
        groupedByDate.putIfAbsent(key, () => []).add(item);
      }

      // Buat row untuk Excel
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
        TextCellValue('Lokasi Absen Masuk (Latitude, Longitude)'),
        TextCellValue('Lokasi Absen Keluar (Latitude, Longitude)'),
      ]);

      for (var entry in groupedByDate.entries) {
        final tanggal = entry.key;
        final records = entry.value;

        // Urutkan berdasarkan waktu
        records.sort(
          (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime),
        );

        for (int i = 0; i < records.length; i++) {
          // print('ssss');
          // print(records[i]['nik']);
          if (records[i]['type'] == 'absen_masuk') {
            final masuk = records[i];
            Map<String, dynamic>? keluar;
            if (i + 1 < records.length &&
                records[i + 1]['type'] == 'absen_keluar') {
              keluar = records[i + 1];
              i++; // skip next karena sudah dipakai
            }
            sheet.appendRow([
              TextCellValue(records[i]['nik']),
              TextCellValue(records[i]['name']),
              TextCellValue(records[i]['departement']),
              TextCellValue(tanggal),
              TextCellValue(masuk['hari']),
              TextCellValue(DateFormat('HH:mm').format(masuk['time'])),
              TextCellValue(
                keluar != null
                    ? DateFormat('HH:mm').format(keluar['time'])
                    : '',
              ),
              TextCellValue(masuk['bulan']),
              TextCellValue(masuk['lokasi']),
              TextCellValue(keluar != null ? keluar['lokasi'] : ''),
            ]);
          }
        }
      }
      final directory = await getExternalStorageDirectory(); // lebih aman
      DateTime currentTime = DateTime.now();
      String formattedDate = DateFormat(
        'MMMM yyyy',
        'id_ID',
      ).format(currentTime).splitMapJoin("_");
      final filePath =
          '${directory!.path}/absensi_all_${formattedDate}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      print('test $filePath');
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
    } finally {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
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
          .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('time', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('time')
          .get();

      if (snapshot.docs.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data absensi ditemukan')),
        );
        return;
      }

      // final excel = Excel.createExcel();
      // final sheet = excel['Sheet1'];

      // Buat map pairing masuk & keluar berdasarkan tanggal
      final rawAbsensi = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final time = (data['time'] as Timestamp).toDate();
        rawAbsensi.add({
          'type': data['type'],
          'time': time,
          'tanggal': DateFormat('dd/MM/yyyy').format(time),
          'hari': DateFormat('EEEE', 'id_ID').format(time),
          'bulan': DateFormat('MMMM yyyy', 'id_ID').format(time),
          'lokasi': '${data['latitude']}, ${data['longitude']}',
        });
      }

      // Kelompokkan berdasarkan tanggal
      final groupedByDate = <String, List<Map<String, dynamic>>>{};
      for (var item in rawAbsensi) {
        final key = item['tanggal'];
        groupedByDate.putIfAbsent(key, () => []).add(item);
      }

      // Buat row untuk Excel
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
        TextCellValue('Lokasi Absen Masuk (Latitude, Longitude)'),
        TextCellValue('Lokasi Absen Keluar (Latitude, Longitude)'),
      ]);

      for (var entry in groupedByDate.entries) {
        final tanggal = entry.key;
        final records = entry.value;

        // Urutkan berdasarkan waktu
        records.sort(
          (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime),
        );

        for (int i = 0; i < records.length; i++) {
          if (records[i]['type'] == 'absen_masuk') {
            final masuk = records[i];
            Map<String, dynamic>? keluar;
            if (i + 1 < records.length &&
                records[i + 1]['type'] == 'absen_keluar') {
              keluar = records[i + 1];
              i++; // skip next karena sudah dipakai
            }

            sheet.appendRow([
              TextCellValue(nik),
              TextCellValue(name),
              TextCellValue(department),
              TextCellValue(tanggal),
              TextCellValue(masuk['hari']),
              TextCellValue(DateFormat('HH:mm').format(masuk['time'])),
              TextCellValue(
                keluar != null
                    ? DateFormat('HH:mm').format(keluar['time'])
                    : '',
              ),
              TextCellValue(masuk['bulan']),
              TextCellValue(masuk['lokasi']),
              TextCellValue(keluar != null ? keluar['lokasi'] : ''),
            ]);
          }
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/absensi_${name.replaceAll(" ", "_")}_$nik${DateTime.now().millisecondsSinceEpoch}.xlsx';
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
