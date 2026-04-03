import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'firebase_options.dart';
import 'controllers/uav_controller.dart';
import 'controllers/auth_controller.dart';
import 'views/screens/loading_screen.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/fleet_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Get.put(AuthController());
  Get.put(UavController());

  runApp(const SancaktarGCS());
}

class SancaktarGCS extends StatelessWidget {
  const SancaktarGCS({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF030A12),
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => LoadingScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/fleet', page: () => const FleetSelectionScreen()),
        GetPage(name: '/cockpit', page: () => const CommandCockpit()),
      ],
    );
  }
}

class CommandCockpit extends StatelessWidget {
  const CommandCockpit({super.key});

  @override
  Widget build(BuildContext context) {
    final UavController controller = Get.find<UavController>();

    return Scaffold(
      drawer: const FleetSidebar(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("SANCAKTAR GCS", style: TextStyle(fontSize: 14, letterSpacing: 3)),
        centerTitle: true,
      ),
      body: SafeArea(
        // 1. TAŞMA KORUMASI: Tüm ekranı kaydırılabilir yaptık!
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(controller),
                const SizedBox(height: 20),
                _buildMapView(controller),
                const SizedBox(height: 20),
                _buildTelemetryRow(controller),
                // Spacer() yerine sabit boşluk koyduk (Çünkü SingleChildScrollView içinde Spacer çökertir)
                const SizedBox(height: 30), 
                _buildActionButtons(controller),
                const SizedBox(height: 10),
                _buildVoiceCommand(controller),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UavController controller) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "COMMAND COCKPIT",
          style: TextStyle(color: Colors.blue.shade200, fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "ACTIVE UNIT: ${controller.selectedUavId.value.isEmpty ? "SEÇİM BEKLENİYOR" : controller.selectedUavId.value.toUpperCase()}",
          style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ));
  }

  Widget _buildMapView(UavController controller) {
    return Obx(() {
      List<Marker> allMarkers = [];

      controller.uavList.forEach((id, uav) {
        bool isSelected = controller.selectedUavId.value == id;

        allMarkers.add(
          Marker(
            point: LatLng(uav.command.targetLat, uav.command.targetLon),
            width: isSelected ? 90: 60,
            height: isSelected ? 90: 60,
            child: GestureDetector(
              onTap: () => controller.selectUav(id),
              child: Column(
                children: [
                  Icon(
                    Icons.navigation_sharp,
                    color: isSelected ? Colors.redAccent : Colors.blueAccent,
                    size: isSelected ? 40 : 25,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      id.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSelected ? 10 : 8,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });

      double centerLat = controller.currentUav?.command.targetLat ?? 38.0285;
      double centerLon = controller.currentUav?.command.targetLon ?? 32.5115;

      return Container(
        height: 400,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(centerLat, centerLon),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sancaktar.gcs',
              ),
              MarkerLayer(markers: allMarkers),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTelemetryRow(UavController controller) {
    return Obx(() {
      final uav = controller.currentUav;

      if (uav == null) {
        return Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1621),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: Colors.blue),
                SizedBox(height: 10),
                Text("VERİ BEKLENİYOR...", style: TextStyle(color: Colors.blueGrey)),
              ],
            ),
          ),
        );
      }

      return Row(
        children: [
          Expanded(child: _buildStatCard("ALTITUDE", uav.telemetry.altitude.toStringAsFixed(1), "METERS")),
          const SizedBox(width: 10),
          Expanded(child: _buildStatCard("SPEED", uav.telemetry.speed.toStringAsFixed(1), "KM/H")),
          const SizedBox(width: 10),
          Expanded(child: _buildStatCard("BATTERY", "%${uav.telemetry.battery}", "CAPACITY")),
        ],
      );
    });
  }

  Widget _buildStatCard(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1621),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 9)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(unit, style: const TextStyle(color: Colors.blueGrey, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(UavController controller) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOutlinedButton("TAKE OFF", Colors.blue, () => controller.sendCommand("TAKEOFF")),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildOutlinedButton("LAND", Colors.red, () => controller.sendCommand("LAND")),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildOutlinedButton(
                "MANUEL HEDEF GİR", 
                Colors.greenAccent, 
                () => _showManualCoordinateDialog(controller)
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showManualCoordinateDialog(UavController controller) {
    TextEditingController latController = TextEditingController();
    TextEditingController lngController = TextEditingController();

    Get.defaultDialog(
      title: "MANUEL KOORDİNAT GİRİŞİ",
      titleStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      backgroundColor: const Color(0xFF0D1621),
      // 2. TAŞMA KORUMASI: Klavye açılınca pencerenin taşmasını engelledik
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.greenAccent),
              decoration: const InputDecoration(
                labelText: "Enlem (Latitude) - Örn: 39.9250",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueGrey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: lngController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.greenAccent),
              decoration: const InputDecoration(
                labelText: "Boylam (Longitude) - Örn: 32.8500",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueGrey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
              ),
            ),
          ],
        ),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text("İPTAL", style: TextStyle(color: Colors.grey)),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
        onPressed: () {
          double? lat = double.tryParse(latController.text.replaceAll(',', '.'));
          double? lng = double.tryParse(lngController.text.replaceAll(',', '.'));

          if (lat != null && lng != null) {
            Get.back();
            controller.sendWaypointToUav(lat, lng); 
          } else {
            Get.snackbar(
              "GEÇERSİZ FORMAT", 
              "Lütfen sadece rakam ve nokta kullanın!", 
              backgroundColor: Colors.orange, 
              colorText: Colors.white,
            );
          }
        },
        child: const Text("KOORDİNATI GÖNDER", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildOutlinedButton(String label, Color color, VoidCallback onPressed) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildVoiceCommand(UavController controller) {
    return Obx(() => Center(
      child: Column(
        children: [
          if (controller.isListening.value)
            Text("Duyulan: ${controller.lastWords.value}", style: const TextStyle(color: Colors.blue, fontSize: 10)),
          TextButton.icon(
            onPressed: () => controller.toggleListening(),
            icon: Icon(
              controller.isListening.value ? Icons.mic : Icons.mic_none, 
              color: controller.isListening.value ? Colors.red : Colors.blueGrey
            ),
            label: Text(
              controller.isListening.value ? "DİNLİYORUM..." : "VOICE COMMAND", 
              style: TextStyle(color: controller.isListening.value ? Colors.red : Colors.blueGrey)
            ),
          ),
        ],
      ),
    ));
  }
}

class FleetSidebar extends StatelessWidget {
  const FleetSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final UavController controller = Get.find<UavController>();

    return Drawer(
      child: Container(
        color: const Color(0xFF0A1118),
        child: Column(
          children: [
            const DrawerHeader(
              child: Center(
                child: Text("SANCAR GCS\nFLEET MANAGEMENT", 
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.uavList.isEmpty) {
                  return const Center(child: Text("Aktif İHA bulunamadı.", style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  itemCount: controller.uavList.length,
                  itemBuilder: (context, index) {
                    String uavId = controller.uavList.keys.elementAt(index);
                    final uav = controller.uavList[uavId]!;
                    bool isSelected = controller.selectedUavId.value == uavId;

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: Colors.blue.withOpacity(0.1),
                      leading: Icon(Icons.airplanemode_active, color: isSelected ? Colors.blue : Colors.grey),
                      title: Text(uavId.toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : Colors.grey)),
                      subtitle: Text("Batarya: %${uav.telemetry.battery}", style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                      onTap: () {
                        controller.selectUav(uavId);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}