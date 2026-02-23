import 'dart:async'; // Diperlukan untuk Timer
import 'package:flutter/material.dart';
import 'package:logbook_app/features/auth/login_controller.dart';
import 'package:logbook_app/features/logbook/counter_view.dart';
import 'package:logbook_app/features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _controller = LoginController();
  
  // Kunci form untuk validasi (Field tidak boleh kosong)
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // State untuk fitur Show/Hide Password
  bool _isObscure = true;

  // State untuk Security Logic (Lockout)
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  Timer? _lockoutTimer;
  int _countdown = 0;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _lockoutTimer?.cancel(); // Pastikan timer dimatikan saat widget dihancurkan
    super.dispose();
  }

  void _handleLogin() {
    // Jika sedang terkunci, jangan lakukan apa-apa
    if (_isLockedOut) return;

    // 2. Security Logic: Validasi Field tidak boleh kosong
    if (_formKey.currentState!.validate()) {
      String user = _userController.text;
      String pass = _passController.text;

      bool isSuccess = _controller.login(user, pass);

      if (isSuccess) {
        // Reset counter jika berhasil
        setState(() {
          _failedAttempts = 0; 
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LogView(username: user),
          ),
        );
      } else {
        // Login Gagal
        setState(() {
          _failedAttempts++;
        });

        // Cek jika sudah salah 3 kali
        if (_failedAttempts >= 3) {
          _startLockout();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Login Gagal! Sisa percobaan: ${3 - _failedAttempts}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Logika untuk menonaktifkan tombol selama 10 detik
  void _startLockout() {
    setState(() {
      _isLockedOut = true;
      _countdown = 10;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Terlalu banyak percobaan. Login dikunci selama 10 detik."),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );

    // Timer mundur setiap 1 detik
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          // Waktu habis, buka kunci
          _isLockedOut = false;
          _failedAttempts = 0; // Reset percobaan
          timer.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Silakan coba login kembali."), backgroundColor: Colors.green),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login GateKeeper"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form( // Bungkus dengan Form untuk validasi
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Field Username
              TextFormField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                // Validasi tidak boleh kosong
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Field Password dengan Show/Hide
              TextFormField(
                controller: _passController,
                // 3. View: Show/Hide Password
                obscureText: _isObscure, 
                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  // Ikon mata untuk toggle visibility
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                ),
                // Validasi tidak boleh kosong
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Tombol Login
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  // Tombol disabled (null) jika _isLockedOut true
                  onPressed: _isLockedOut ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLockedOut ? Colors.grey : Colors.blue,
                  ),
                  child: Text(
                    _isLockedOut 
                        ? "Tunggu $_countdown detik..." 
                        : "Masuk",
                    style: const TextStyle(
                      fontSize: 18, 
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}