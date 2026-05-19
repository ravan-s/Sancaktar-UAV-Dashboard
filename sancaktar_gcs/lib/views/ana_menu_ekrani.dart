import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/uav_controller.dart';
import 'screens/drone_detay_ekrani.dart';

class AnaMenuEkrani extends StatelessWidget {
  const AnaMenuEkrani({super.key});

  @override
  Widget build(BuildContext context) {
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
        if (controller.uavList.isEmpty) {
          return const Center(
            child: Text(
              "Dronlar Aranıyor...",
              style: TextStyle(color: Colors.blueGrey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.uavList.length,
          itemBuilder: (context, index) {
            final uavId = controller.uavList.keys.elementAt(index);
            final uav   = controller.uavList[uavId]!;

            return GestureDetector(
              onTap: () {
                controller.selectUav(uavId);
                Get.to(() => const DroneDetayEkrani());
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1621),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _getMissionColor(uavId).withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── ÜST KISIM ──────────────────────────────
                    Row(
                      children: [
                        Icon(
                          _getMissionIcon(uavId),
                          color: _getMissionColor(uavId),
                          size: 32,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                uavId.toUpperCase().replaceAll("_", " "),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                // ✅ uav.action (eski: uav.command.action)
                                "GÖREV: ${uav.action ?? 'BEKLEME'}",
                                style: TextStyle(
                                  color: _getMissionColor(uavId),
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Online / Offline göstergesi
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: uav.isOnline ? Colors.greenAccent : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── TELEMETRİ ÖZET ──────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniStat(
                          Icons.height,
                          "${uav.altitude.toStringAsFixed(1)}m",
                          Colors.blue,
                        ),
                        _buildMiniStat(
                          Icons.speed,
                          "${uav.speed.toStringAsFixed(1)}m/s",
                          Colors.orange,
                        ),
                        _buildMiniStat(
                          Icons.battery_charging_full,
                          "%${uav.battery}",
                          uav.battery > 20 ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── ALT KISIM: Durum Belirteçleri ───────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ✅ uav.isArmed (eski: uav.status.isArmed)
                        _buildStatusBadge(
                          uav.isArmed ? "ARMED" : "DISARMED",
                          uav.isArmed ? Colors.greenAccent : Colors.redAccent,
                        ),
                        // ✅ uav.connectionStrength (eski: uav.status.connectionStrength)
                        _buildStatusBadge(
                          "SINYAL %${uav.connectionStrength}",
                          uav.connectionStrength > 80
                              ? Colors.blue
                              : Colors.orange,
                        ),
                        // ✅ uav.flightMode (eski: uav.status.flightMode)
                        _buildStatusBadge(
                          uav.flightMode,
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

  // ── YARDIMCI WİDGET'LAR ─────────────────────────────

  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  // Dron ismine göre renk
  Color _getMissionColor(String uavId) {
    if (uavId.contains("kamikaze"))    return Colors.red;
    if (uavId.contains("tasiyici"))    return Colors.orange;
    if (uavId.contains("insan_takip")) return Colors.cyan;
    if (uavId.contains("alan_tarama")) return Colors.green;
    return Colors.blueGrey;
  }

  // Dron ismine göre ikon
  IconData _getMissionIcon(String uavId) {
    if (uavId.contains("kamikaze"))    return Icons.crisis_alert;
    if (uavId.contains("tasiyici"))    return Icons.local_shipping;
    if (uavId.contains("insan_takip")) return Icons.person_search;
    if (uavId.contains("alan_tarama")) return Icons.radar;
    return Icons.flight;
  }
}