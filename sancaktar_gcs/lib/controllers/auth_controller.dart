import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  static const String _adminCode = 'SANCAKTAR2025'; // ← YENİ

  var userAccessLevel = 0.obs;
  var userRole = "".obs;
  var isLoading = false.obs;
  var currentUid = "".obs;

  // ── GİRİŞ — DOKUNULMADI ──────────────────────────────────────
  Future<void> login(String username, String password) async {
    isLoading.value = true;
    try {
      String email = username.trim();
      if (!email.contains('@')) {
        email = "$email@gmail.com";
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password.trim(),
      );

      DataSnapshot snapshot = await _dbRef
          .child("users/${userCredential.user!.uid}")
          .get();

      if (snapshot.exists) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

        userAccessLevel.value =
            int.tryParse(data['access_level'].toString()) ?? 0;
        userRole.value = data['user'] ?? "guest";
        currentUid.value = userCredential.user!.uid;

        debugPrint('✅ accessLevel set edildi: ${userAccessLevel.value}');
        debugPrint('✅ uid set edildi: ${currentUid.value}');

        await Future.delayed(const Duration(milliseconds: 150));
        Get.offAllNamed('/fleet');
      } else {
        Get.snackbar("SİSTEM HATASI", "Kullanıcı veritabanında bulunamadı.");
      }
    } catch (e) {
      Get.snackbar(
        "GİRİŞ HATASI",
        "Kullanıcı adı veya şifre hatalı.",
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── KAYIT — YENİ ─────────────────────────────────────────────
  Future<void> register({
    required String email,
    required String password,
    required String username,
    required String adminCode,
  }) async {
    isLoading.value = true;
    try {
      final int level = adminCode.trim() == _adminCode ? 10 : 0;
      final String role = level == 10 ? "admin" : "guest";

      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await _dbRef.child("users/${cred.user!.uid}").set({
        'email': email.trim(),
        'user': username.trim(),
        'access_level': level,
        'role': role,
      });

      // login ile aynı sıra — önce set et, sonra navigate
      userAccessLevel.value = level;
      userRole.value = role;
      currentUid.value = cred.user!.uid;

      debugPrint('✅ Kayıt OK — uid: ${currentUid.value}, level: $level');

      Get.snackbar(
        '✅ KAYIT BAŞARILI',
        level == 10
            ? 'Yönetici hesabı oluşturuldu.'
            : 'Gözlemci hesabı oluşturuldu. Komut yetkiniz yoktur.',
        backgroundColor: level == 10
            ? const Color.fromARGB(255, 0, 25, 80).withOpacity(0.8)
            : const Color.fromARGB(255, 87, 20, 0).withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      await Future.delayed(const Duration(milliseconds: 150));
      Get.offAllNamed('/fleet');
    } on FirebaseAuthException catch (e) {
      final String msg = switch (e.code) {
        'email-already-in-use' => 'Bu e-posta zaten kayıtlı.',
        'weak-password' => 'Şifre en az 6 karakter olmalı.',
        'invalid-email' => 'Geçersiz e-posta adresi.',
        _ => 'Kayıt hatası: ${e.message}',
      };
      Get.snackbar(
        'KAYIT HATASI',
        msg,
        backgroundColor: const Color.fromARGB(255, 77, 5, 0).withOpacity(0.7),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── ŞİFREMİ UNUTTUM — YENİ ───────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    if (email.trim().isEmpty) {
      Get.snackbar('HATA', 'Lütfen e-posta adresinizi girin.');
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      Get.snackbar(
        '📧 MAIL GÖNDERİLDİ',
        'Şifre sıfırlama bağlantısı e-postanıza gönderildi.',
        backgroundColor: const Color.fromARGB(255, 0, 14, 92).withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'HATA',
        e.code == 'user-not-found'
            ? 'Bu e-posta ile kayıtlı hesap bulunamadı.'
            : 'Hata: ${e.message}',
        backgroundColor: const Color.fromARGB(255, 78, 5, 0).withOpacity(0.7),
        colorText: Colors.white,
      );
    }
  }

  // ── SESSION RESTORE — uygulama yeniden açılınca ───────────────
  var sessionReady = false.obs; // ← YENİ
  var minSplashDone = false.obs; // ← YENİ

  Future<void> loadUserFromSession(String uid) async {
    sessionReady.value = false;
    minSplashDone.value = false; // ← YENİ

    // 6sn timer ve DB sorgusu paralel çalışsın
    await Future.wait([
      _fetchUser(uid),
      Future.delayed(const Duration(seconds: 6), () {
        minSplashDone.value = true;
      }),
    ]);
  }

  // DB fetch ayrı metoda taşındı
  Future<void> _fetchUser(String uid) async {
    try {
      final snapshot = await _dbRef.child("users/$uid").get();
      if (snapshot.exists) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        userAccessLevel.value =
            int.tryParse(data['access_level'].toString()) ?? 0;
        userRole.value = data['user'] ?? "guest";
        currentUid.value = uid;
      }
    } catch (e) {
      debugPrint('❌ Session restore hatası: $e');
    } finally {
      sessionReady.value = true;
    }
  }

  // ── ÇIKIŞ — DOKUNULMADI ──────────────────────────────────────
  void logout() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
  }
}
