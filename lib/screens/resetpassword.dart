import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final snapshot = FirebaseFirestore.instance;
  bool _isLoading = false;

  Future<bool> checkEmailInUsersCollection(String email) async {
    final result = await snapshot
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }

  void _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showErrorDialog("Masukkan email yang valid.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final emailExists = await checkEmailInUsersCollection(email);
    if (!emailExists) {
      setState(() => _isLoading = false);
      _showErrorDialog("Email tidak terdaftar di sistem.");
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      setState(() {
        _isLoading = false;
        _emailController.clear();
      });

      // ✅ Tampilkan dialog berhasil
      _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog("Terjadi kesalahan: ${e.message}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Berhasil"),
        content: const Text("Link reset password telah dikirim ke email Anda."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // tutup dialog
              Navigator.of(context).pop(); // kembali ke halaman login
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Gagal"),
        content: Text(message),
        actions: [
          TextButton(
            child: Text("Tutup"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Lupa Password")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              "Masukkan email Anda untuk mengatur ulang password.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text("Kirim Link"),
            ),
          ],
        ),
      ),
    );
  }
}
