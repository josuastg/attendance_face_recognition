import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ListLokasiAbsenScreen extends StatefulWidget {
  const ListLokasiAbsenScreen({Key? key}) : super(key: key);

  @override
  State<ListLokasiAbsenScreen> createState() => _ListLokasiAbsenScreenState();
}

class _ListLokasiAbsenScreenState extends State<ListLokasiAbsenScreen> {
  // Future<void> _toggleStatus(String docId, String currentStatus) async {
  //   final newStatus = currentStatus == 'Active' ? 'Inactive' : 'Active';
  //   try {
  //     await FirebaseFirestore.instance
  //         .collection('lokasi_absen')
  //         .doc(docId)
  //         .update({'status': newStatus});
  //   } catch (e) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Gagal memperbarui status: $e')));
  //   }
  // }

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
              onPressed: () {
                Navigator.pushNamed(context, '/formlokasi');
              },
              child: const Text('Buat Lokasi Absen'),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('lokasi_absen')
                  .orderBy('nama_lokasi')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_off,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada lokasi absen yang dibuat.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final lokasiList = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: lokasiList.length,
                  itemBuilder: (context, index) {
                    final lokasi = lokasiList[index];
                    final status = lokasi['status'] ?? 'Inactive';
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
                            Text(
                              lokasi['nama_lokasi'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${status == 'Active' ? 'Aktif' : 'Tidak Aktif'}',
                            ),
                            Text(
                              'Departemen: ${lokasi['departemen'] == 'All' ? 'Semua Departemen' : lokasi['departemen']}',
                            ),
                            Text('Radius: ${lokasi['radius'] ?? '-'}m'),
                            const SizedBox(height: 8),
                            // Align(
                            //   alignment: Alignment.centerRight,
                            //   child: ElevatedButton(
                            //     onPressed: () {
                            //       _toggleStatus(lokasi.id, status);
                            //     },
                            //     style: ElevatedButton.styleFrom(
                            //       backgroundColor: Colors.black87,
                            //       padding: const EdgeInsets.symmetric(
                            //         horizontal: 16,
                            //         vertical: 8,
                            //       ),
                            //     ),
                            //     child: Text(
                            //       status == 'Active'
                            //           ? 'Nonaktifkan'
                            //           : 'Aktifkan',
                            //     ),
                            //   ),
                            // ),
                          ],
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
