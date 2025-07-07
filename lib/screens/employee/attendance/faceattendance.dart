import 'dart:convert';
import 'dart:io' show Platform, File, Directory;
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:geolocator/geolocator.dart';
import 'package:app_settings/app_settings.dart';

class FaceAttendanceScreen extends StatefulWidget {
  final String type;

  const FaceAttendanceScreen({super.key, required this.type});

  @override
  State<FaceAttendanceScreen> createState() => _FaceAttendanceScreenState();
}

class _FaceAttendanceScreenState extends State<FaceAttendanceScreen> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<Position?> getCurrentLocationWithDialog(BuildContext context) async {
    // Tampilkan dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("Mengecek lokasi..."),
          ],
        ),
      ),
    );

    try {
      // Cek apakah GPS diaktifkan
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Navigator.of(context).pop(); // Tutup dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layanan lokasi belum aktif. Aktifkan GPS.'),
          ),
        );
        if (Platform.isIOS) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Layanan lokasi belum aktif.'),
              content: Text('Tolong aktifkan GPS terlebih dahulu'),
              actions: [
                TextButton(
                  onPressed: () async {
                    await AppSettings.openAppSettings();
                    Navigator.pop(context);
                  },
                  child: const Text('Go to Settings'),
                ),
              ],
            ),
          );
        }
        return null;
      }

      // Cek dan minta izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        Navigator.of(context).pop(); // Tutup dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi tidak diberikan.')),
        );
        if (Platform.isIOS) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Layanan lokasi belum aktif.'),
              content: Text('Tolong aktifkan GPS terlebih dahulu'),
              actions: [
                TextButton(
                  onPressed: () async {
                    await AppSettings.openAppSettings();
                    Navigator.pop(context);
                  },
                  child: const Text('Go to Settings'),
                ),
              ],
            ),
          );// Buka pengaturan jika iOS
        }
        return null;
      }

      final position = await Geolocator.getCurrentPosition();

      if (Platform.isAndroid && position.isMocked) {
        Navigator.of(context).pop(); // Tutup dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lokasi tidak valid (mock detected).')),
        );
        return null;
      }

      Navigator.of(context).pop(); // ✅ Tutup dialog jika sukses
      return position;
    } catch (e) {
      Navigator.of(context).pop(); // ✅ Tutup dialog jika error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mendapatkan lokasi: $e')));
      return null;
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _cameraController.initialize();

    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _takeAndSubmitPhoto() async {
    if (!_cameraController.value.isInitialized) return;

    // cek location
    final position = await getCurrentLocationWithDialog(context);
    if (position == null) return; // ⛔ Stop jika gagal
    // Tampilkan dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("Memproses absensi..."),
          ],
        ),
      ),
    );

    try {
      final photo = await _cameraController.takePicture();
      final originalImage = File(photo.path);

      // Unmirror image
      final bytes = await originalImage.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return;
      final flipped = img.flipHorizontal(decoded);
      final flippedBytes = img.encodeJpg(flipped);

      // Simpan image baru ke file
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String newPath = path.join(appDir.path, 'absen_selfie.jpg');
      final newImage = await File(newPath).writeAsBytes(flippedBytes);
      //-6.213659995673977, 106.48862015322251
      final baseUrl = dotenv.env['API_URL'] ?? '';
      final uri = Uri.parse('$baseUrl/absen');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('photo', newImage.path))
        ..fields['user_id'] = userId ?? ''
        ..fields['type'] = widget.type
        ..fields['date'] = DateFormat('yyyy-MM-dd').format(DateTime.now())
        ..fields['time'] = DateTime.now().toIso8601String()
        ..fields['latitude'] = position.latitude.toString()
        ..fields['longitude'] = position.longitude.toString();

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final msg = jsonDecode(responseBody);
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading

      if (response.statusCode == 200) {
        Navigator.pushReplacementNamed(
          context,
          '/success-absen',
          arguments: {
            'type': widget.type, // absen_masuk atau absen_keluar
            'time': DateFormat('HH:mm').format(DateTime.now()),
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Gagal absen'),
            content: Text(
              'Gagal melakukan ${widget.type == 'absen_masuk' ? 'absen masuk' : 'absen keluar'}, ${msg['error'].toString().toLowerCase()}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Tutup loading jika error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'absen_masuk' ? 'Absen Masuk' : 'Absen Keluar';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _isCameraInitialized
          ? Column(
              children: [
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    height: 300,
                    width: MediaQuery.of(context).size.width * 0.90,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CameraPreview(_cameraController),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _takeAndSubmitPhoto,
                    child: const Text('Ambil Foto'),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Lakukan selfie untuk proses absensi',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Memuat kamera...'),
                ],
              ),
            ),
    );
  }
}
