import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sancaktar_gcs/controllers/uav_controller.dart';


class DroneDetayEkrani extends StatelessWidget {
  const DroneDetayEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller'ı bul
    final UavController controller = Get.find();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F18), // Taktiksel koyu arka plan
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1621),
        title: Obx(() => Text(
          "${controller.selectedUavId.value.toUpperCase()} KONTROL PANELİ",
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        )),
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(() {
        // Seçili dronun canlı verisini al
        final uav = controller.currentUav;

        if (uav == null) {
          return const Center(child: CircularProgressIndicator(color: Colors.cyan));
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. TELEMETRİ PANELİ (Hız, İrtifa, Batarya) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTelemetryCard("İRTİFA", "${uav.telemetry.altitude} m", Icons.height, Colors.blue),
                  _buildTelemetryCard("HIZ", "${uav.telemetry.speed} m/s", Icons.speed, Colors.orange),
                  _buildTelemetryCard("BATARYA", "%${uav.telemetry.battery}", Icons.battery_charging_full, 
                    uav.telemetry.battery > 20 ? Colors.green : Colors.red),
                ],
              ),
              const SizedBox(height: 20),

              // --- 2. RADAR / HARİTA ALANI (Şimdilik yer tutucu, buraya harita gelecek) ---
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1621),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radar ızgarası efekti (Görsel şölen)
                      CustomPaint(painter: RadarGridPainter(), size: const Size(double.infinity, double.infinity)),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.radar, color: Colors.cyan, size: 60),
                          const SizedBox(height: 10),
                          const Text(
                            "HARİTA / RADAR SİSTEMİ ÇEVRİMDIŞI",
                            style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Hedef Koordinat: ${uav.command.targetLat}, ${uav.command.targetLon}",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- 3. KOMUT MERKEZİ ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1621),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("GÜNCEL GÖREV DURUMU", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          uav.command.action,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: uav.status.isArmed ? Colors.redAccent.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            uav.status.isArmed ? "ARMED (SİLAHLI/AKTİF)" : "DISARMED (PASİF)",
                            style: TextStyle(color: uav.status.isArmed ? Colors.redAccent : Colors.green, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Telemetri kutucukları için yardımcı tasarım
  Widget _buildTelemetryCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: Get.width * 0.28,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1621),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }
}

// Radar arkaplan çizgilerini çizen sınıf (Görsellik için)
class RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.cyan.withOpacity(0.1)..style = PaintingStyle.stroke..strokeWidth = 1;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width * 0.2, paint);
    canvas.drawCircle(center, size.width * 0.4, paint);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}