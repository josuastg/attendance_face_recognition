import 'package:attendance_face_recognition/screens/admin/attendance_history/detailattendance.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardSection2 extends StatefulWidget {
  const DashboardSection2({super.key});

  @override
  State<DashboardSection2> createState() => _DashboardSection2State();
}

class _DashboardSection2State extends State<DashboardSection2> {
  String selectedFilter = 'Absen'; // Default filter
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> allKaryawan = [];
  Set<String> userIdsYangSudahAbsen = {};

  @override
  void initState() {
    super.initState();
    fetchData();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    final karyawanSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'karyawan')
        .get();

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final absensiSnapshot = await FirebaseFirestore.instance
        .collection('absensi')
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('time', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    final absenUserIds = absensiSnapshot.docs
        .map((doc) => doc['user_id'].toString())
        .toSet();

    final karyawanData = karyawanSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    setState(() {
      allKaryawan = karyawanData;
      userIdsYangSudahAbsen = absenUserIds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredKaryawan = allKaryawan.where((karyawan) {
      final id = karyawan['id'];
      final cocokFilter = selectedFilter == 'Absen'
          ? userIdsYangSudahAbsen.contains(id)
          : !userIdsYangSudahAbsen.contains(id);

      final cocokSearch =
          karyawan['name'] != null &&
          karyawan['name'].toString().toLowerCase().contains(searchQuery);

      return cocokFilter && cocokSearch;
    }).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Status Kehadiran Karyawan Hari Ini",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedFilter,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'Absen',
                  child: Text(
                    'Sudah Absen Masuk',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Belum Absen',
                  child: Text(
                    'Belum Absen Masuk',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedFilter = value;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama karyawan...',
                suffixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: filteredKaryawan.length < 5
                  ? filteredKaryawan.length * 70
                  : 300, // atau coba 350 jika masih terlalu pendek
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  itemCount: filteredKaryawan.length,
                  itemBuilder: (context, index) {
                    final karyawan = filteredKaryawan[index];
                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailAttendanceScreen(
                              userId: karyawan['id'],
                              userName: karyawan['name'],
                            ),
                          ),
                        );
                      },
                      title: Text(
                        karyawan['name']?.toString().toUpperCase() ??
                            'Tanpa Nama',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "${karyawan['departement'] ?? '-'}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      leading:
                          karyawan['photo_url'] != null &&
                              karyawan['photo_url'].isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(
                                karyawan['photo_url'][0],
                              ),
                              backgroundColor: Colors.grey[200],
                              onBackgroundImageError: (_, __) {},
                            )
                          : CircleAvatar(
                              child: Text(
                                (karyawan['name']?.isNotEmpty == true)
                                    ? karyawan['name'][0].toUpperCase()
                                    : '?',
                              ),
                            ),
                      trailing: Icon(
                        selectedFilter == 'Absen'
                            ? Icons.check_circle
                            : Icons.cancel_outlined,
                        color: selectedFilter == 'Absen'
                            ? Colors.green[500]
                            : Colors.red[500],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
