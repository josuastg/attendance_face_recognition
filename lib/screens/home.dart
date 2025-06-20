import 'package:attendance_face_recognition/screens/employee/attendance/registerface.dart';
import 'package:attendance_face_recognition/screens/employee/attendance_history/mydetailattendance.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  String role = '';
  String name = '';
  String today = '';
  String time = '';
  String id = '';
  @override
  void initState() {
    super.initState();
    getUserRole();
    _startClock();
  }

  void getUserRole() async {
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data()!;
      setState(() {
        role = data['role'] ?? 'karyawan'; // default to karyawan jika tidak ada
        name = data['name'] ?? 'User';
        id = data['id'] ?? '';
      });

      // ✅ Cek apakah user sudah memiliki face_embedding
      final faceEmbedding = data['face_embedding'];
      if ((faceEmbedding == null || faceEmbedding.toString().isEmpty) &&
          role == 'karyawan') {
        // ⏩ Redirect ke halaman pendaftaran wajah
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const RegisterFaceScreen(), // ganti sesuai nama page-mu
            ),
          );
        });
      }
    } else {
      setState(() {
        role = 'karyawan';
        name = 'User';
        id = '';
      });
    }
  }

  void _startClock() {
    final now = DateTime.now();
    final formatterDate = DateFormat("EEEE, dd MMMM yyyy", "id_ID");
    today = formatterDate.format(now);
    time = DateFormat.Hm().format(now);

    // Update setiap detik
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          time = DateFormat.Hm().format(DateTime.now());
        });
        _startClock();
      }
    });
  }

  void _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Ya"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      print("✅ Logout success");
      // Tidak perlu Navigator.push, biarkan AuthGate mengarahkan ulang
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: role.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Welcome, $name',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Office",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(today),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              role == 'admin' ? "$time WIB" : "08:00 - 17:00",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (role == 'karyawan')
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/dashboardattendance',
                                  );
                                },
                                child: const Text("Absen Sekarang"),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        children: [
                          if (role == 'karyawan') ...[
                            IconButtonWithLabel(
                              icon: Icons.history,
                              label: "Riwayat Kehadiran",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MyDetailAttendanceScreen(
                                          userId: id,
                                          userName: name,
                                        ),
                                  ),
                                );
                              },
                            ),
                            IconButtonWithLabel(
                              icon: Icons.logout,
                              label: "Keluar Aplikasi",
                              onPressed: _logout,
                            ),
                          ],
                          if (role == 'admin') ...[
                            IconButtonWithLabel(
                              icon: Icons.list,
                              label: "List Kehadiran Karyawan",
                              onPressed: () {
                                Navigator.pushNamed(context, '/listattendance');
                                // Aksi
                              },
                            ),
                            IconButtonWithLabel(
                              icon: Icons.person_add,
                              label: "Tambah Data Karyawan",
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/registerkaryawan',
                                ); // <- Navigasi ke register
                              },
                            ),
                            IconButtonWithLabel(
                              icon: Icons.logout,
                              label: "Keluar Aplikasi",
                              onPressed: _logout,
                            ),
                            IconButtonWithLabel(
                              icon: Icons.location_on,
                              label: "Setting Lokasi Absen",
                              onPressed: () {
                                Navigator.pushNamed(context, '/listlokasi');
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class IconButtonWithLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const IconButtonWithLabel({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPressed,
      splashColor: Colors.grey.withOpacity(0.3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            // decoration: BoxDecoration(
            //   shape: BoxShape.circle,
            //   color: Colors.grey[200],
            // ),
            child: Icon(icon, size: 45, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
