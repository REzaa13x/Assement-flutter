import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  Future<void> _login() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthRepository.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.success && response.token != null) {
        // Simpan token ke shared preferences
        await AuthService.saveToken(response.token!);

        if (response.user != null) {
          await AuthService.saveUserData(response.user!.toJson());
        }

        // Hubungkan token perangkat (FCM) dengan akun yang baru login
        NotificationService.registerTokenForCurrentUser();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login berhasil!'),
            backgroundColor: Colors.green,
          ),
        );

        // Arahkan ke halaman utama
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        final rawMessage = response.message ?? '';
        String errorMessage;

        // Cek apakah error berasal dari masalah jaringan
        if (rawMessage.contains('Failed to fetch') ||
            rawMessage.contains('SocketException') ||
            rawMessage.contains('Connection refused') ||
            rawMessage.contains('refused the network connection') ||
            rawMessage.contains('Error logging in')) {
          errorMessage =
              'Tidak dapat terhubung ke server. Pastikan server Laravel sudah berjalan (php artisan serve).';
        } else if (response.errors != null && response.errors!.isNotEmpty) {
          final firstError = response.errors!.values.first;
          errorMessage = firstError is List
              ? firstError.join(', ')
              : firstError.toString();
        } else {
          errorMessage = rawMessage.isNotEmpty
              ? rawMessage
              : 'Login gagal. Periksa email dan password Anda.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final String errorMsg = e.toString();
      String userFriendlyMsg;

      if (errorMsg.contains('Failed to fetch') ||
          errorMsg.contains('SocketException') ||
          errorMsg.contains('Connection refused') ||
          errorMsg.contains('refused the network connection') ||
          errorMsg.contains('ClientException')) {
        userFriendlyMsg = 'Tidak dapat terhubung ke server.\n'
            'Pastikan server Laravel sudah berjalan:\n'
            '  php artisan serve';
      } else {
        userFriendlyMsg = 'Terjadi kesalahan: $errorMsg';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFriendlyMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  static const _primary = Color(0xFF2972FF);
  static const _ink = Color(0xFF142D50);
  static const _muted = Color(0xFF61738C);

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted, fontSize: 14),
      prefixIcon: Icon(icon, color: _primary, size: 21),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF5F8FD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: border(const Color(0xFFE3EAF4)),
      enabledBorder: border(const Color(0xFFE3EAF4)),
      focusedBorder: border(_primary, 1.5),
      errorBorder: border(const Color(0xFFD84154)),
      focusedErrorBorder: border(const Color(0xFFD84154), 1.5),
      errorMaxLines: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF4F8FF),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF2FF), Color(0xFFF8FBFF), Color(0xFFF0F6FF)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -115,
              right: -100,
              child: IgnorePointer(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primary.withValues(alpha: 0.035),
                    border: Border.all(
                        color: _primary.withValues(alpha: 0.04), width: 28),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 360;
                  final padding = compact ? 16.0 : 24.0;
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding:
                        EdgeInsets.symmetric(horizontal: padding, vertical: 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 56)
                            .clamp(0.0, double.infinity),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 448),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(color: Colors.white),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primary.withValues(alpha: 0.08),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.volunteer_activism,
                                    size: 50, color: _primary),
                              ),
                              const SizedBox(height: 14),
                              const Text('DonGiv',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.2,
                                    color: _ink,
                                  )),
                              const SizedBox(height: 5),
                              const Text('Aplikasi Donasi & Relawan',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: _muted,
                                      height: 1.4)),
                              const SizedBox(height: 30),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(compact ? 20 : 26),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                      color: const Color(0xFFEAF0F9)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF214C8F)
                                          .withValues(alpha: 0.065),
                                      blurRadius: 32,
                                      offset: const Offset(0, 12),
                                    )
                                  ],
                                ),
                                child: AutofillGroup(
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Selamat Datang Kembali',
                                            style: TextStyle(
                                              fontSize: compact ? 23 : 25,
                                              height: 1.25,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.6,
                                              color: _ink,
                                            )),
                                        const SizedBox(height: 10),
                                        const Text(
                                            'Masuk untuk melanjutkan aktivitas donasi dan relawan Anda.',
                                            style: TextStyle(
                                                fontSize: 14,
                                                height: 1.55,
                                                color: _muted)),
                                        const SizedBox(height: 26),
                                        const Text('Email',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: _ink)),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _emailController,
                                          readOnly: _isLoading,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.email
                                          ],
                                          autocorrect: false,
                                          textCapitalization:
                                              TextCapitalization.none,
                                          style: const TextStyle(
                                              fontSize: 15, color: _ink),
                                          decoration: _inputDecoration(
                                              hint: 'nama@email.com',
                                              icon: Icons.email_outlined),
                                          onFieldSubmitted: (_) =>
                                              FocusScope.of(context)
                                                  .nextFocus(),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Email wajib diisi';
                                            }
                                            if (!RegExp(
                                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                                .hasMatch(value)) {
                                              return 'Email tidak valid';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 20),
                                        const Text('Password',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: _ink)),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _passwordController,
                                          readOnly: _isLoading,
                                          obscureText: !_showPassword,
                                          keyboardType:
                                              TextInputType.visiblePassword,
                                          textInputAction: TextInputAction.done,
                                          autofillHints: const [
                                            AutofillHints.password
                                          ],
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          style: const TextStyle(
                                              fontSize: 15, color: _ink),
                                          decoration: _inputDecoration(
                                            hint: 'Masukkan password Anda',
                                            icon: Icons.lock_outline,
                                            suffix: IconButton(
                                              tooltip: _showPassword
                                                  ? 'Sembunyikan password'
                                                  : 'Tampilkan password',
                                              onPressed: () => setState(() =>
                                                  _showPassword =
                                                      !_showPassword),
                                              icon: Icon(
                                                  _showPassword
                                                      ? Icons
                                                          .visibility_outlined
                                                      : Icons
                                                          .visibility_off_outlined,
                                                  color: _muted,
                                                  size: 21),
                                            ),
                                          ),
                                          onFieldSubmitted: (_) => _login(),
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Password wajib diisi';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 26),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed:
                                                _isLoading ? null : _login,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _primary,
                                              foregroundColor: Colors.white,
                                              disabledBackgroundColor: _primary
                                                  .withValues(alpha: 0.7),
                                              disabledForegroundColor:
                                                  Colors.white,
                                              minimumSize:
                                                  const Size.fromHeight(54),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 16),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          14)),
                                              textStyle: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            child: _isLoading
                                                ? Semantics(
                                                    liveRegion: true,
                                                    label: 'Sedang masuk',
                                                    child: const SizedBox(
                                                        width: 22,
                                                        height: 22,
                                                        child:
                                                            CircularProgressIndicator(
                                                                strokeWidth:
                                                                    2.5,
                                                                color: Colors
                                                                    .white)),
                                                  )
                                                : const Text('Masuk'),
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Center(
                                          child: Wrap(
                                            alignment: WrapAlignment.center,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              const Text('Belum punya akun?',
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: _muted)),
                                              TextButton(
                                                onPressed: _isLoading
                                                    ? null
                                                    : () => Navigator
                                                        .pushReplacementNamed(
                                                            context,
                                                            '/register'),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: _primary,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 12),
                                                  textStyle: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                child: const Text(
                                                    'Daftar sekarang'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                  'Langkah kecil Anda, harapan besar bagi sesama.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12,
                                      height: 1.5,
                                      color: _muted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
