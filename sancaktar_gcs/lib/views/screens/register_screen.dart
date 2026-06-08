import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sancaktar_gcs/controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _adminCodeCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _obscureCode = true;

  final AuthController _auth = Get.find<AuthController>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _adminCodeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    final code = _adminCodeCtrl.text.trim();

    if (email.isEmpty || username.isEmpty || password.isEmpty) {
      Get.snackbar(
        'HATA',
        'Lütfen tüm zorunlu alanları doldurun.',
        backgroundColor: const Color.fromARGB(255, 177, 12, 0).withOpacity(0.7),
        colorText: Colors.white,
      );
      return;
    }
    if (password != confirm) {
      Get.snackbar(
        'HATA',
        'Şifreler eşleşmiyor.',
        backgroundColor: const Color.fromARGB(255, 182, 12, 0).withOpacity(0.7),
        colorText: Colors.white,
      );
      return;
    }
    if (password.length < 6) {
      Get.snackbar(
        'HATA',
        'Şifre en az 6 karakter olmalı.',
        backgroundColor: const Color.fromARGB(255, 170, 11, 0).withOpacity(0.7),
        colorText: Colors.white,
      );
      return;
    }

    _auth.register(
      email: email,
      password: password,
      username: username,
      adminCode: code,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'HESAP OLUŞTUR',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        if (_auth.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(255, 177, 0, 0),
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Başlık ikonu
              const Icon(
                Icons.person_add_alt_1,
                color: Color.fromARGB(255, 177, 0, 0),
                size: 56,
              ),
              const SizedBox(height: 24),

              _buildField(
                controller: _emailCtrl,
                label: 'E-Posta *',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _buildField(
                controller: _usernameCtrl,
                label: 'Kullanıcı Adı *',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              _buildField(
                controller: _passwordCtrl,
                label: 'Şifre *',
                icon: Icons.lock_outline,
                obscure: _obscurePassword,
                toggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 16),

              _buildField(
                controller: _confirmCtrl,
                label: 'Şifre Tekrar *',
                icon: Icons.lock_outline,
                obscure: _obscureConfirm,
                toggleObscure: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 24),

              // Yönetici kodu bölümü
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromARGB(
                      255,
                      168,
                      0,
                      0,
                    ).withOpacity(0.4),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color.fromARGB(255, 78, 0, 0).withOpacity(0.05),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: Color.fromARGB(255, 170, 0, 0),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'YÖNETİCİ KODU (Opsiyonel)',
                          style: TextStyle(
                            color: Color(0xFFA82200),
                            fontSize: 12,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kod girilmezse gözlemci yetkisiyle kayıt olursunuz.',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _adminCodeCtrl,
                      label: 'Yönetici Kodu',
                      icon: Icons.vpn_key_outlined,
                      obscure: _obscureCode,
                      toggleObscure: () =>
                          setState(() => _obscureCode = !_obscureCode),
                      borderColor: const Color.fromARGB(
                        255,
                        168,
                        0,
                        0,
                      ).withOpacity(0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Kayıt butonu
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA82200),
                  foregroundColor: const Color(0xFFFFFFFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'HESAP OLUŞTUR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  'Zaten hesabım var → Giriş yap',
                  style: TextStyle(color: Color.fromARGB(136, 182, 182, 184)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextInputType keyboardType = TextInputType.text,
    Color? borderColor,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white38,
                  size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor ?? Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor ?? Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: borderColor ?? const Color(0xFFA82200),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
