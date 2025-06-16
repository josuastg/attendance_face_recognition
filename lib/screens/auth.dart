import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final _auth = FirebaseAuth.instance;
  String errorMessage = '';

  String? emailError;
  String? passwordError;
  bool isPasswordVisible = false;

  bool isEmailValid = true;
  bool isPasswordValid = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(validateEmail);
    _passwordController.addListener(validatePassword);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  void _login() async {
    setState(() {
      _isLoading = true;
      errorMessage = '';
    });
    validateEmail();
    validatePassword();
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login berhasil")));

      // TODO: Redirect ke halaman utama
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? 'Login gagal';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan saat login';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isButtonEnabled =
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        isEmailValid &&
        isPasswordValid;
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400,
            ), // Biar nggak terlalu lebar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  onChanged: (value) {
                    validateEmail();
                  },
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    errorText: isEmailValid
                        ? null
                        : 'Email you entered is incorrect!',
                  ),
                ),
                SizedBox(height: 20),
                TextField(
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
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
                ),
                if (errorMessage.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading || !isButtonEnabled ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Login', style: TextStyle(fontSize: 16)),
                ),
                SizedBox(height: 30),
                Text(
                  'By signing up, you agree to our Terms of Service\nand Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
