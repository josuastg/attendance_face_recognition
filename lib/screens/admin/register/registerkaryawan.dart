import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // penting untuk secondary app

class RegisterKaryawanScreen extends StatefulWidget {
  const RegisterKaryawanScreen({super.key});

  @override
  State<RegisterKaryawanScreen> createState() => _RegisterKaryawanScreenState();
}

class _RegisterKaryawanScreenState extends State<RegisterKaryawanScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _selectedDepartemen;
  bool _isLoading = false;

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  final List<String> _departemenList = [
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

  bool isEmailValid = true;
  bool isPasswordValid = true;
  bool isConfirmPasswordValid = true;
  bool _passwordMatch = true;
  bool isValidNIK = true;

  bool _isFormValid() {
    return _namaController.text.isNotEmpty &&
        _nikController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _selectedDepartemen != null &&
        _passwordController.text == _confirmPasswordController.text &&
        isEmailValid &&
        isPasswordValid &&
        isConfirmPasswordValid &&
        isValidNIK;
  }

  void validateNIK() {
    setState(() {
      if (_nikController.text.isEmpty ||
          int.tryParse(_nikController.text) == null) {
        isValidNIK = true;
      } else {
        isValidNIK = _nikController.text.length >= 8;
      }
    });
    return;
  }

  void validateEmail() {
    setState(() {
      if (_emailController.text.isEmpty) {
        isEmailValid = true;
      } else {
        isEmailValid = RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        ).hasMatch(_emailController.text);
      }
    });
    return;
  }

  void validatePassword() {
    setState(() {
      if (_passwordController.text.isEmpty) {
        isPasswordValid = true;
      } else {
        isPasswordValid = _passwordController.text.length >= 8;
      }
    });
    return;
  }

  void validateConfirmPassword() {
    setState(() {
      if (_confirmPasswordController.text.isEmpty) {
        isConfirmPasswordValid = true;
      } else {
        isConfirmPasswordValid = _confirmPasswordController.text.length >= 8;
        _passwordMatch =
            _passwordController.text == _confirmPasswordController.text;
        print(_passwordMatch);
      }
    });
    return;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Inisialisasi Firebase App baru agar tidak mengganggu session admin
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Buat akun baru
      UserCredential userCredential = await secondaryAuth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final newUser = userCredential.user;

      if (newUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(newUser.uid)
            .set({
              'id': newUser.uid,
              'name': _namaController.text.trim(),
              'nik': _nikController.text.trim(),
              'email': _emailController.text.trim(),
              'departement': _selectedDepartemen,
              'role': 'karyawan',
              'created_at': Timestamp.now(),
            });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Karyawan berhasil didaftarkan.')),
        );

        // Reset field
        _namaController.clear();
        _nikController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        setState(() {
          _selectedDepartemen = null;
        });
      }

      // Sign out dari secondary agar tidak mengganggu instance utama
      await secondaryAuth.signOut();
      await secondaryApp.delete();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pendaftaran Karyawan"),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: ListView(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (value) =>
                    value!.isEmpty ? 'Masukkan nama lengkap' : null,
              ),
              TextFormField(
                controller: _nikController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  validateNIK();
                },
                decoration: InputDecoration(
                  labelText: 'NIK',
                  errorText: isValidNIK
                      ? null
                      : 'NIK must be number and 8 digit',
                ),
                validator: (value) => value!.isEmpty
                    ? 'Masukkan NIK'
                    : (int.tryParse(value) == null ? 'NIK harus angka' : null),
              ),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  validateEmail();
                },
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: isEmailValid
                      ? null
                      : 'Email you entered is incorrect!',
                ),
                validator: (value) => value!.isEmpty || !value.contains('@')
                    ? 'Masukkan email yang valid'
                    : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedDepartemen,
                items: _departemenList
                    .map(
                      (dept) =>
                          DropdownMenuItem(value: dept, child: Text(dept)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDepartemen = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Departemen'),
                validator: (value) => value == null ? 'Pilih departemen' : null,
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: !isPasswordVisible,
                onChanged: (value) {
                  validatePassword();
                },
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: isPasswordValid
                      ? null
                      : 'Password must be at least 8 characters!',
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                    child: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                validator: (value) => value!.length < 6
                    ? 'Password must be at least 8 characters!'
                    : null,
              ),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !isConfirmPasswordVisible,
                onChanged: (value) {
                  validateConfirmPassword();
                },
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  errorText: isConfirmPasswordValid && _passwordMatch
                      ? null
                      : 'Password must be match to password !',
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        isConfirmPasswordVisible = !isConfirmPasswordVisible;
                      });
                    },
                    child: Icon(
                      isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                validator: (value) => value != _passwordController.text
                    ? 'Password must be match to password !'
                    : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isFormValid() && !_isLoading ? _submitForm : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Daftar", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
