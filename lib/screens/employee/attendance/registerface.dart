import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class RegisterFaceScreen extends StatefulWidget {
  const RegisterFaceScreen({super.key});

  @override
  State<RegisterFaceScreen> createState() => _RegisterFaceScreenState();
}

class _RegisterFaceScreenState extends State<RegisterFaceScreen> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  List<XFile> _capturedPhotos = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
    if (!mounted) return;

    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> _capturePhoto() async {
    if (!_cameraController.value.isInitialized || _capturedPhotos.length >= 3)
      return;

    final photo = await _cameraController.takePicture();
    final originalImage = File(photo.path);

    // Baca dan decode image
    final bytes = await originalImage.readAsBytes();
    final decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) return;

    // Flip horizontal (unmirror)
    final flippedImage = img.flipHorizontal(decodedImage);

    // Simpan ke file baru
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String newPath = path.join(
      appDir.path,
      'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final flippedBytes = img.encodeJpg(flippedImage);
    final newImageFile = await File(newPath).writeAsBytes(flippedBytes);

    setState(() {
      _capturedPhotos.add(XFile(newImageFile.path));
    });
  }

  void _deletePhoto(int index) async {
    final file = File(_capturedPhotos[index].path);
    if (await file.exists()) {
      await file.delete(); // Hapus file dari penyimpanan
    }
    setState(() {
      _capturedPhotos.removeAt(index);
    });
  }

  Future<void> _submitPhotos() async {
    if (_capturedPhotos.length != 3) return;

    final url = Uri.parse('https://your-api-url.com/register-face');

    final request = http.MultipartRequest('POST', url);
    for (int i = 0; i < 3; i++) {
      request.files.add(
        await http.MultipartFile.fromPath('photo$i', _capturedPhotos[i].path),
      );
    }

    final response = await request.send();
    // if (response.statusCode == 200) {
    //   // ✅ Tampilkan dialog berhasil simpan
    //   if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Berhasil'),
          content: const Text(
            'Wajah berhasil disimpan.\nSegera lakukan absen.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    // } else {
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(const SnackBar(content: Text('Gagal simpan foto!')));
    // }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Widget _buildThumbnail(int index) {
    if (index < _capturedPhotos.length) {
      return Stack(
        children: [
          Image.file(
            File(_capturedPhotos[index].path),
            width: 70,
            height: 70,
            fit: BoxFit.cover,
          ),

          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _deletePhoto(index),
              child: const Icon(Icons.delete, size: 22, color: Colors.red),
            ),
          ),
        ],
      );
    } else {
      return Container(
        width: 70,
        height: 70,
        color: Colors.grey[300],
        child: const Icon(Icons.image),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Pendaftaran Belum Selesai"),
              content: const Text(
                "Anda harus menyelesaikan pendaftaran wajah terlebih dahulu.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Pendaftaran Wajah")),
        body: _isCameraInitialized
            ? Column(
                children: [
                  // Live Camera View
                  SizedBox(
                    height: 300, // Atur tinggi sesuai yang kamu inginkan
                    width:
                        MediaQuery.of(context).size.width *
                        0.90, // Lebar sedikit margin
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CameraPreview(_cameraController),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Thumbnails
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildThumbnail(index),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 12),

                  // Button ambil foto atau simpan
                  ElevatedButton(
                    onPressed: _capturedPhotos.length == 3
                        ? _submitPhotos
                        : _capturePhoto,
                    child: Text(
                      _capturedPhotos.length == 3 ? 'Simpan' : 'Tambah Foto',
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Informasi
                  const Text("*Maks.3 Foto"),
                  const Text("*Pastikan selfie dalam keadaan terang"),
                  const Text("*Pastikan semua bagian wajah terlihat"),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
