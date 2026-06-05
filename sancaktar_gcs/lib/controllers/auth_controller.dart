import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // --- EKSİK OLAN DEĞİŞKENLER BURADA ---
  var userAccessLevel = 0.obs;
  var userRole = "".obs;
  var isLoading = false.obs;
  var currentUid = "".obs; // Hata veren eksik satır buydu!

  // Giriş yapma fonksiyonu
  Future<void> login(String username, String password) async {
    // Giriş başladığı için yükleme durumunu true yapıyoruz
    isLoading.value = true;

    try {
      // Kullanıcı adı hilesi
      String email = username.trim();
      if (!email.contains('@')) {
        email = "$email@gmail.com";
      }

      // Firebase girişi
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password.trim(),
      );

      // Veritabanından yetki kontrolü
      DataSnapshot snapshot = await _dbRef
          .child("users/${userCredential.user!.uid}")
          .get();

      if (snapshot.exists) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        userAccessLevel.value =
            int.tryParse(data['access_level'].toString()) ?? 1;
        userRole.value = data['role'] ?? "guest";
        currentUid.value = userCredential.user!.uid;

        Get.offAllNamed('/fleet'); // Yeni hali bu olmalı
        // Giriş başarılı, Kokpit'e uçuyoruz
        debugPrint('🔑 RAW data: $data');
        debugPrint('🔑 access_level raw: ${data['access_level']}');
        debugPrint('🔑 access_level type: ${data['access_level'].runtimeType}');

        userAccessLevel.value =
            int.tryParse(data['access_level'].toString()) ?? 1;
        userRole.value = data['role'] ?? "guest";
        currentUid.value = userCredential.user!.uid;

        debugPrint('🔑 userAccessLevel after set: ${userAccessLevel.value}');

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
      // Giriş denemesi bitti (başarılı veya başarısız), yükleme çarkını durdur
      isLoading.value = false;
    }
  }

  // Çıkış Fonksiyonu
  void logout() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
  }
}
