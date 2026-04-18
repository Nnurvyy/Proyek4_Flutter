// test/authentication_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app/features/auth/login_controller.dart';

void main() {
  group('Modul 2 - Authentication (LoginController)', () {
    late LoginController loginController;

    setUp(() {
      loginController = LoginController();
    });

    // Flow 1: Positif (Username dan Password Benar)
    test('Flow 1: Harus mengembalikan data user jika username & password valid', () {
      final result = loginController.login('admin', '123');
      
      expect(result, isNotNull);
      expect(result!['role'], 'Ketua');
      expect(result['teamId'], 'team_A');
    });

    // Flow 2: Negatif (Username Benar, Password Salah)
    test('Flow 2: Harus mengembalikan null jika password salah', () {
      final result = loginController.login('admin', 'password_salah');
      
      expect(result, isNull);
    });

    // Flow 3: Negatif (Username Tidak Terdaftar)
    test('Flow 3: Harus mengembalikan null jika username tidak terdaftar', () {
      final result = loginController.login('hacker', '123');
      
      expect(result, isNull);
    });
  });
}