import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:attendance_face_recognition/screens/auth.dart';
import 'package:attendance_face_recognition/screens/home.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ⏳ Masih menunggu Firebase Auth init
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ User sudah login, redirect ke Home
        if (snapshot.hasData) {
          print("✅ User terdeteksi: ${snapshot.data?.email}");
          return HomeScreen();
        } else {
          print("❌ Tidak ada user login");
        }

        // ⛔️ Tidak login, tampilkan login page
        return const AuthScreen();
      },
    );
  }
}
