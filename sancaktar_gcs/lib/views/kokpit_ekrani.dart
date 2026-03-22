import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/uav_controller.dart'; // Dosya yolun farklıysa burayı düzeltmeyi unutma

// --- ANA EKRAN (SAĞ VE SOLU BİRLEŞTİREN YAPI) ---
class KokpitEkrani extends StatelessWidget {
  const KokpitEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    // Beyni ekrana bağlıyoruz
    final UavController controller = Get.put(UavController());

    return Scaffold(
      backgroundColor: const Color(0xFF030A12), // Koyu askeri lacivert arka plan
      body: SafeArea(
        child: Row(
          children: [
            // 1. SOL TARAF: Filo Menüsü
            const FleetSidebar(),

            // 2. SAĞ TARAF: Ana Kokpit Göstergeleri
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(controller),
                    const SizedBox(height: 40), // Kamera olmadığı için burayı biraz açtık
                    _buildTelemetryRow(controller), // İrtifa, Hız, Batarya
                    const Spacer(),
                    _buildActionButtons(), // Kalkış ve İniş Butonları
                    const SizedBox(height: 10),
                    _buildVoiceCommand(), // Sesli Komut
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SAĞ TARAFIN YARDIMCI WIDGET'LARI ---

  Widget _buildHeader(UavController controller) {
    return Obx(() {
      // Seçili İHA'nın adını dinamik olarak ekrana yazdırıyoruz
      String activeUav = controller.selectedUavId.value.toUpperCase();
      if (activeUav.isEmpty) activeUav = "BEKLENİYOR...";

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SANCAKTAR KOMUTA MERKEZİ",
            style: TextStyle(
              color: Colors.blue.shade200,
              fontSize: 22,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "AKTİF BİRİM: $activeUav",
            style: const TextStyle(color: Colors.blueGrey, fontSize: 14),
          ),
        ],
      );
    });
  }

  Widget _buildTelemetryRow(UavController controller) {
    return Obx(() {
      // Veri yoksa uyarı göster
      if (controller.uavList.isEmpty || controller.currentUav == null) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1621),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.5)),
          ),
          child: const Center(
            child: Text(
              "SİNYAL BEKLENİYOR...", 
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 2)
            ),
          ),
        );
      }

      // Veri varsa seçili İHA'nın verilerini göster
      final uav = controller.currentUav!;

      return Row(
        children: [
          Expanded(child: _buildStatCard("İRTİFA", "${uav.telemetry.altitude}", "METRE")),
          const SizedBox(width: 15),
          Expanded(child: _buildStatCard("HIZ", "${uav.telemetry.speed}", "KM/S")),
          const SizedBox(width: 15),
          Expanded(child: _buildStatCard("BATARYA", "%${uav.telemetry.battery}", "KAPASİTE")),
        ],
      );
    });
  }

  Widget _buildStatCard(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1621),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(unit, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(child: _buildOutlinedButton("KALKIŞ (TAKE OFF)", Colors.blue)),
        const SizedBox(width: 15),
        Expanded(child: _buildOutlinedButton("İNİŞ (LAND)", Colors.red)),
      ],
    );
  }

  Widget _buildOutlinedButton(String label, Color color) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        print("$label butonuna basıldı!"); // Daha sonra buraya Firebase komut kodu eklenecek
      },
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildVoiceCommand() {
    return Center(
      child: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.mic_none, color: Colors.blueGrey),
        label: const Text("SESLİ KOMUT", style: TextStyle(color: Colors.blueGrey)),
      ),
    );
  }
}

// ============================================================================
// --- SOL MENÜ WIDGET'I (FİLO YÖNETİMİ) ---
// ============================================================================
class FleetSidebar extends StatelessWidget {
  const FleetSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller'ı tekrar buluyoruz
    final UavController controller = Get.find<UavController>();

    return Container(
      width: 250, // Menü genişliği
      color: const Color(0xFF0A1118),
      child: Column(
        children: [
          const SizedBox(height: 30),
          const Text(
            "FİLO YÖNETİMİ",
            style: TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.blueGrey, thickness: 0.5),
          
          Expanded(
            child: Obx(() {
              if (controller.uavList.isEmpty) {
                return const Center(child: Text("Aktif İHA Yok", style: TextStyle(color: Colors.grey)));
              }

              return ListView.builder(
                itemCount: controller.uavList.length,
                itemBuilder: (context, index) {
                  String uavId = controller.uavList.keys.elementAt(index);
                  final uav = controller.uavList[uavId]!;
                  bool isSelected = controller.selectedUavId.value == uavId;

                  return ListTile(
                    tileColor: isSelected ? Colors.blue.withOpacity(0.15) : Colors.transparent,
                    leading: Icon(
                      Icons.flight, 
                      color: isSelected ? Colors.blue : Colors.blueGrey,
                    ),
                    title: Text(
                      uavId.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Pil: %${uav.telemetry.battery} | İrtifa: ${uav.telemetry.altitude}",
                      style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                    ),
                    onTap: () {
                      // Tıklanan dronu aktif yap!
                      controller.selectUav(uavId);
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}