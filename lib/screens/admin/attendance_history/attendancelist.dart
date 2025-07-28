import 'dart:io';
import 'package:attendance_face_recognition/screens/admin/attendance_history/detailattendance.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  final bool _isExporting = false;
  String _selectedDepartement = 'Semua';
  List<String> _departementList = ['Semua'];

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

  List<dynamic> _allList = [];
  List<dynamic> _filteredList = [];

  Future<void> fetchData() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    _allList = snapshot.docs.toList();
    setState(() {
      _filteredList = _allList;
    });
  }

  void _resetFilter() {
    setState(() {
      _searchKeyword = '';
      _searchController.clear();
      _selectedDepartement = 'Semua'; // atau "" jika tidak punya label default
    });
    fetchData();
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000; // in meters
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  Map<String, dynamic>? lokasiKantor;

  Future<void> getLokasiKantor() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('lokasi_absen')
        .limit(1) // ganti dengan ID lokasi jika perlu
        .get();

    if (snapshot.docs.isNotEmpty) {
      lokasiKantor = snapshot.docs.first.data(); // atau docs[0].data()
    }
  }

  @override
  void initState() {
    super.initState();
    getLokasiKantor();
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
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchKeyword = '';
                                });
                              },
                            )
                          : const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      hintStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      tooltip: 'Filter Departemen',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled:
                              true, // Penting untuk memberi ruang lebih
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          builder: (BuildContext context) {
                            return DraggableScrollableSheet(
                              expand: false,
                              initialChildSize: 0.5, // Tinggi awal
                              minChildSize: 0.3,
                              maxChildSize: 0.9,
                              builder: (_, controller) {
                                return ListView.builder(
                                  controller: controller,
                                  itemCount: _departementList.length,
                                  itemBuilder: (context, index) {
                                    final dept = _departementList[index];
                                    return ListTile(
                                      title: Text(dept),
                                      onTap: () {
                                        setState(() {
                                          _selectedDepartement = dept;
                                        });
                                        Navigator.pop(context);
                                      },
                                      selected: dept == _selectedDepartement,
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    Text(
                      _selectedDepartement,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
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
                  // .where('is_active', isEqualTo: true)
                  .orderBy("created_at", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var allDocs = snapshot.data!.docs;

                _departementList = ['Semua'];
                final harcodeDepartment = [
                  'Accounting',
                  'Engineering',
                  'HRD',
                  'MIS',
                  'Marketing',
                  'PPIC',
                  'Produksi',
                  'Purchasing',
                  'QA',
                  'Others',
                ];
                _departementList.addAll(
                  harcodeDepartment.map((e) => e).toSet().toList(),
                );

                var filteredDocs = allDocs.where((doc) {
                  final name = doc['name'].toString().toLowerCase();
                  final departement = doc['departement'].toString();
                  final matchesSearch = name.contains(_searchKeyword);
                  final matchesDept =
                      _selectedDepartement == 'Semua' ||
                      departement == _selectedDepartement;
                  return matchesSearch && matchesDept;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Karyawan yang Anda cari tidak ditemukan.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
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
                        ).then((_) {
                          _resetFilter(); // Reset filter setelah kembali
                        });
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
        final double latKantor =
            double.tryParse(lokasiKantor!['latitude'].toString()) ?? 0.0;
        final double longKantor =
            double.tryParse(lokasiKantor!['longitude'].toString()) ?? 0.0;

        final double latUser =
            double.tryParse(data['latitude'].toString()) ?? 0.0;
        final double longUser =
            double.tryParse(data['longitude'].toString()) ?? 0.0;

        final double radiusKantor =
            double.tryParse(lokasiKantor!['radius'].toString()) ?? 0.0;
        final double jarak = calculateDistance(
          latKantor,
          longKantor,
          latUser,
          longUser,
        );
        final bool diDalamKantor = jarak <= radiusKantor;
        rawAbsensi.add({
          'photo_url': data['photo_url'],
          'nik': data['nik'],
          'name': data['name'],
          'departement': data['departement'],
          'type': data['type'],
          'time': time,
          'tanggal': DateFormat('dd/MM/yyyy').format(time),
          'hari': DateFormat('EEEE', 'id_ID').format(time),
          'bulan': DateFormat('MMMM yyyy', 'id_ID').format(time),
          'posisi': diDalamKantor ? 'Dalam Kantor' : 'Luar Kantor',
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
        TextCellValue('URL Foto Absen'),
        TextCellValue('NIK'),
        TextCellValue('Nama'),
        TextCellValue('Departemen'),
        TextCellValue('Tanggal'),
        TextCellValue('Hari'),
        TextCellValue('Scan Masuk'),
        TextCellValue('Scan Keluar'),
        TextCellValue('Bulan'),
        TextCellValue('Posisi Absen Masuk'),
        TextCellValue('Posisi Absen Keluar'),
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
              TextCellValue('${records[i]['photo_url']}'),
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
              TextCellValue(masuk['posisi']),
              TextCellValue(keluar != null ? keluar['posisi'] : ''),
            ]);
          }
        }
      }
      final directory = await getApplicationDocumentsDirectory();
      DateTime currentTime = DateTime.now();
      String formattedDate = DateFormat(
        'MMMM yyyy',
        'id_ID',
      ).format(currentTime).splitMapJoin("_");
      final filePath =
          '${directory!.path}/absensi_all_${formattedDate}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
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
        final double latKantor =
            double.tryParse(lokasiKantor!['latitude'].toString()) ?? 0.0;
        final double longKantor =
            double.tryParse(lokasiKantor!['longitude'].toString()) ?? 0.0;

        final double latUser =
            double.tryParse(data['latitude'].toString()) ?? 0.0;
        final double longUser =
            double.tryParse(data['longitude'].toString()) ?? 0.0;

        final double radiusKantor =
            double.tryParse(lokasiKantor!['radius'].toString()) ?? 0.0;
        final double jarak = calculateDistance(
          latKantor,
          longKantor,
          latUser,
          longUser,
        );
        final bool diDalamKantor = jarak <= radiusKantor;
        rawAbsensi.add({
          'photo_url': data['photo_url'],
          'type': data['type'],
          'time': time,
          'tanggal': DateFormat('dd/MM/yyyy').format(time),
          'hari': DateFormat('EEEE', 'id_ID').format(time),
          'bulan': DateFormat('MMMM yyyy', 'id_ID').format(time),
          'posisi': diDalamKantor ? 'Dalam Kantor' : 'Luar Kantor',
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
        TextCellValue('URL Foto Absen'),
        TextCellValue('NIK'),
        TextCellValue('Nama'),
        TextCellValue('Departemen'),
        TextCellValue('Tanggal'),
        TextCellValue('Hari'),
        TextCellValue('Scan Masuk'),
        TextCellValue('Scan Keluar'),
        TextCellValue('Bulan'),
        TextCellValue('Posisi Absen Masuk'),
        TextCellValue('Posisi Absen Keluar'),
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
              TextCellValue('${records[i]['photo_url']}'),
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
              TextCellValue(masuk['posisi']),
              TextCellValue(keluar != null ? keluar['posisi'] : ''),
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
