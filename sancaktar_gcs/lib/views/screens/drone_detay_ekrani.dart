import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sancaktar_gcs/controllers/uav_controller.dart';

class DroneDetayEkrani extends StatelessWidget {
  const DroneDetayEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final UavController controller = Get.find();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F18),
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
        final uav = controller.currentUav;

        if (uav == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.cyan),
          );
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
                  _buildTelemetryCard(
                    "İRTİFA",
                    "${uav.altitude.toStringAsFixed(1)} m",
                    Icons.height,
                    Colors.blue,
                  ),
                  _buildTelemetryCard(
                    "HIZ",
                    "${uav.speed.toStringAsFixed(1)} m/s",
                    Icons.speed,
                    Colors.orange,
                  ),
                  _buildTelemetryCard(
                    "BATARYA",
                    "%${uav.battery}",
                    Icons.battery_charging_full,
                    uav.battery > 20 ? Colors.green : Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- 2. UYDU SINYALI & SINYAL GÜCÜ ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTelemetryCard(
                    "GPS FIX",
                    uav.gps_fix == 3 ? "3D" : "2D",
                    Icons.satellite,
                    uav.gps_fix == 3 ? Colors.green : Colors.yellow,
                  ),
                  _buildTelemetryCard(
                    "SINYAL",
                    "${uav.connectionStrength}%",
                    Icons.signal_cellular_alt,
                    uav.connectionStrength > 70 ? Colors.green : Colors.orange,
                  ),
                  _buildTelemetryCard(
                    "BATARYA V",
                    "${uav.battery_volt.toStringAsFixed(2)}V",
                    Icons.electrical_services,
                    Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- 3. RADAR / HARİTA ALANI ---
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1621),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.cyan.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        painter: RadarGridPainter(),
                        size: const Size(double.infinity, double.infinity),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.radar, color: Colors.cyan, size: 60),
                          const SizedBox(height: 10),
                          const Text(
                            "HARİTA / RADAR SİSTEMİ",
                            style: TextStyle(
                              color: Colors.cyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Konum bilgisi
                          if (uav.hasLocation)
                            Column(
                              children: [
                                Text(
                                  "Mevcut: ${uav.lat?.toStringAsFixed(6)}, ${uav.lon?.toStringAsFixed(6)}",
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          // Hedef konum (varsa)
                          if (uav.targetLat != null && uav.targetLon != null)
                            Text(
                              "Hedef: ${uav.targetLat?.toStringAsFixed(6)}, ${uav.targetLon?.toStringAsFixed(6)}",
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 11,
                              ),
                            )
                          else
                            const Text(
                              "Hedef konum belirtilmemiş",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- 4. KOMUT MERKEZİ ---
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
                    const Text(
                      "GÜNCEL GÖREV DURUMU",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Komut
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Komut",
                              style: TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                            Text(
                              uav.action ?? "BEKLEME",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // Armed durum
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: uav.isArmed
                                ? Colors.redAccent.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            uav.isArmed
                                ? "🔴 ARMED (AKTİF)"
                                : "🟢 DISARMED (PASİF)",
                            style: TextStyle(
                              color: uav.isArmed ? Colors.redAccent : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Uçuş modu
                    Row(
                      children: [
                        const Icon(Icons.flight_takeoff, color: Colors.cyan, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Mod: ${uav.flightMode}",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
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

  // Telemetri kartı widget'ı
  Widget _buildTelemetryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// Radar arkaplan çizgilerini çizen sınıf
class RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);

    // Daire çizgileri
    canvas.drawCircle(center, size.width * 0.2, paint);
    canvas.drawCircle(center, size.width * 0.4, paint);

    // Çapraz çizgiler
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}