import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ListLokasiAbsenScreen extends StatefulWidget {
  const ListLokasiAbsenScreen({Key? key}) : super(key: key);

  @override
  State<ListLokasiAbsenScreen> createState() => _ListLokasiAbsenScreenState();
}

class _ListLokasiAbsenScreenState extends State<ListLokasiAbsenScreen> {
  Future<void> _toggleStatus(String docId, bool currentStatus) async {
    final newStatus = currentStatus;
    try {
      await FirebaseFirestore.instance
          .collection('lokasi_absen')
          .doc(docId)
          .update({'marketing_flexible': newStatus});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui status: $e')));
    }
  }

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus lokasi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('lokasi_absen')
            .doc(docId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lokasi berhasil dihapus')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus lokasi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List Lokasi Absen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lokasi_absen')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final lokasiList = snapshot.data?.docs ?? [];

          return Column(
            children: [
              if (lokasiList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/formlokasi');
                    },
                    child: const Text('Buat Lokasi Absen'),
                  ),
                ),
              Expanded(
                child: lokasiList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.location_off,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Belum ada lokasi absen yang dibuat.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: lokasiList.length,
                        itemBuilder: (context, index) {
                          final lokasi = lokasiList[index];
                          final marketingFlexible =
                              lokasi['marketing_flexible'] ?? false;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Judul lokasi dan tombol hapus
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          lokasi['nama_lokasi'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _confirmDelete(context, lokasi.id),
                                        icon: const Icon(Icons.delete),
                                        color: Colors.red,
                                        tooltip: 'Hapus Lokasi',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // Informasi radius dan koordinat
                                  Text(
                                    'Radius Toleransi: ${lokasi['radius'] ?? '-'} meter',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    'Radius menentukan jarak maksimal pengguna dari titik lokasi absen.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Latitude: ${lokasi['latitude'].toString()}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    'Longitude: ${lokasi['longitude'].toString()}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),

                                  // Penjelasan kecil
                                  const Text(
                                    '📍 Koordinat lokasi diambil dari titik pusat lokasi perusahaan Anda.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Marketing flexible
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              'Marketing Flexible:',
                                              style: TextStyle(fontSize: 13),
                                            ),
                                            Text(
                                              'Jika aktif, karyawan marketing bisa absen di luar radius.',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        marketingFlexible
                                            ? 'Aktif'
                                            : 'Tidak Aktif',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: marketingFlexible
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      Switch(
                                        value: marketingFlexible,
                                        onChanged: (value) async {
                                          await _toggleStatus(lokasi.id, value);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
