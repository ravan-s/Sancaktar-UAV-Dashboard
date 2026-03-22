import 'package:firebase_database/firebase_database.dart';
import 'package:sancaktar_gcs/models/uav_model.dart';


class FirebaseService {
  // Firebase veritabanının ana referansını (kök dizinini) alıyoruz
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("");

  // İHA verilerini ANLIK (canlı) dinleyen Stream (Akış)
  Stream<Map<String, UavModel>> listenToUavs() {
    // Sadece 'uavs' klasörünü dinle
    return _dbRef.child('uavs').onValue.map((event) {
      final Map<String, UavModel> uavList = {};
      
      // Eğer veritabanı boş değilse
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        
        // Gelen JSON verisindeki her bir dronu (tuna_1, kamikaze vb.) tek tek dön
        data.forEach((key, value) {
          // JSON verisini, az önce yazdığımız güvenli UavModel nesnesine çevir ve listeye ekle
          uavList[key.toString()] = UavModel.fromJson(value as Map<dynamic, dynamic>);
        });
      }
      
      return uavList; // Çevrilmiş İHA listesini Controller'a gönder
    });
  }
}