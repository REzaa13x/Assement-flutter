// Test alur login yang dipakai LoginPage, dijalankan terhadap server Laravel
// lokal (php artisan serve di port 8000).
//
// Jalankan dengan: flutter test test/login_flow_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/models/auth.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String email = 'saski@gmail.com';
  const String correctPassword = '12345678';
  const String wrongPassword = 'password-salah-123';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // flutter_test memasang HttpOverrides yang membalas 400 untuk semua
    // request; nonaktifkan agar test bisa benar-benar memanggil Laravel lokal.
    HttpOverrides.global = null;
  });

  test('login dengan kredensial benar mengembalikan token dan user', () async {
    final AuthResponse response = await AuthRepository.login(
      email: email,
      password: correctPassword,
    );

    expect(response.success, isTrue,
        reason: 'Login seharusnya sukses: ${response.message}');
    expect(response.token, isNotNull, reason: 'Token tidak boleh null');
    expect(response.token, isNotEmpty);
    expect(response.user, isNotNull, reason: 'User tidak boleh null');
    expect(response.user!.email, email);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('token tersimpan di AuthService dan dilaporkan sebagai login', () async {
    final AuthResponse response = await AuthRepository.login(
      email: email,
      password: correctPassword,
    );
    expect(response.success, isTrue);

    await AuthService.saveToken(response.token!);
    await AuthService.saveUserData(response.user!.toJson());

    expect(await AuthService.isLoggedIn(), isTrue);
    expect(await AuthService.getToken(), response.token);

    // Data user harus bisa dibaca kembali sebagai JSON (bukan Map.toString())
    final stored = await AuthService.getUserData();
    expect(stored, isNotNull, reason: 'getUserData tidak boleh null');
    expect(stored!['email'], email);
    expect(stored['name'], response.user!.name);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('login dengan password salah gagal dengan pesan yang jelas', () async {
    final AuthResponse response = await AuthRepository.login(
      email: email,
      password: wrongPassword,
    );

    expect(response.success, isFalse);
    expect(response.token, isNull);
    expect(response.message, isNotNull);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('setelah logout, status login kembali false', () async {
    final AuthResponse response = await AuthRepository.login(
      email: email,
      password: correctPassword,
    );
    expect(response.success, isTrue);

    await AuthService.saveToken(response.token!);
    expect(await AuthService.isLoggedIn(), isTrue);

    final loggedOut =
        await AuthRepository.logout(token: await AuthService.getToken());
    expect(loggedOut, isTrue, reason: 'Logout harus mengembalikan 200');

    await AuthService.removeToken();
    expect(await AuthService.isLoggedIn(), isFalse);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
