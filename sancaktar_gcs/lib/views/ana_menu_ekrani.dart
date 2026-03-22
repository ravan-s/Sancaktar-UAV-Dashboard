import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/uav_controller.dart';
import 'screens/drone_detay_ekrani.dart';// (Eğer dosyan screens klasöründe değil de views klasöründeyse 'views/drone_detay_ekrani.dart' yap)
class AnaMenuEkrani extends StatelessWidget {
  const AnaMenuEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller'ı (Beyni) ekrana bağlıyoruz
    final UavController controller = Get.put(UavController());

    return Scaffold(
      backgroundColor: const Color(0xFF030A12),
      appBar: AppBar(
        title: const Text("FİLO DURUMU", style: TextStyle(letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A1118),
        elevation: 0,
      ),
      body: Obx(() {
        // Eğer Firebase'den veri gelmediyse yükleniyor animasyonu göster
        if (controller.uavList.isEmpty) {
          return const Center(
            child: Text("Dronlar Aranıyor...", style: TextStyle(color: Colors.blueGrey)),
          );
        }

        // Firebase'deki dronları liste olarak ekrana basıyoruz
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.uavList.length, // Firebase'de 5 dron varsa 5 kutu çizer
          itemBuilder: (context, index) {
            String uavId = controller.uavList.keys.elementAt(index);
            final uav = controller.uavList[uavId]!;

            // ... (Önceki kodların aynı kalacak, sadece Container kısmını değiştiriyoruz)
            // ... (Üst kısımlar aynı kalıyor, Scaffold ve ListView.builder kısımları)

           return GestureDetector(
              onTap: () {
                controller.selectUav(uavId); // Dronu seç
                Get.to(() => const DroneDetayEkrani()); // Detay ekranına fırla!
              },
// ...
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1621),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    // Renkleri artık DRON İSMİNE göre alıyoruz
                    color: _getMissionColor(uavId).withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ÜST KISIM
                    Row(
                      children: [
                        Icon(
                          _getMissionIcon(uavId), // İkonlar DRON İSMİNE göre
                          color: _getMissionColor(uavId),
                          size: 32,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                uavId.toUpperCase().replaceAll("_", " "), // alt tireyi boşluk yap
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                // Görev tipi yerine dronun anlık ACTION (Eylem) komutunu yazdırıyoruz!
                                "GÖREV: ${uav.command.action}",
                                style: TextStyle(color: _getMissionColor(uavId), fontSize: 12, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // ALT KISIM: Durum Belirteçleri
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusBadge("ARM", uav.status.isArmed ? Colors.greenAccent : Colors.redAccent),
                        _buildStatusBadge("BAĞLANTI", uav.status.connectionStrength > 80 ? Colors.blue : Colors.orange),
                        _buildStatusBadge(
                          "UÇUŞ MODU: ${uav.status.flightMode}", 
                          Colors.purpleAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // --- YARDIMCI FONKSİYONLAR (YENİ JSON'A GÖRE DÜZENLENDİ) ---

  // Dron ismine göre renk verir
  Color _getMissionColor(String uavId) {
    if (uavId.contains("kamikaze")) return Colors.red;
    if (uavId.contains("tasiyici")) return Colors.orange;
    if (uavId.contains("insan_takip")) return Colors.cyan;
    if (uavId.contains("alan_tarama")) return Colors.green;
    return Colors.blueGrey; // tuna_1 ve diğerleri için varsayılan
  }

  // Dron ismine göre ikon verir
  IconData _getMissionIcon(String uavId) {
    if (uavId.contains("kamikaze")) return Icons.crisis_alert;
    if (uavId.contains("tasiyici")) return Icons.local_shipping;
    if (uavId.contains("insan_takip")) return Icons.person_search;
    if (uavId.contains("alan_tarama")) return Icons.radar;
    return Icons.flight;
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}