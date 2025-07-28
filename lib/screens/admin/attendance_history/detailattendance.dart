import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class DetailAttendanceScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const DetailAttendanceScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<DetailAttendanceScreen> createState() => _DetailAttendanceScreenState();
}

class _DetailAttendanceScreenState extends State<DetailAttendanceScreen> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentIndex = 0;
  List<String> photoUrls = [];

  Future<List<Map<String, dynamic>>> getAttendanceStream() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - 1, now.day);
    final snapshot = await FirebaseFirestore.instance
        .collection('absensi')
        .where('user_id', isEqualTo: widget.userId)
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('time', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('time')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> getUserPhotoUrls() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    final data = userDoc.data();
    if (data != null && data['photo_url'] != null) {
      final List<String> urls = List<String>.from(data['photo_url']);
      setState(() {
        photoUrls = urls;
      });
      preloadImages(urls);
    }
  }

  Future<void> nonaktifkanKaryawan(BuildContext context, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'is_active': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Karyawan berhasil dinonaktifkan')),
      );

      // Redirect ke halaman list karyawan
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/listattendance',
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menonaktifkan: $e')));
    }
  }

  void preloadImages(List<String> urls) {
    for (final url in urls) {
      precacheImage(CachedNetworkImageProvider(url), context);
    }
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
    getUserPhotoUrls();
    getLokasiKantor();
  }

  Widget buildCarousel() {
    if (photoUrls.isEmpty) {
      return const Center(child: Text('Belum ada foto wajah.'));
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 100,
            enlargeCenterPage: true,
            viewportFraction: 0.8,
            aspectRatio: 2.0,
            enableInfiniteScroll: false,
          ),
          items: photoUrls.map((url) {
            return GestureDetector(
              onTap: () => openFullScreen(url),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: url,
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(strokeWidth: 1),
                  errorWidget: (context, url, error) => const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        Positioned(
          left: 10,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => _carouselController.previousPage(),
          ),
        ),
        Positioned(
          right: 10,
          child: IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () => _carouselController.nextPage(),
          ),
        ),
      ],
    );
  }

  void openFullScreen(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Detail Wajah Karyawan")),
          body: Center(
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Kehadiran"),
        leading: BackButton(),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.block),
          //   tooltip: 'Nonaktifkan Karyawan',
          //   onPressed: () async {
          //     final confirm = await showDialog<bool>(
          //       context: context,
          //       builder: (context) => AlertDialog(
          //         title: const Text('Konfirmasi'),
          //         content: const Text(
          //           'Apakah Anda yakin ingin menonaktifkan karyawan ini?',
          //         ),
          //         actions: [
          //           TextButton(
          //             onPressed: () => Navigator.of(context).pop(false),
          //             child: const Text('Batal'),
          //           ),
          //           TextButton(
          //             onPressed: () => Navigator.of(context).pop(true),
          //             child: const Text('Ya, Nonaktifkan'),
          //           ),
          //         ],
          //       ),
          //     );

          //     if (confirm == true) {
          //       // Panggil fungsi nonaktifkan
          //       await nonaktifkanKaryawan(context, widget.userId);
          //     }
          //   },
          // ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nama karyawan
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Text(
                widget.userName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Carousel Foto Wajah + Arrow
          buildCarousel(),
          // Carousel Foto Wajah
          // FutureBuilder<List<String>>(
          //   future: getUserPhotoUrls(),
          //   builder: (context, snapshot) {
          //     if (snapshot.connectionState == ConnectionState.waiting) {
          //       return const Center(child: CircularProgressIndicator());
          //     }

          //     if (snapshot.hasError) {
          //       return const Center(child: Text('Gagal memuat foto wajah.'));
          //     }

          //     final urls = snapshot.data ?? [];
          //     if (urls.isEmpty) {
          //       return const Center(child: Text('Belum ada foto wajah.'));
          //     }

          //     return CarouselSlider(
          //       options: CarouselOptions(
          //         height: 120,
          //         autoPlay: true,
          //         enlargeCenterPage: true,
          //         viewportFraction: 0.8,
          //         aspectRatio: 2.0,
          //       ),
          //       items: urls.map((url) {
          //         return GestureDetector(
          //           onTap: () => openFullScreen(url),
          //           child: ClipOval(
          //             child: Image.network(
          //               url,
          //               width: 120,
          //               height: 120,
          //               fit: BoxFit.contain,
          //               errorBuilder: (context, error, stackTrace) {
          //                 debugPrint('❌ Gagal load foto: $error');
          //                 return const CircleAvatar(
          //                   radius: 0,
          //                   backgroundColor: Colors.grey,
          //                   child: Icon(Icons.person, color: Colors.white),
          //                 );
          //               },
          //             ),
          //           ),
          //         );
          // return ClipRRect(
          //   borderRadius: BorderRadius.circular(30),
          //   child: Image.network(
          //     url,
          //     fit: BoxFit.contain,
          //     width: 150,
          //     errorBuilder: (context, error, stackTrace) =>
          //         const Icon(Icons.broken_image, size: 80),
          //   ),
          // );
          // }).toList(),
          //   );
          // },
          // ),
          const SizedBox(height: 10),
          // Riwayat Absensi
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

                    final time = (data['time'] as Timestamp).toDate();
                    final formattedDate = DateFormat(
                      'dd MMM yyyy',
                      'id_ID',
                    ).format(time);
                    final formattedTime = DateFormat('HH:mm').format(time);
                    final photoAbsen = data['photo_url'];
                    final double latKantor =
                        double.tryParse(lokasiKantor!['latitude'].toString()) ??
                        0.0;
                    final double longKantor =
                        double.tryParse(
                          lokasiKantor!['longitude'].toString(),
                        ) ??
                        0.0;

                    final double latUser =
                        double.tryParse(data['latitude'].toString()) ?? 0.0;
                    final double longUser =
                        double.tryParse(data['longitude'].toString()) ?? 0.0;

                    final double radiusKantor =
                        double.tryParse(lokasiKantor!['radius'].toString()) ??
                        0.0;
                    print('radius$radiusKantor');
                    final double jarak = calculateDistance(
                      latKantor,
                      longKantor,
                      latUser,
                      longUser,
                    );
                    final bool diDalamKantor = jarak <= radiusKantor;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Kolom kiri: teks absen, tanggal, jam
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
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
                                      Text(formattedDate),
                                      Text(formattedTime),
                                    ],
                                  ),
                                ),

                                // Kolom kanan: gambar atau teks fallback
                                (photoAbsen != null &&
                                        photoAbsen.toString().isNotEmpty)
                                    ? GestureDetector(
                                        onTap: () => openFullScreen(photoAbsen),
                                        child: ClipOval(
                                          child: Image.network(
                                            photoAbsen,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  debugPrint(
                                                    '❌ Gagal load foto: $error',
                                                  );
                                                  return const CircleAvatar(
                                                    radius: 0,
                                                    backgroundColor:
                                                        Colors.grey,
                                                    child: Icon(
                                                      Icons.person,
                                                      color: Colors.white,
                                                    ),
                                                  );
                                                },
                                          ),
                                        ),
                                      )
                                    : const Padding(
                                        padding: EdgeInsets.only(
                                          top: 35,
                                          right: 8,
                                        ),
                                        child: Text(
                                          '-',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: diDalamKantor
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  diDalamKantor? 'Dalam Kantor': 'Luar Kantor',
                                  style: TextStyle(
                                    color: diDalamKantor
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            // Cek dan tampilkan lokasi
                            if (data['latitude'] != null &&
                                data['longitude'] != null) ...[
                              TextButton.icon(
                                icon: const Icon(Icons.location_on, size: 18),
                                iconAlignment: IconAlignment.start,
                                label: const Text(
                                  "Lihat di Google Maps",
                                  style: TextStyle(fontSize: 13),
                                ),
                                onPressed: () {
                                  final lat = data['latitude'];
                                  final lng = data['longitude'];
                                  final url =
                                      'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                                  launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                              ),
                            ],
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
