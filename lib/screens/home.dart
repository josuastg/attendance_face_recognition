import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    getUserRole();
    _startClock();
  }

  void getUserRole() {
    // Cek email admin
    if (user?.email == 'admin@gmail.com') {
      setState(() {
        role = 'admin';
        name = 'Admin'; // Default nama jika belum pakai Firestore
      });
    } else {
      setState(() {
        role = 'karyawan';
        name = 'Lorem Ipsum'; // Default nama
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
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Konfirmasi Logout"),
      content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Batal
          child: const Text("Batal"),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop(); // Tutup dialog
            await FirebaseAuth.instance.signOut();
          },
          child: const Text("Ya"),
        ),
      ],
    ),
  );
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
                                  // Aksi absen
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
                                // Aksi
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
                                // Aksi
                              },
                            ),
                            IconButtonWithLabel(
                              icon: Icons.person_add,
                              label: "Tambah Data Karyawan",
                              onPressed: () {
                                // Aksi
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
                                // Aksi
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
            child: Icon(
              icon,
              size: 45,
              color: Colors.black87,
            ),
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
