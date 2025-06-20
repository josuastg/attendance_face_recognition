import 'package:flutter/material.dart';

class SuccessAbsenScreen extends StatelessWidget {
  const SuccessAbsenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final type = args?['type'] ?? '';
    final time = args?['time'] ?? '--:--';

    final title = type == 'absen_masuk' ? 'Absen Masuk' : 'Absen Keluar';

    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Berhasil $title !!!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
                child: const Text('Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
