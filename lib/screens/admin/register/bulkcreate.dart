import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BulkUploadUsersScreen extends StatefulWidget {
  final String adminId;

  const BulkUploadUsersScreen({super.key, required this.adminId});

  @override
  State<BulkUploadUsersScreen> createState() => _BulkUploadUsersScreenState();
}

class _BulkUploadUsersScreenState extends State<BulkUploadUsersScreen> {
  File? selectedFile;
  bool isUploading = false;

  Future<void> pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("Mengunggah data..."),
          ],
        ),
      ),
    );
  }

  Future<void> uploadExcelFile() async {
    if (selectedFile == null) return;

    setState(() => isUploading = true);

    try {
      showLoadingDialog();
      // Read Excel
      final bytes = selectedFile!.readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      final users = <Map<String, dynamic>>[];

      for (var row in excel.tables[excel.tables.keys.first]!.rows.skip(1)) {
        final email = row[0]?.value?.toString() ?? '';
        final password = row[1]?.value?.toString() ?? '';
        final name = row[2]?.value?.toString() ?? '';
        final departemen = row[3]?.value?.toString() ?? '';
        final nik = row.length > 4 ? row[4]?.value?.toString() ?? '' : '';

        if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty && departemen.isNotEmpty && nik.isNotEmpty) {
          users.add({
            'email': email,
            'password': password,
            'name': name,
            'departemen': departemen,
            'nik': nik,
          });
        }
      }

      final dio = Dio();
      final baseUrl = dotenv.env['API_URL'] ?? '';

      final response = await dio.post(
        'http://192.168.1.8:5001/bulk-create-users',
        data: {'admin_id': widget.adminId, 'users': users},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      Navigator.pop(context); // Tutup loading

      final data = response.data;
      if (data['success'] == true) {
        final created = data['created_count'];
        final failed = data['failed_count'];
        setState(() {
          selectedFile = null; // Reset file setelah selesai
        });
        if (failed > 0) {
          final url = data['failed_download_url'];
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Sebagian Gagal'),
              content: Text(
                '$created berhasil, $failed gagal. Anda dapat mengunduh file error.',
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await launchUrlString(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  child: const Text('Download Error File'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Berhasil'),
              content: Text('$created user berhasil ditambahkan.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception(data['error'] ?? 'Gagal upload data.');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Gagal'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
    setState(() => isUploading = false);
  }

  Widget buildTemplateInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 Gunakan template file berikut:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final url = 'https://res.cloudinary.com/dthyhs6rq/raw/upload/v1752422015/template_bulk_upload_dtiqyj.xlsx';
            await launchUrlString(url, mode: LaunchMode.externalApplication);
          },
          child: const Text(
            '📥 Download Template Excel',
            style: TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Kolom yang didukung: email (ex: sari@ginsaintipratama.com), password (default: 12345678), name, departemen, nik',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Create Users')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildTemplateInfo(),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: pickExcelFile,
              icon: const Icon(Icons.file_open),
              label: const Text('Pilih File Excel'),
            ),
            const SizedBox(height: 10),
            if (selectedFile != null)
              Text(
                '📄 ${selectedFile!.path.split('/').last}',
                style: const TextStyle(color: Colors.green),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isUploading || selectedFile == null ? null : uploadExcelFile,
              icon: const Icon(Icons.upload_file),
              label: isUploading
                  ? const Text('Mengunggah...')
                  : const Text('Upload Sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}
