import 'package:attendance_face_recognition/gate/authgate.dart';
import 'package:attendance_face_recognition/screens/admin/attendance_history/attendancelist.dart';
import 'package:attendance_face_recognition/screens/auth.dart';
import 'package:attendance_face_recognition/screens/employee/attendance/dashboardattendance.dart';
import 'package:attendance_face_recognition/screens/employee/attendance/faceattendance.dart';
import 'package:attendance_face_recognition/screens/employee/attendance/registerface5.dart';
import 'package:attendance_face_recognition/screens/employee/attendance/successabsen.dart';
import 'package:attendance_face_recognition/screens/home.dart';
import 'package:attendance_face_recognition/screens/admin/location/listlokasiabsen.dart';
import 'package:attendance_face_recognition/screens/admin/register/registerkaryawan.dart';
import 'package:attendance_face_recognition/screens/admin/location/registerlokasiabsen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      title: 'Attendance App',
      routes: {
        '/login': (context) => AuthScreen(),
        '/home': (context) => HomeScreen(),
        '/registerkaryawan': (context) => RegisterKaryawanScreen(),
        '/listlokasi': (context) => ListLokasiAbsenScreen(),
        '/formlokasi': (context) => const FormLokasiAbsenScreen(),
        '/listattendance': (context) => AttendanceListScreen(),
        "/dashboardattendance": (context) => DashboarAttendanceScreen(),
        "/faceregistrationscreen": (context) => FaceRegistrationScreen(),
        "/success-absen": (context) => SuccessAbsenScreen(),
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        fontFamily: 'Poppins',
      ),
    );
  }
}
