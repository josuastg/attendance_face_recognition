import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FormLokasiAbsenScreen extends StatefulWidget {
  const FormLokasiAbsenScreen({super.key});

  @override
  State<FormLokasiAbsenScreen> createState() => _FormLokasiAbsenScreenState();
}

class _FormLokasiAbsenScreenState extends State<FormLokasiAbsenScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaLokasiController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  bool _isLoading = false;
  bool marketingFlexible = false;
  bool _isFormValid() {
    return _namaLokasiController.text.isNotEmpty &&
        _latitudeController.text.isNotEmpty &&
        _longitudeController.text.isNotEmpty &&
        _radiusController.text.isNotEmpty &&
        longitudeErrorText == null &&
        latitudeErrorText == null;
  }

  String? latitudeErrorText;
  String? longitudeErrorText;

  void _validateLatitude(String value) {
    final regex = RegExp(r'^-?([1-8]?\d(\.\d+)?|90(\.0+)?)$');
    setState(() {
      if (value.isEmpty) {
        latitudeErrorText = 'Latitude wajib diisi';
      } else if (!regex.hasMatch(value)) {
        latitudeErrorText =
            'Format latitude tidak valid, contoh : -6.1751 atau +90';
      } else {
        latitudeErrorText = null;
      }
    });
  }

  void _validateLongitude(String value) {
    final regex = RegExp(r'^-?(1[0-7]\d(\.\d+)?|[1-9]?\d(\.\d+)?|180(\.0+)?)$');
    setState(() {
      if (value.isEmpty) {
        longitudeErrorText = 'Longitude wajib diisi';
      } else if (!regex.hasMatch(value)) {
        longitudeErrorText =
            'Format longitude tidak valid, contoh : -6.1751 atau +90';
      } else {
        longitudeErrorText = null;
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final ref = await FirebaseFirestore.instance
          .collection('lokasi_absen')
          .add({
            'nama_lokasi': _namaLokasiController.text.trim(),
            'latitude': _latitudeController.text.trim(),
            'longitude': _longitudeController.text.trim(),
            'radius': int.parse(_radiusController.text.trim()),
            'created_at': Timestamp.now(),
            'marketing_flexible': marketingFlexible,
          });
      await ref.set({'id': ref.id}, SetOptions(merge: true));
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lokasi absen berhasil disimpan.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/listlokasi');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('')));

      _namaLokasiController.clear();
      _latitudeController.clear();
      _longitudeController.clear();
      _radiusController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Lokasi Absen')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: ListView(
            children: [
              TextFormField(
                controller: _namaLokasiController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lokasi Absen',
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Nama lokasi wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _latitudeController,
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  errorText: latitudeErrorText,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: _validateLatitude,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _longitudeController,
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  errorText: longitudeErrorText,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: _validateLongitude,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _radiusController,
                decoration: const InputDecoration(
                  labelText: 'Radius Toleransi',
                  suffixText: 'm',
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Radius wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Marketing Flexible (Opsional):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Switch(
                    value: marketingFlexible,
                    onChanged: (value) async {
                      setState(() {
                        marketingFlexible = value;
                      });
                      // Tidak perlu setState(), StreamBuilder akan rebuild sendiri
                    },
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _isFormValid() ? _submitForm : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
