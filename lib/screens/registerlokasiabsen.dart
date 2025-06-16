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

  String? _selectedDepartemen;
  String? _selectedStatus;

  bool _isLoading = false;

  final List<String> departemenOptions = [
    "All",
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

  final List<String> statusOptions = ['Active', 'Inactive'];

  bool _isFormValid() {
    return _namaLokasiController.text.isNotEmpty &&
        _latitudeController.text.isNotEmpty &&
        _longitudeController.text.isNotEmpty &&
        _radiusController.text.isNotEmpty &&
        _selectedDepartemen != null &&
        _selectedStatus != null &&
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
        latitudeErrorText = 'Format latitude tidak valid, contoh : -6.1751 atau +90';
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
        longitudeErrorText = 'Format longitude tidak valid, contoh : -6.1751 atau +90';
      } else {
        longitudeErrorText = null;
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('lokasi_absen').add({
        'id': user?.uid,
        'nama_lokasi': _namaLokasiController.text.trim(),
        'departemen': _selectedDepartemen,
        'latitude': _latitudeController.text.trim(),
        'longitude': _longitudeController.text.trim(),
        'radius': _radiusController.text.trim(),
        'status': _selectedStatus,
        'created_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi absen berhasil disimpan.')),
      );

      _namaLokasiController.clear();
      _latitudeController.clear();
      _longitudeController.clear();
      _radiusController.clear();
      setState(() {
        _selectedDepartemen = null;
        _selectedStatus = null;
      });
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
              DropdownButtonFormField<String>(
                value: _selectedDepartemen,
                decoration: const InputDecoration(labelText: 'Departemen'),
                items: departemenOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDepartemen = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Departemen wajib dipilih' : null,
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
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: statusOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Status wajib dipilih' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isFormValid() ? _submitForm : null,
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
