import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/drone_card.dart';

class FleetSelectionScreen extends StatelessWidget {
  const FleetSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Örnek Filo Verisi
    final List<Map<String, dynamic>> drones = [
     
      {'id': 1, 'name': 'TAŞIYICI', 'type': 'VTOL SURVEILLANCE', 'battery': 85, 'status': 'Active', 'mission': 'RECON'},
      {'id': 1, 'name': 'KAMİKAZE', 'type': 'VTOL SURVEILLANCE', 'battery': 85, 'status': 'Active', 'mission': 'RECON'},
      {'id': 1, 'name': 'İNSAN TAKİBİ', 'type': 'VTOL SURVEILLANCE', 'battery': 85, 'status': 'Active', 'mission': 'RECON'},
      {'id': 2, 'name': 'TUNA 1', 'type': 'CARGO DELIVERY', 'battery': 24, 'status': 'Active', 'mission': 'LOGISTICS'},
      {'id': 3, 'name': 'ALAN TARAMA', 'type': 'STEALTH SCANNER', 'battery': 98, 'status': 'Standby', 'mission': 'IDLE'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Çok koyu lacivert/siyah
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "FLEET SELECTION",
          style: TextStyle(color: Color(0xFF3B82F6), letterSpacing: 4, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text("SELECT UNIT TO COMMAND", style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 2)),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: drones.map((drone) => Padding(
                    padding: const EdgeInsets.only(right: 30),
                    child: DroneCard(
                      drone: drone,
                      onTap: () => Get.toNamed('/cockpit', arguments: drone),
                    ),
                  )).toList(),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 40.0),
            child: Text("SANCAKTAR GROUND CONTROL SYSTEM v2.0", style: TextStyle(color: Colors.white10, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}