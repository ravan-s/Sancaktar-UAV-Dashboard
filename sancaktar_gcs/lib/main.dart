import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'controllers/uav_controller.dart';
import 'controllers/auth_controller.dart';
import 'views/screens/loading_screen.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/log_screen.dart';
import 'views/screens/fleet_selection_screen.dart';
import 'views/screens/desktop_cockpit.dart';

bool get isLinuxDesktop =>
    defaultTargetPlatform == TargetPlatform.linux && !kIsWeb;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isLinuxDesktop) {
    // Linux: Firebase SDK yok, REST kullanılıyor
    Get.put(UavController(), permanent: true);
  } else {
    // Mobil: Firebase SDK
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Get.put(AuthController(), permanent: true);
    Get.put(UavController(), permanent: true);
  }

  runApp(const SancaktarGCS());
}

class SancaktarGCS extends StatelessWidget {
  const SancaktarGCS({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sancaktar GCS',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF030A12),
      ),
      home: isLinuxDesktop
          ? const DesktopCockpit()
          : StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return LoadingScreen();
                }
                return snapshot.hasData
                    ? const FleetSelectionScreen()
                    : const LoginScreen();
              },
            ),
      getPages: [
        GetPage(name: '/login',   page: () => const LoginScreen()),
        GetPage(name: '/fleet',   page: () => const FleetSelectionScreen()),
        GetPage(name: '/cockpit', page: () => const CommandCockpit()),
        GetPage(name: '/desktop', page: () => const DesktopCockpit()),
      ],
    );
  }
}

// ── COMMAND COCKPIT (Mobil) ───────────────────────────────────
class CommandCockpit extends StatelessWidget {
  const CommandCockpit({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<UavController>();
    return Scaffold(
      drawer: const FleetSidebar(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('SANCAKTAR GCS',
          style: TextStyle(fontSize: 14, letterSpacing: 3)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(ctrl),
                const SizedBox(height: 20),
                _map(ctrl),
                const SizedBox(height: 20),
                _telemetry(ctrl),
                const SizedBox(height: 30),
                _actions(ctrl),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(UavController ctrl) => Obx(() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('COMMAND COCKPIT', style: TextStyle(
        color: Colors.blue.shade200, fontSize: 18,
        letterSpacing: 2, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text('ACTIVE UNIT: ${ctrl.selectedUavId.value.isEmpty
        ? 'SEÇİM BEKLENİYOR'
        : ctrl.selectedUavId.value.toUpperCase()}',
        style: const TextStyle(color: Colors.blueAccent,
          fontSize: 12, fontWeight: FontWeight.w600)),
    ]));

  Widget _map(UavController ctrl) => Obx(() {
    final markers = ctrl.uavList.entries.map((e) {
      final sel = ctrl.selectedUavId.value == e.key;
      return Marker(
        point: LatLng(e.value.lat ?? 38.0285, e.value.lon ?? 32.5115),
        width: sel ? 90 : 60, height: sel ? 90 : 60,
        child: GestureDetector(
          onTap: () => ctrl.selectUav(e.key),
          child: Column(children: [
            Icon(Icons.navigation_sharp,
              color: sel ? Colors.redAccent : Colors.blueAccent,
              size: sel ? 40 : 25),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: Colors.black54,
                borderRadius: BorderRadius.circular(4)),
              child: Text(e.key.toUpperCase(), style: TextStyle(
                color: Colors.white, fontSize: sel ? 10 : 8,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal))),
          ])));
    }).toList();

    return Container(
      height: 400, width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(
              ctrl.currentUav?.lat ?? 38.0285,
              ctrl.currentUav?.lon ?? 32.5115),
            initialZoom: 15),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.sancaktar.gcs'),
            MarkerLayer(markers: markers),
          ])));
  });

  Widget _telemetry(UavController ctrl) => Obx(() {
    final uav = ctrl.currentUav;
    if (uav == null) return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0D1621),
        borderRadius: BorderRadius.circular(12)),
      child: const Center(child: Column(children: [
        CircularProgressIndicator(color: Colors.blue),
        SizedBox(height: 10),
        Text('VERİ BEKLENİYOR...', style: TextStyle(color: Colors.blueGrey)),
      ])));

    return Row(children: [
      Expanded(child: _statCard('ALTITUDE', uav.altitude.toStringAsFixed(1), 'METERS')),
      const SizedBox(width: 10),
      Expanded(child: _statCard('SPEED', uav.speed.toStringAsFixed(1), 'M/S')),
      const SizedBox(width: 10),
      Expanded(child: _statCard('BATTERY', '%${uav.battery}', 'CAPACITY')),
    ]);
  });

  Widget _statCard(String label, String value, String unit) =>
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF0D1621),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.1))),
      child: Column(children: [
        Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 9)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white,
          fontSize: 22, fontWeight: FontWeight.bold)),
        Text(unit, style: const TextStyle(color: Colors.blueGrey, fontSize: 9)),
      ]));

  Widget _actions(UavController ctrl) => Column(children: [
    Row(children: [
      Expanded(child: _btn('TAKE OFF', Colors.blue,
        () => ctrl.sendCommand('TAKEOFF'))),
      const SizedBox(width: 15),
      Expanded(child: _btn('LAND', Colors.red,
        () => ctrl.sendCommand('LAND'))),
    ]),
    const SizedBox(height: 15),
    Row(children: [
      Expanded(child: _btn('RTL', Colors.orange,
        () => ctrl.sendCommand('RTL'))),
      const SizedBox(width: 15),
      Expanded(child: _btn('HOLD', Colors.grey,
        () => ctrl.sendCommand('HOLD'))),
    ]),
  ]);

  Widget _btn(String label, Color color, VoidCallback onPressed) =>
    OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      onPressed: onPressed,
      child: Text(label, style: TextStyle(
        color: color, fontWeight: FontWeight.bold)));
}

// ── FLEET SIDEBAR ─────────────────────────────────────────────
class FleetSidebar extends StatelessWidget {
  const FleetSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<UavController>();
    return Drawer(child: Container(
      color: const Color(0xFF0A1118),
      child: Column(children: [
        const DrawerHeader(child: Center(child: Text(
          'SANCAKTAR GCS\nFLEET MANAGEMENT',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.blue,
            fontWeight: FontWeight.bold, letterSpacing: 2)))),
        Expanded(child: Obx(() {
          if (ctrl.uavList.isEmpty) return const Center(
            child: Text('Aktif İHA bulunamadı.',
              style: TextStyle(color: Colors.grey)));
          return ListView.builder(
            itemCount: ctrl.uavList.length,
            itemBuilder: (_, i) {
              final id  = ctrl.uavList.keys.elementAt(i);
              final uav = ctrl.uavList[id]!;
              final sel = ctrl.selectedUavId.value == id;
              return ListTile(
                selected: sel,
                selectedTileColor: Colors.blue.withOpacity(0.1),
                leading: Icon(Icons.airplanemode_active,
                  color: sel ? Colors.blue : Colors.grey),
                title: Text(id.toUpperCase(),
                  style: TextStyle(
                    color: sel ? Colors.white : Colors.grey)),
                subtitle: Text('Batarya: %${uav.battery}',
                  style: const TextStyle(
                    fontSize: 11, color: Colors.blueGrey)),
                onTap: () {
                  ctrl.selectUav(id);
                  Navigator.pop(context);
                });
            });
        })),
      ])));
  }
}