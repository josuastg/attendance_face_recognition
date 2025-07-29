import 'package:flutter/material.dart';
import 'dashboardsection1.dart';
import 'dashboardsection2.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard HRD"),
        leading: const BackButton(),
      ),
      body: Scrollbar(
        thumbVisibility: true, // Agar scrollbar selalu terlihat saat scroll
        radius: const Radius.circular(10),
        thickness: 6,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              DashboardSection1(),
              SizedBox(height: 16),
              DashboardSection2(),
            ],
          ),
        ),
      ),
    );
  }
}
