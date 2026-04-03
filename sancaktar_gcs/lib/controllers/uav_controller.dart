import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:sancaktar_gcs/controllers/auth_controller.dart'; 
import 'package:sancaktar_gcs/services/firebase_service.dart';
import '../models/uav_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_tts/flutter_tts.dart';

class UavController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthController _authController = Get.find<AuthController>();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final VoiceAssistant assistant = VoiceAssistant(); // Asistan burada
  
  final uavList = <String, UavModel>{}.obs; 
  final selectedUavId = "".obs;            
  final isListening = false.obs;           
  final lastWords = "".obs;    
  // Son uyarı zamanlarını tutan sözlükler
  final Map<String, DateTime> _lastBatteryWarningTime = {};
  final Map<String, DateTime> _lastAltitudeWarningTime = {};            

  UavModel? get currentUav {
    if (selectedUavId.value.isEmpty) return null;
    return uavList[selectedUavId.value];
  }

  @override
  void onInit() {
    super.onInit();
    _startListeningToFirebase();

    // 🕵️‍♂️ FAILSAFE TAKİPÇİSİ (Senin istediğin yapı)
    ever(uavList, (Map<String, UavModel> list) {
      list.forEach((id, uav) {
        _runFailSafeChecks(id, uav);
      });
    });
  }

  // 🛡️ KRİTİK KONTROLLER (Batarya %30 ve İrtifa 20m)
 void _runFailSafeChecks(String id, UavModel uav) {
    final battery = uav.telemetry.battery;
    final altitude = uav.telemetry.altitude;
    final now = DateTime.now();

    // 🔋 BATARYA KONTROLÜ (%30 Altı)
    if (battery <= 49) {
      // Eğer daha önce hiç uyarılmadıysa veya son uyarının üzerinden 1 dakika geçtiyse
      if (!_lastBatteryWarningTime.containsKey(id) || 
          now.difference(_lastBatteryWarningTime[id]!).inSeconds >= 40) {
        
        assistant.say("Dikkat! $id bataryası kritik seviyede. Yüzde $battery.");
        _lastBatteryWarningTime[id] = now; // Zamanı kaydet (Mühürle)
      }
    }

    // 🏔️ İRTİFA KONTROLÜ (20 Metre Üstü)
    if (altitude > 200) {
      if (!_lastAltitudeWarningTime.containsKey(id) || 
          now.difference(_lastAltitudeWarningTime[id]!).inMinutes >= 1) {
        
        assistant.say("Uyarı! $id irtifa sınırını aşıyor. Mevcut yükseklik ${altitude.toInt()} metre.");
        _lastAltitudeWarningTime[id] = now; // Zamanı kaydet (Mühürle)
      }
    }
  }

  // --- 1. TELEMETRİ VERİ AKIŞI ---
  void _startListeningToFirebase() {
    _firebaseService.listenToUavs().listen((data) {
      uavList.assignAll(data);
      
      if (uavList.isNotEmpty) {
        print("📡 Aktif Filo: ${uavList.keys.toList()}");

        if (selectedUavId.value.isEmpty) {
          if (uavList.containsKey("tuna_1")) {
            selectedUavId.value = "tuna_1";
          } else {
            selectedUavId.value = uavList.keys.first;
          }
          print("✅ Otomatik Seçilen İHA: ${selectedUavId.value}");
        } 
        else if (!uavList.containsKey(selectedUavId.value)) {
          selectedUavId.value = uavList.keys.first;
        }
      }
    }, onError: (error) {
      print("🚨 TELEMETRİ AKIŞ HATASI: $error");
    });
  }

  // --- 2. KOMUT GÖNDERME ---
  void sendCommand(String commandType) {
    if (selectedUavId.isEmpty) {
      Get.snackbar("HATA", "Lütfen bir İHA seçin.", 
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.withOpacity(0.5));
      return;
    }

    if (_authController.userAccessLevel.value >= 5) {
      _firebaseService.sendUavCommand(selectedUavId.value, commandType);
      Get.snackbar("KOMUT", "${selectedUavId.value} -> $commandType",
          snackPosition: SnackPosition.BOTTOM, colorText: Colors.white);
    } else {
      Get.snackbar("YETKİSİZ", "Bu işlem için seviye 5 yetki gereklidir.");
    }
  }

  // --- 3. KONUM GÖNDERME ---
 // --- 3. KONUM GÖNDERME (Manuel Giriş) ---
 // --- 3. KONUM GÖNDERME (Manuel Giriş - Güncellenmiş) ---
  // --- 3. KONUM GÖNDERME (Manuel Giriş - Nihai Versiyon) ---
  void sendTargetPosition(double lat, double lng) {
    // 🔍 1. KONTROL: İHA Seçili mi?
    if (selectedUavId.isEmpty) {
      Get.snackbar("HATA", "Lütfen önce bir İHA seçin.",
          backgroundColor: Colors.redAccent.withOpacity(0.7), colorText: Colors.white);
      return;
    }

    // 🔍 2. KONTROL: Yetki Seviyesi (Seviye 4)
    if (_authController.userAccessLevel.value >= 4) {
      
      // 🚀 ASIL İŞLEM: Firebase'e yazma
      FirebaseDatabase.instance.ref()
          .child(selectedUavId.value)
          .child('telemetry')
          .child('target_waypoint')
          .set({
        'lat': lat,
        'lon': lng,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }).then((_) {
        // 🔥 KRİTİK EKLEME: Dialog kapandıktan sonra bildirimin görünmesi için 600ms bekleme
        Future.delayed(const Duration(milliseconds: 600), () {
          if (Get.isSnackbarOpen) Get.back(); // Eğer açıkta kalan başka bildirim varsa temizle
          
          Get.snackbar(
            "📍 HEDEF TANIMLANDI", 
            "İHA: ${selectedUavId.value.toUpperCase()}\nKoordinat: $lat, $lng",
            duration: const Duration(seconds: 5), // 5 saniye ekranda kalsın
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.withOpacity(0.9),
            colorText: Colors.white,
            icon: const Icon(Icons.gps_fixed, color: Colors.white),
            margin: const EdgeInsets.all(15),
            borderColor: Colors.white.withOpacity(0.5),
            borderWidth: 1,
          );
        });

        // Sesli asistan ve terminal çıktısı
        print("✅ BAŞARILI: $lat, $lng Firebase'e yazıldı.");
        assistant.say("Yeni hedef koordinatlar manuel olarak iletildi.");

      }).catchError((error) {
        print("❌ Firebase Yazma Hatası: $error");
        Get.snackbar("BAĞLANTI HATASI", "Veri gönderilemedi: $error", backgroundColor: Colors.red);
      });

    } else {
      // Yetki hatası
      Get.snackbar(
        "YETKİSİZ", 
        "Bu işlem için seviye 4 yetki gereklidir. Mevcut: ${_authController.userAccessLevel.value}",
        backgroundColor: Colors.orangeAccent, 
        colorText: Colors.black,
        duration: const Duration(seconds: 4)
      );
    }
  }
  // --- 4. SESLİ KOMUT SİSTEMİ 
  void toggleListening() async {
    if (!isListening.value) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == "done" || status == "notListening") isListening.value = false;
        },
        onError: (error) => isListening.value = false,
      );

      if (available) {
        isListening.value = true;
        lastWords.value = "Dinleniyor...";
        _speech.listen(
          onResult: (result) {
            lastWords.value = result.recognizedWords;
            if (result.finalResult) {
               _processVoiceCommand(result.recognizedWords.toLowerCase());
            }
          },
          localeId: "tr_TR",
        );
      }
    } else {
      _stopVoiceAndReset();
    }
  }
  
  void _stopVoiceAndReset() {
    isListening.value = false;
    _speech.stop();
  }

  void _processVoiceCommand(String command) {
    final cmd = command.toLowerCase();
    
    if (cmd.contains("kalkış") || cmd.contains("havalan")) {
      assistant.say("Anlaşıldı Kaptan. Tuna bir havalanıyor. İrtifa artırılıyor, tüm sistemler nominal.");
      sendCommand("TAKEOFF");
    } 
    else if (cmd.contains("iniş") || cmd.contains("çök")) {
      assistant.say("İniş protokolü başlatıldı. Güvenli bölgeye alçalınıyor. Gözünüz sahada olsun.");
      sendCommand("LAND");
    }
    else if (cmd.contains("konum") || cmd.contains("hedefle")) {
      assistant.say("Yeni görev koordinatları İHA'ya iletildi. Hedef Konya Teknik Üniversitesi.");
    }
    else if (cmd.contains("eve dön") || cmd.contains("merkez")) {
      assistant.say("Görev iptal edildi. Ana üsse geri dönüş rotası oluşturuluyor.");
      sendCommand("RTL");
    }
    else if (cmd.contains("acil") || cmd.contains("iptal")) {
      assistant.say("Kritik uyarı! Tüm operasyon durduruldu. Acil durum moduna geçiliyor!");
      sendCommand("EMERGENCY");
    }
  }

  void selectUav(String id) {
    if (uavList.containsKey(id)) {
      selectedUavId.value = id;
    }
  }

  Future<void> sendWaypointToUav(double lat, double lng) async {
    if (selectedUavId.value.isEmpty) return;
    try {
      await FirebaseDatabase.instance.ref()
          .child(selectedUavId.value)
          .child('telemetry')
          .child('target_waypoint')
          .set({
        'lat': lat,
        'lon': lng,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      assistant.say("Yeni koordinatlar gönderildi.");
    } catch (e) {
      print("Hata: $e");
    }
  }
}

class VoiceAssistant {
  final FlutterTts _tts = FlutterTts();
  VoiceAssistant() {
    _tts.setLanguage("tr-TR");
    _tts.setPitch(1.0);
    _tts.setSpeechRate(0.5);
  }
  Future<void> say(String text) async {
    await _tts.speak(text);
  }
}