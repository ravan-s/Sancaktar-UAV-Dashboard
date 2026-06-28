import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sancaktar_gcs/views/screens/register_screen.dart';
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
    Get.put(UavController(), permanent: true); // AuthController YOK
  } else {
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
                // Firebase bağlantısı bekleniyor
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return LoadingScreen();
                }

                // Oturum yok → login
                if (!snapshot.hasData) return const LoginScreen();

                // Oturum VAR ama AuthController henüz dolmamış olabilir
                final auth = Get.find<AuthController>();
                final uid = snapshot.data!.uid;

                // Sadece bir kez çalıştır
                if (auth.currentUid.value.isEmpty) {
                  auth.loadUserFromSession(uid);
                }

                // sessionReady gelene kadar LoadingScreen göster
                return Obx(() {
                  // sessionReady false iken zaten Loading göster
                  if (!auth.sessionReady.value) return LoadingScreen();

                  // sessionReady true oldu ama 6sn geçti mi?
                  if (!auth.minSplashDone.value) return LoadingScreen();

                  return const FleetSelectionScreen();
                });
              },
            ),
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/fleet', page: () => const FleetSelectionScreen()),
        GetPage(name: '/cockpit', page: () => const CommandCockpit()),
        GetPage(name: '/desktop', page: () => const DesktopCockpit()),
        GetPage(name: '/register', page: () => const RegisterScreen()),
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
        title: const Text(
          'SANCAKTAR GCS',
          style: TextStyle(fontSize: 14, letterSpacing: 3),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.blueGrey, size: 20),
            onPressed: () => Get.find<AuthController>().logout(),
          ),
        ],
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
                _map(context, ctrl),
                const SizedBox(height: 20),
                _telemetry(ctrl),
                const SizedBox(height: 30),
                _actions(context, ctrl),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(UavController ctrl) => Obx(
    () => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMMAND COCKPIT',
          style: TextStyle(
            color: Colors.blue.shade200,
            fontSize: 18,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ACTIVE UNIT: ${ctrl.selectedUavId.value.isEmpty ? 'SEÇİM BEKLENİYOR' : ctrl.selectedUavId.value.toUpperCase()}',
          style: const TextStyle(
            color: Colors.blueAccent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _map(BuildContext context, UavController ctrl) => Obx(() {
    final markers = ctrl.uavList.entries.map((e) {
      final sel = ctrl.selectedUavId.value == e.key;
      return Marker(
        point: LatLng(e.value.lat ?? 38.0285, e.value.lon ?? 32.5115),
        width: sel ? 90 : 60,
        height: sel ? 90 : 60,
        child: GestureDetector(
          onTap: () => ctrl.selectUav(e.key),
          child: Column(
            children: [
              Icon(
                Icons.navigation_sharp,
                color: sel ? Colors.redAccent : Colors.blueAccent,
                size: sel ? 40 : 25,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  e.key.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: sel ? 10 : 8,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

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
            initialCenter: LatLng(
              ctrl.currentUav?.safeLat ?? 38.0285,
              ctrl.currentUav?.safeLon ?? 32.5115,
            ),
            initialZoom: 15,
            // ✅ Uzun basma buraya eklendi
            onLongPress: (TapPosition tapPosition, LatLng latLng) {
              ctrl.addSelectedMarker(latLng);
              _onMapLongPress(context, ctrl, latLng);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.sancaktar.gcs',
            ),
            // ✅ Seçilen konum marker'ı eklendi
            Obx(
              () => MarkerLayer(
                markers: [
                  ...markers, // mevcut marker'larınız
                  if (ctrl.selectedLocation.value != null)
                    Marker(
                      point: ctrl.selectedLocation.value!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  });

  Widget _telemetry(UavController ctrl) => Obx(() {
    final uav = ctrl.currentUav;
    if (uav == null)
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1621),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 10),
              Text(
                'VERİ BEKLENİYOR...',
                style: TextStyle(color: Colors.blueGrey),
              ),
            ],
          ),
        ),
      );

    return Row(
      children: [
        Expanded(
          child: _statCard(
            'ALTITUDE',
            uav.altitude.toStringAsFixed(1),
            'METERS',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard('SPEED', uav.speed.toStringAsFixed(1), 'M/S'),
        ),
        const SizedBox(width: 10),
        Expanded(child: _statCard('BATTERY', '%${uav.battery}', 'CAPACITY')),
      ],
    );
  });

  Widget _statCard(String label, String value, String unit) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF0D1621),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue.withOpacity(0.1)),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.blueGrey, fontSize: 9),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(unit, style: const TextStyle(color: Colors.blueGrey, fontSize: 9)),
      ],
    ),
  );

  Widget _actions(BuildContext context, UavController ctrl) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _btn(
              'TAKE OFF',
              Colors.blue,
              () => ctrl.sendCommand('TAKEOFF'),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _btn('LAND', Colors.red, () => ctrl.sendCommand('LAND')),
          ),
        ],
      ),
      const SizedBox(height: 15),
      Row(
        children: [
          Expanded(
            child: _btn('RTL', Colors.orange, () => ctrl.sendCommand('RTL')),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _btn('HOLD', Colors.grey, () => ctrl.sendCommand('HOLD')),
          ),
        ],
      ),
      const SizedBox(height: 15),
      Row(
        children: [
          Expanded(
            child: _btn(
              'MANUEL KONUM',
              Colors.cyan,
              () => _showManualLocationDialog(context, ctrl),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _btn(
              'ANLIK KONUM',
              Colors.green,
              () => ctrl.sendMyCurrentLocation(),
            ),
          ),
        ],
      ),
      const SizedBox(height: 15),
      Obx(
        () => ctrl.selectedUavId.value == 'alan_tarama'
            ? SizedBox(
                width: double.infinity,
                child: _btn(
                  'ALAN TARAMA TİPİ',
                  Colors.purple,
                  () => _showScanTypeDialog(context, ctrl),
                ),
              )
            : const SizedBox.shrink(),
      ),
      const SizedBox(height: 15),
      Obx(
        () => SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: ctrl.isListening.value
                    ? Colors.redAccent.withOpacity(0.8)
                    : Colors.tealAccent.withOpacity(0.5),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: ctrl.isListening.value
                  ? Colors.redAccent.withOpacity(0.08)
                  : Colors.tealAccent.withOpacity(0.05),
            ),
            onPressed: () => ctrl.toggleListening(),
            icon: Icon(
              ctrl.isListening.value ? Icons.mic : Icons.mic_none,
              color: ctrl.isListening.value
                  ? Colors.redAccent
                  : Colors.tealAccent,
              size: 20,
            ),
            label: Text(
              ctrl.isListening.value ? 'DİNLENİYOR...' : 'SESLİ KOMUT',
              style: TextStyle(
                color: ctrl.isListening.value
                    ? Colors.redAccent
                    : Colors.tealAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _btn(String label, Color color, VoidCallback onPressed) =>
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      );

  void _showManualLocationDialog(BuildContext context, UavController ctrl) {
    // Taşıyıcı değilse eski tek-konum dialogu aç
    if (ctrl.selectedUavId.value != 'tasiyici') {
      _showSingleLocationDialog(context, ctrl);
      return;
    }

    // Taşıyıcı için 4 dronun konumlarını al
    final drones = [
      {'id': 'kamikaze', 'label': 'KAMİKAZE', 'color': Colors.redAccent},
      {
        'id': 'nesne_tespit',
        'label': 'NESNE TESPİT',
        'color': Colors.blueAccent,
      },
      {
        'id': 'insan_takip',
        'label': 'İNSAN TAKİP',
        'color': Colors.orangeAccent,
      },
      {
        'id': 'alan_tarama',
        'label': 'ALAN TARAMA',
        'color': Colors.purpleAccent,
      },
    ];

    final Map<String, TextEditingController> latCtrls = {};
    final Map<String, TextEditingController> lonCtrls = {};
    for (final d in drones) {
      final id = d['id'] as String;
      latCtrls[id] = TextEditingController();
      lonCtrls[id] = TextEditingController();
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1621),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.blueAccent, width: 1),
        ),
        title: const Text(
          'TAŞIYICI — BIRAKMA KONUMLARI',
          style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 13,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: drones.map((d) {
                final id = d['id'] as String;
                final label = d['label'] as String;
                final color = d['color'] as Color;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1521),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drone başlığı
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Lat & Lon yan yana
                      Row(
                        children: [
                          Expanded(
                            child: _coordField(
                              controller: latCtrls[id]!,
                              hint: 'Enlem',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _coordField(
                              controller: lonCtrls[id]!,
                              hint: 'Boylam',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İPTAL', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // Validasyon
              for (final d in drones) {
                final id = d['id'] as String;
                if (double.tryParse(latCtrls[id]!.text.trim()) == null ||
                    double.tryParse(lonCtrls[id]!.text.trim()) == null) {
                  Get.snackbar(
                    'HATA',
                    '${d['label']} için geçerli koordinat girin',
                    backgroundColor: Colors.red.withOpacity(0.2),
                    colorText: Colors.redAccent,
                  );
                  return;
                }
              }
              Navigator.pop(ctx);
              _showDropConfirmDialog(context, ctrl, drones, latCtrls, lonCtrls);
            },
            child: const Text(
              'GÖNDER',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Koordinat input alanı
  Widget _coordField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
        hintText: hint == 'Enlem' ? '37.000000' : '32.000000',
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 10),
        filled: true,
        fillColor: const Color(0xFF060E18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white12),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  // Onay dialogu
  void _showDropConfirmDialog(
    BuildContext context,
    UavController ctrl,
    List<Map<String, dynamic>> drones,
    Map<String, TextEditingController> latCtrls,
    Map<String, TextEditingController> lonCtrls,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1621),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.orange, width: 1),
        ),
        title: const Text(
          'EMİN MİSİNİZ?',
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Aşağıdaki konumlar taşıyıcıya gönderilecek:',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ...drones.map((d) {
              final id = d['id'] as String;
              final label = d['label'] as String;
              final color = d['color'] as Color;
              final lat = double.parse(
                latCtrls[id]!.text.trim(),
              ).toStringAsFixed(6);
              final lon = double.parse(
                lonCtrls[id]!.text.trim(),
              ).toStringAsFixed(6);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '$lat, $lon',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'VAZGEÇ',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // Firebase'e yaz
              ctrl.sendDropMissionLocations({
                for (final d in drones)
                  d['id'] as String: {
                    'lat': double.parse(
                      latCtrls[d['id'] as String]!.text.trim(),
                    ),
                    'lon': double.parse(
                      lonCtrls[d['id'] as String]!.text.trim(),
                    ),
                    'alt': 15.0,
                  },
              });
              Get.snackbar(
                '',
                '',
                snackPosition: SnackPosition.TOP,
                backgroundColor: const Color(0xFF0D1621),
                borderColor: Colors.orange,
                borderWidth: 1,
                duration: const Duration(seconds: 3),
                titleText: const Text(
                  'KONUMLAR GÖNDERİLDİ',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                messageText: const Text(
                  'Taşıyıcı bırakma noktaları alındı.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              );
            },
            child: const Text(
              'EVET, GÖNDER',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Eski tek dron konum dialogu (tasiyici dışındakiler için)
  void _showSingleLocationDialog(BuildContext context, UavController ctrl) {
    final latCtrl = TextEditingController();
    final lonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1621),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.cyan, width: 1),
        ),
        title: const Text(
          'MANUEL KONUM',
          style: TextStyle(
            color: Colors.cyan,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'ENLEM (Latitude)',
                labelStyle: TextStyle(color: Colors.white54, fontSize: 11),
                hintText: 'örn: 38.028500',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 11),
                filled: true,
                fillColor: Color(0xFF0A1521),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.cyan),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lonCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'BOYLAM (Longitude)',
                labelStyle: TextStyle(color: Colors.white54, fontSize: 11),
                hintText: 'örn: 32.511500',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 11),
                filled: true,
                fillColor: Color(0xFF0A1521),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.cyan),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İPTAL', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final lat = double.tryParse(latCtrl.text.trim());
              final lon = double.tryParse(lonCtrl.text.trim());
              if (lat == null || lon == null) return;
              Navigator.pop(ctx);
              ctrl.sendTargetPosition(lat, lon);
            },
            child: const Text(
              'KONUMU GÖNDER',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showScanTypeDialog(BuildContext context, UavController ctrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1621),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.purple, width: 1),
        ),
        title: const Text(
          'ALAN TARAMA TİPİ',
          style: TextStyle(
            color: Colors.purple,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _scanOption(ctx, ctrl, 'ZİGZAG', 'zigzag', Icons.swap_vert_rounded),
            const SizedBox(height: 10),
            _scanOption(
              ctx,
              ctrl,
              'SPİRAL',
              'spiral',
              Icons.rotate_right_rounded,
            ),
            const SizedBox(height: 10),
            _scanOption(ctx, ctrl, 'IZGARA', 'grid', Icons.grid_4x4_rounded),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İPTAL', style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }

  void _onMapLongPress(
    BuildContext context,
    UavController ctrl,
    LatLng latLng,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1621),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.blue, width: 1),
        ),
        title: const Text(
          'KONUM SEÇİLDİ',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📍 Enlem: ${latLng.latitude.toStringAsFixed(6)}',
              style: const TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 4),
            Text(
              '📍 Boylam: ${latLng.longitude.toStringAsFixed(6)}',
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İPTAL', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ctrl.sendManualLocation(latLng.latitude, latLng.longitude);
            },
            child: const Text(
              'KONUMU GÖNDER',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanOption(
    BuildContext ctx,
    UavController ctrl,
    String label,
    String id,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        try {
          ctrl.sendScanMission(
            pattern: id,
            waypoints: const [],
            altitude: 50.0,
            speed: 10.0,
          );
        } catch (_) {}
        Get.snackbar(
          '',
          '',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF0D1621),
          borderColor: Colors.purple,
          borderWidth: 1,
          duration: const Duration(seconds: 4),
          titleText: const Text(
            'TARAMA KOMUTU GÖNDERİLDİ',
            style: TextStyle(
              color: Colors.purple,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          messageText: Text(
            'alan_tarama → $label',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.purple.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.purple, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FLEET SIDEBAR ─────────────────────────────────────────────
class FleetSidebar extends StatelessWidget {
  const FleetSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<UavController>();
    return Drawer(
      child: Container(
        color: const Color(0xFF0A1118),
        child: Column(
          children: [
            const DrawerHeader(
              child: Center(
                child: Text(
                  'SANCAKTAR GCS\nFLEET MANAGEMENT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (ctrl.uavList.isEmpty)
                  return const Center(
                    child: Text(
                      'Aktif İHA bulunamadı.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                return ListView.builder(
                  itemCount: ctrl.uavList.length,
                  itemBuilder: (_, i) {
                    final id = ctrl.uavList.keys.elementAt(i);
                    final uav = ctrl.uavList[id]!;
                    final sel = ctrl.selectedUavId.value == id;
                    return ListTile(
                      selected: sel,
                      selectedTileColor: Colors.blue.withOpacity(0.1),
                      leading: Icon(
                        Icons.airplanemode_active,
                        color: sel ? Colors.blue : Colors.grey,
                      ),
                      title: Text(
                        id.toUpperCase(),
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.grey,
                        ),
                      ),
                      subtitle: Text(
                        'Batarya: %${uav.battery}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.blueGrey,
                        ),
                      ),
                      onTap: () {
                        ctrl.selectUav(id);
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
