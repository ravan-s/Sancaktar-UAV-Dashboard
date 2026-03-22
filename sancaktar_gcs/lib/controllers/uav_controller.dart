import 'package:get/get.dart';
import 'package:sancaktar_gcs/services/firebase_service.dart';
import '../models/uav_model.dart';


class UavController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  
  // Tüm İHA'lar burada duruyor (Senin attığın kısım)
  var uavList = <String, UavModel>{}.obs;

  // ŞU AN KONTROL ETTİĞİMİZ İHA (Yeni ekliyoruz)
  var selectedUavId = "".obs;

  // Seçili İHA'nın verilerine kolayca ulaşmak için bir "getter"
  UavModel? get currentUav => uavList[selectedUavId.value];

  @override
  void onInit() {
    super.onInit();
    _firebaseService.listenToUavs().listen((data) {
      uavList.value = data;
      
      // Eğer henüz hiç dron seçilmediyse, listedeki ilk dronu otomatik seç
      if (selectedUavId.value == "" && data.isNotEmpty) {
        selectedUavId.value = data.keys.first;
      }
    });
  }

  // Menüden dron değiştirmek için kullanacağız
  void selectUav(String id) {
    selectedUavId.value = id;
    print("Komuta Merkezi Aktarıldı: $id");
  }
}