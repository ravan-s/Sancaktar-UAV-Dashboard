import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:get/get.dart';
import 'controllers/uav_controller.dart';
import 'views/ana_menu_ekrani.dart'; // Kendi dosya ismine göre düzelt
 // Eğer farklı bir klasördeyse yolunu ona göre düzelt (örn: 'controllers/uav_controller.dart')
void main() async {
  // 1. Flutter bağlayıcılarını hazırla
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Firebase'i başlat (Hata almamak için await ile bekliyoruz)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SancaktarGCS());
}

class SancaktarGCS extends StatelessWidget {
  const SancaktarGCS({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( // Sayfa geçişleri için MaterialApp yerine GetMaterialApp yapıyoruz!
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const AnaMenuEkrani(), // İLK AÇILACAK EKRAN
    );
  }
}

// --- SENİN FİGMA TASARIMININ OLDUĞU SINIF BURADAN BAŞLIYOR ---
class CommandCockpit extends StatelessWidget {
  const CommandCockpit({super.key});

@override
  Widget build(BuildContext context) {
    // BEYNİ (KONTROLCÜYÜ) KOKPİTE BAĞLIYORUZ
    final UavController controller = Get.put(UavController());
    return Scaffold(
      backgroundColor: const Color(0xFF030A12), // Koyu lacivert arka plan
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildFPVView(), // İHA Kamerası simülasyonu
              const SizedBox(height: 20),
              _buildTelemetryRow(), // İrtifa ve Hız kartları
              const Spacer(),
              _buildActionButtons(), // Take Off ve Land butonları
              const SizedBox(height: 10),
              _buildVoiceCommand(), 
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "COMMAND COCKPIT",
          style: TextStyle(
            color: Colors.blue.shade200,
            fontSize: 18,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "ACTIVE UNIT: TUNA SURVEILLANCE",
          style: TextStyle(color: Colors.blueGrey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFPVView() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        // Placeholder resim: İnternet varsa gözükür, yoksa siyah kutu kalır
        image: const DecorationImage(
          image: NetworkImage("https://images.unsplash.com/photo-1508614589041-895b88991e3e?q=80&w=1000&auto=format&fit=crop"),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20, left: 20,
            child: Container(
              padding: const EdgeInsets.all(4),
              color: Colors.black54,
              child: const Text("REC ● 00:12:45", style: TextStyle(color: Colors.red, fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildTelemetryRow() {
    final UavController controller = Get.find<UavController>();

    return Obx(() {
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

      final uav = controller.currentUav!;

      // İŞTE BURASI DÜZELDİ: uav.telemetry.altitude ve uav.telemetry.speed
      return Row(
        children: [
          Expanded(child: _buildStatCard("ALTITUDE", "${uav.telemetry.altitude}", "METERS")),
          const SizedBox(width: 15),
          Expanded(child: _buildStatCard("SPEED", "${uav.telemetry.speed}", "KM/H")),
          const SizedBox(width: 15),
          Expanded(child: _buildStatCard("BATTERY", "%${uav.telemetry.battery}", "CAPACITY")),
        ],
      );
    });
  }
  Widget _buildStatCard(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1621),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          Text(unit, style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(child: _buildOutlinedButton("TAKE OFF", Colors.blue)),
        const SizedBox(width: 15),
        Expanded(child: _buildOutlinedButton("LAND", Colors.red)),
      ],
    );
  }

  Widget _buildOutlinedButton(String label, Color color) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        print("$label komutu gönderildi!");
      },
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildVoiceCommand() {
    return Center(
      child: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.mic_none, color: Colors.blueGrey),
        label: const Text("VOICE COMMAND", style: TextStyle(color: Colors.blueGrey)),
      ),
    );
  }
}
class FleetSidebar extends StatelessWidget {
  const FleetSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final UavController controller = Get.find<UavController>();

    return Container(
      width: 250, // Menünün genişliği
      color: const Color(0xFF0A1118), // Ana ekrandan bir tık daha farklı koyu lacivert
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
          
          // İHA Listesi (Canlı güncellenir)
          Expanded(
            child: Obx(() {
              if (controller.uavList.isEmpty) {
                return const Center(
                  child: Text("Aktif İHA Yok", style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                itemCount: controller.uavList.length,
                itemBuilder: (context, index) {
                  // Listedeki İHA'nın ID'sini ve verisini alıyoruz
                  String uavId = controller.uavList.keys.elementAt(index);
                  final uav = controller.uavList[uavId]!;
                  
                  // Bu İHA şu an seçili olan mı?
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
                      "Pil: %${uav.telemetry.battery}",
                      style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                    ),
                    onTap: () {
                      // Menüden başka bir İHA'ya tıklanınca beyni güncelliyoruz
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