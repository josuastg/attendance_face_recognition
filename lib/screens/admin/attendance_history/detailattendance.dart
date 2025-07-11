import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  void preloadImages(List<String> urls) {
    for (final url in urls) {
      precacheImage(CachedNetworkImageProvider(url), context);
    }
  }

  @override
  void initState() {
    super.initState();
    getUserPhotoUrls();
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
                    ;
                    final time = (data['time'] as Timestamp).toDate();
                    final formattedDate = DateFormat(
                      'dd MMM yyyy',
                      'id_ID',
                    ).format(time);
                    final formattedTime = DateFormat('HH:mm').format(time);
                    // final photoAbsen = data['photo_url'] ?? null;
                    // print(photoAbsen);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Text(formattedDate), Text(formattedTime)],
                        ),
                        // trailing: photoAbsen != null
                        //     ? GestureDetector(
                        //         onTap: () => openFullScreen(photoAbsen),
                        //         child: ClipOval(
                        //           child: Image.network(
                        //             photoAbsen,
                        //             width: 60,
                        //             height: 60,
                        //             fit: BoxFit.contain,
                        //             errorBuilder: (context, error, stackTrace) {
                        //               debugPrint('❌ Gagal load foto: $error');
                        //               return const CircleAvatar(
                        //                 radius: 60,
                        //                 backgroundColor: Colors.grey,
                        //                 child: Icon(
                        //                   Icons.person,
                        //                   color: Colors.white,
                        //                 ),
                        //               );
                        //             },
                        //           ),
                        //         ),
                        //       )
                        //     : null,
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
