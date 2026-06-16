import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/drone_card.dart';
import '../../controllers/uav_controller.dart';
import '../../models/uav_model.dart';

class FleetSelectionScreen extends StatelessWidget {
  const FleetSelectionScreen({super.key});

  // Voltage → yüzde (hücre sayısı otomatik tespit)
  int _voltageToPercent(double voltage) {
    if (voltage <= 0) return 0;
    final cells = (voltage / 4.2).ceil().clamp(1, 12);
    final minV = cells * 3.5;
    final maxV = cells * 4.2;
    final percent = ((voltage - minV) / (maxV - minV) * 100).clamp(0, 100);
    return percent.round();
  }

  // Firebase drone ID → ekran adı
  String _droneDisplayName(String id) {
    switch (id) {
      case 'tuna_1':
        return 'NESNE TESPİT';
      case 'insan_takip':
        return 'İNSAN TAKİBİ';
      case 'alan_tarama':
        return 'ALAN TARAMA';
      case 'kamikaze':
        return 'KAMİKAZE';
      case 'tasiyici':
        return 'TAŞIYICI';
      default:
        return id.toUpperCase();
    }
  }

  String _droneType(String id) {
    switch (id) {
      case 'tuna_1':
        return 'OBJECT DETECTION';
      case 'insan_takip':
        return 'HUMAN TRACKING';
      case 'alan_tarama':
        return 'AREA SCANNER';
      case 'kamikaze':
        return 'ATTACK DRONE';
      case 'tasiyici':
        return 'CARGO CARRIER';
      default:
        return 'UAV';
    }
  }

  @override
  Widget build(BuildContext context) {
    final uavController = Get.find<UavController>();

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "FLEET SELECTION",
          style: TextStyle(
            color: Color(0xFF3B82F6),
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "SELECT UNIT TO COMMAND",
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          Expanded(
            child: Center(
              child: Obx(() {
                final uavMap = uavController.uavList;

                if (uavMap.isEmpty) {
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF3B82F6)),
                      SizedBox(height: 16),
                      Text(
                        'CONNECTING TO FIREBASE...',
                        style: TextStyle(
                          color: Colors.white38,
                          letterSpacing: 2,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                }

                // Sıralı gösterim için sabit sıra
                const droneOrder = [
                  'tasiyici',
                  'kamikaze',
                  'insan_takip',
                  'tuna_1',
                  'alan_tarama',
                ];

                final orderedIds = [
                  ...droneOrder.where((id) => uavMap.containsKey(id)),
                  ...uavMap.keys.where((id) => !droneOrder.contains(id)),
                ];

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: orderedIds.map((droneId) {
                      final UavModel uav = uavMap[droneId]!;
                      final int batteryPercent = uav.battery > 0
                          ? uav.battery
                          : _voltageToPercent(uav.battery_volt);

                      final drone = {
                        'id': droneId,
                        'name': _droneDisplayName(droneId),
                        'type': _droneType(droneId),
                        'battery': batteryPercent,
                        'status': uav.isArmed
                            ? 'ARMED'
                            : (uav.flightMode == 'STANDBY'
                                  ? 'Standby'
                                  : 'Active'),
                        'mission': uav.flightMode,
                        'altitude': uav.altitude,
                        'groundspeed': uav.speed,
                        'lat': uav.lat,
                        'lon': uav.lon,
                      };

                      return Padding(
                        padding: const EdgeInsets.only(right: 30),
                        child: DroneCard(
                          drone: drone,
                          onTap: () {
                            uavController.selectUav(droneId);
                            Get.toNamed('/cockpit', arguments: drone);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 40.0),
            child: Text(
              "SANCAKTAR GROUND CONTROL SYSTEM v2.0",
              style: TextStyle(color: Colors.white10, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
