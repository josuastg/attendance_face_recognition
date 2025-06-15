import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  List<File> _photos = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);

    _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
    _initializeControllerFuture = _cameraController.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_photos.length >= 5) return;

    try {
      await _initializeControllerFuture;
      final image = await _cameraController.takePicture();
      setState(() {
        _photos.add(File(image.path));
      });
    } catch (e) {
      print(e);
    }
  }

  void _deletePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _savePhotos() {
    // Implement your save logic here
    print("Saving ${_photos.length} photos...");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: FutureBuilder(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return CameraPreview(_cameraController);
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        if (index < _photos.length) {
                          return Stack(
                            children: [
                              Image.file(_photos[index], width: 60, height: 60, fit: BoxFit.cover),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () => _deletePhoto(index),
                                  child: const Icon(Icons.delete, color: Colors.red, size: 20),
                                ),
                              )
                            ],
                          );
                        } else {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, color: Colors.grey),
                          );
                        }
                      }),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: _photos.length < 5 ? _takePhoto : null,
                          child: const Text("Ambil Foto"),
                        ),
                        ElevatedButton(
                          onPressed: _photos.length == 5 ? _savePhotos : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _photos.length == 5 ? Colors.blue : Colors.grey,
                          ),
                          child: const Text("Simpan"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text("*Required 5 Photo"),
                    const Text("*Pastikan selfie dalam keadaan terang"),
                    const Text("*Pastikan semua bagian wajah terlihat"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
