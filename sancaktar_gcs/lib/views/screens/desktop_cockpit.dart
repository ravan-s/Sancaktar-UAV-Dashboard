// ================================================================
//  SANCAKTAR GCS — Ana Ekran (Responsive)
//  Dosya: lib/views/screens/desktop_cockpit.dart
// ================================================================
// ✅ Şununla değiştir
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../controllers/uav_controller.dart';
import '../../models/uav_model.dart';
import '../../services/telemetry_service.dart';
import 'log_screen.dart';

// ── Renk Paleti ─────────────────────────────────────────────
class _C {
  static const bg      = Color(0xFF030A12);
  static const panel   = Color(0xFF060E18);
  static const card    = Color(0xFF0A1520);
  static const border  = Color(0xFF1E3045);
  static const border2 = Color(0xFF253545);
  static const cyan    = Color(0xFF00E5FF);
  static const red     = Color(0xFFE53935);
  static const amber   = Color(0xFFFFB300);
  static const green   = Color(0xFF00E676);
  static const white   = Color(0xFFECF0F1);
  static const grey    = Color(0xFF546E7A);
  static const dim     = Color(0xFF37474F);
  static const muted   = Color(0xFF7EA8BE);
  static const sky     = Color(0xFF1A5FA8);
  static const earth   = Color(0xFF5C3A28);
}

// ── UavModel proxy ──────────────────────────────────────────
class _P {
  final UavController ctrl;
  _P(this.ctrl);

  UavModel? get uav => ctrl.currentUav;

  double get speed    => uav?.speed    ?? 0;
  double get altitude => uav?.altitude ?? 0;
  int    get battery  => uav?.battery  ?? 0;
  double get volt     => uav?.battery_volt ?? 0;
  String get mode     => uav?.flightMode   ?? 'UNKNOWN';
  bool   get armed    => uav?.isArmed      ?? false;
  int    get gpsFix   => uav?.gps_fix      ?? 0;
  double? get lat     => uav?.lat;
  double? get lon     => uav?.lon;
  int    get conn     => uav?.connectionStrength ?? 0;
  bool   get online   => uav?.isOnline ?? false;

  double get roll          => 0;
  double get pitch         => 0;
  double get heading       => 0;
  double get verticalSpeed => 0;
}

// ================================================================
//  ANA WIDGET
// ================================================================
class DesktopCockpit extends StatelessWidget {
  const DesktopCockpit({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<UavController>();
    return Scaffold(
      backgroundColor: _C.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final sf = (w / 1920).clamp(0.55, 1.5);
          return _GcsLayout(ctrl: ctrl, sf: sf, totalW: w, totalH: constraints.maxHeight);
        },
      ),
    );
  }
}

// ================================================================
//  ANA LAYOUT
// ================================================================
class _GcsLayout extends StatefulWidget {
  final UavController ctrl;
  final double sf, totalW, totalH;
  const _GcsLayout({required this.ctrl, required this.sf,
    required this.totalW, required this.totalH});

  @override
  State<_GcsLayout> createState() => _GcsLayoutState();
}

class _GcsLayoutState extends State<_GcsLayout> {
  late final _P _p;

  @override
  void initState() {
    super.initState();
    _p = _P(widget.ctrl);
  }

  double get sf => widget.sf;

  @override
  Widget build(BuildContext context) {
    final topH    = 44 * sf;
    final statusH = 110 * sf;
    final fleetW  = 200 * sf;

    return Column(
      children: [
        SizedBox(height: topH,   child: _TopBar(p: _p, sf: sf)),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _InstrumentRow(p: _p, sf: sf),
                    Expanded(child: _MapBox(p: _p)),
                  ],
                ),
              ),
              SizedBox(width: fleetW, child: _FleetPanel(ctrl: widget.ctrl, sf: sf)),
            ],
          ),
        ),
        SizedBox(height: statusH, child: _StatusBar(p: _p, sf: sf)),
      ],
    );
  }
}

// ================================================================
//  TOP BAR  ── Saat her saniye güncellenir
// ================================================================
class _TopBar extends StatefulWidget {
  final _P p;
  final double sf;
  const _TopBar({required this.p, required this.sf, super.key});

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  late Timer _timer;
  String _timeStr = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final s = '${now.hour.toString().padLeft(2,'0')}:'
              '${now.minute.toString().padLeft(2,'0')}:'
              '${now.second.toString().padLeft(2,'0')}';
    if (mounted) setState(() => _timeStr = s);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sf = widget.sf;
    final p  = widget.p;
    final fs = (11 * sf).clamp(9.0, 14.0);

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _C.border, width: 1.5)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16 * sf),
      child: Row(
        children: [
          // Logo + İsim
          Container(
            padding: EdgeInsets.only(right: 16 * sf),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: _C.border, width: 1.5)),
            ),
            child: Row(children: [
              Container(
                width: 22 * sf, height: 22 * sf,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.cyan, width: 2),
                ),
                child: Center(child: Container(
                  width: 8 * sf, height: 8 * sf,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: _C.cyan),
                )),
              ),
              SizedBox(width: 10 * sf),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('☰  SANCAKTAR GCM',
                    style: TextStyle(
                      color: _C.white, fontWeight: FontWeight.w900,
                      fontSize: (13 * sf).clamp(10, 16),
                      letterSpacing: 2.5, fontFamily: 'monospace')),
                  Text('KONYA TEKNİK ÜNİVERSİTESİ',
                    style: TextStyle(
                      color: _C.muted, fontSize: (8.5 * sf).clamp(7, 11),
                      letterSpacing: 1.2, fontFamily: 'monospace')),
                ],
              ),
            ]),
          ),
          // Menü öğeleri
          ..._menuItems(sf, fs),
          const Spacer(),
          // Sağ durum
          _topPill(Icons.usb, 'USB · COM3 · 57600',
              TelemetryService().isConnected ? _C.green : _C.red, sf, fs),
          SizedBox(width: 14 * sf),
          _topPill(Icons.storage, 'DB BAĞLI', _C.green, sf, fs),
          SizedBox(width: 14 * sf),
          Text(_timeStr, style: TextStyle(
            color: _C.grey, fontSize: (9 * sf).clamp(8, 12),
            fontFamily: 'monospace')),
        ],
      ),
    );
  }

  List<Widget> _menuItems(double sf, double fs) {
  final items = [
    ('VERİTABANI', false),
    ('DEBUG', false),
    ('LOG', false),
    ('GİRİŞ', true),
  ];
  return items.map((it) => GestureDetector(       // ← GestureDetector ekle
    onTap: () {
      if (it.$1 == 'LOG') Get.to(() => const LogScreen()); // ← bunu ekle
    },
    child: Container(
      height: double.infinity,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: _C.border, width: 1))),
      padding: EdgeInsets.symmetric(horizontal: 14 * sf),
      child: Center(child: Text(it.$1,
        style: TextStyle(
          color: it.$2 ? _C.amber : _C.muted,
          fontSize: fs.clamp(9, 13),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          fontFamily: 'monospace'))),
    ),
  )).toList();
}
  Widget _topPill(IconData icon, String label, Color color, double sf, double fs) {
    return Row(children: [
      Icon(icon, color: color, size: (12 * sf).clamp(10, 16)),
      SizedBox(width: 5 * sf),
      Text(label, style: TextStyle(
        color: _C.muted, fontSize: (fs * 0.9).clamp(8, 12),
        fontWeight: FontWeight.bold, fontFamily: 'monospace')),
    ]);
  }
}

// ================================================================
//  GÖSTERGE SIRASI
// ================================================================
class _InstrumentRow extends StatelessWidget {
  final _P p;
  final double sf;
  const _InstrumentRow({required this.p, required this.sf, super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final instH = (MediaQuery.of(context).size.height * 0.30).clamp(140.0, 320.0);
      return SizedBox(
        height: instH,
        child: Padding(
          padding: EdgeInsets.all(6 * sf),
          child: Row(
            children: [
              _instCard('AIRSPEED',    AirspeedPainter(p.speed),                sf),
              SizedBox(width: 6 * sf),
              _instCard('ATİTÜD',     AttitudePainter(p.roll, p.pitch),         sf),
              SizedBox(width: 6 * sf),
              _instCard('ALTİMETRE',  AltimeterPainter(p.altitude),             sf),
              SizedBox(width: 6 * sf),
              _instCard('YAW / RULO', YawPainter(p.roll, p.battery, p.armed),  sf),
              SizedBox(width: 6 * sf),
              _instCard('PUSULA',     HeadingPainter(p.heading, p.gpsFix),      sf),
              SizedBox(width: 6 * sf),
              _instCard('VSI · D.HIZ',VSIPainter(p.verticalSpeed),              sf),
            ],
          ),
        ),
      );
    });
  }

  Widget _instCard(String label, CustomPainter painter, double sf) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: _C.card,
          border: Border.all(color: _C.border2, width: 1.5),
          borderRadius: BorderRadius.circular(8 * sf),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 5 * sf, bottom: 2 * sf),
              child: Text(label, style: TextStyle(
                color: _C.muted,
                fontSize: (8.5 * sf).clamp(8, 13),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontFamily: 'monospace')),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(6*sf, 0, 6*sf, 6*sf),
                child: LayoutBuilder(builder: (_, c) {
                  final sz = math.min(c.maxWidth, c.maxHeight);
                  return Center(child: SizedBox(
                    width: sz, height: sz,
                    child: CustomPaint(painter: painter),
                  ));
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
//  HARİTA
// ================================================================
class _MapBox extends StatelessWidget {
  final _P p;
  const _MapBox({required this.p, super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final markers = p.ctrl.uavList.entries.map((e) {
        final sel = p.ctrl.selectedUavId.value == e.key;
        return fm.Marker(
          point: LatLng(e.value.lat ?? 38.0285, e.value.lon ?? 32.5115),
          width: sel ? 40 : 28, height: sel ? 40 : 28,
          child: GestureDetector(
            onTap: () => p.ctrl.selectUav(e.key),
            child: Icon(Icons.navigation,
              color: sel ? _C.red : _C.cyan,
              size: sel ? 36 : 24),
          ),
        );
      }).toList();

      return Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _C.border2, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            fm.FlutterMap(
              options: fm.MapOptions(
                initialCenter: LatLng(
                  p.lat ?? 38.0285, p.lon ?? 32.5115),
                initialZoom: 15,
              ),
              children: [
                fm.TileLayer(
                  urlTemplate:
                    'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.revan.sancaktar_gcs',
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                fm.MarkerLayer(markers: markers),
              ],
            ),
            Positioned(top: 8, left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.panel.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _C.border, width: 1),
                ),
                child: const Text('HARİTA · MAP VIEW',
                  style: TextStyle(
                    color: _C.muted, fontSize: 10,
                    fontWeight: FontWeight.bold, letterSpacing: 1.5,
                    fontFamily: 'monospace')),
              ),
            ),
            if (p.lat != null)
              Positioned(bottom: 8, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _C.panel.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${p.lat!.toStringAsFixed(6)}°N · ${p.lon!.toStringAsFixed(6)}°E',
                    style: const TextStyle(
                      color: _C.white, fontSize: 10,
                      fontFamily: 'monospace')),
                ),
              ),
          ]),
        ),
      );
    });
  }
}

// ================================================================
//  FİLO PANELİ  ── _UsbConnectWidget Obx dışına alındı
// ================================================================
class _FleetPanel extends StatelessWidget {
  final UavController ctrl;
  final double sf;
  const _FleetPanel({required this.ctrl, required this.sf, super.key});

  @override
  Widget build(BuildContext context) {
    final fs = (10 * sf).clamp(9.0, 14.0);

    return Container(
      decoration: const BoxDecoration(
        color: _C.panel,
        border: Border(left: BorderSide(color: _C.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Başlık
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10*sf, vertical: 8*sf),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _C.border, width: 1.5))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('FİLO · DRONLAR', style: TextStyle(
                  color: _C.muted, fontSize: (10*sf).clamp(9,13),
                  fontWeight: FontWeight.bold, letterSpacing: 1.5,
                  fontFamily: 'monospace')),
                Obx(() {
                  final active = ctrl.uavList.values
                    .where((u) => u.isOnline).length;
                  return Text('$active AKTİF', style: TextStyle(
                    color: _C.green, fontSize: (10*sf).clamp(9,13),
                    fontWeight: FontWeight.bold, fontFamily: 'monospace'));
                }),
              ],
            ),
          ),

          // USB bağlantı widget'ı — Obx DIŞINDA, her zaman görünür
          _UsbConnectWidget(sf: sf),
          const Divider(color: _C.border, height: 1),

          // Drone listesi
          Expanded(
            child: Obx(() {
              if (ctrl.uavList.isEmpty) {
                return Center(child: Text('Drone bulunamadı',
                  style: TextStyle(color: _C.grey, fontSize: fs,
                    fontFamily: 'monospace')));
              }
              return ListView.builder(
                padding: EdgeInsets.all(6 * sf),
                itemCount: ctrl.uavList.length,
                itemBuilder: (_, i) {
                  final id  = ctrl.uavList.keys.elementAt(i);
                  final uav = ctrl.uavList[id]!;
                  final sel = ctrl.selectedUavId.value == id;
                  return _DroneCard(
                    id: id, uav: uav, selected: sel, sf: sf,
                    onTap: () => ctrl.selectUav(id),
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

// ================================================================
//  USB BAĞLANTI WİDGET'I
// ================================================================
class _UsbConnectWidget extends StatefulWidget {
  final double sf;
  const _UsbConnectWidget({required this.sf});

  @override
  State<_UsbConnectWidget> createState() => _UsbConnectWidgetState();
}

class _UsbConnectWidgetState extends State<_UsbConnectWidget> {
  String _selectedPort  = '';
  String _selectedDrone = 'tuna_1';
  final _ts = TelemetryService();

  @override
  Widget build(BuildContext context) {
    final ports = TelemetryService.getAvailablePorts();
    final fs    = (9.0 * widget.sf).clamp(8.0, 13.0);

    return Padding(
      padding: EdgeInsets.all(8 * widget.sf),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('USB TELEMETRİ', style: TextStyle(
            color: _C.muted, fontSize: fs,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5, fontFamily: 'monospace')),
          SizedBox(height: 6 * widget.sf),

          // Port seç
          DropdownButtonFormField<String>(
            value: _selectedPort.isEmpty ? null : _selectedPort,
            dropdownColor: _C.card,
            style: TextStyle(color: _C.white, fontSize: fs),
            decoration: InputDecoration(
              labelText: 'Port',
              labelStyle: TextStyle(color: _C.muted, fontSize: fs * 0.9),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: _C.border, width: 1)),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: _C.cyan, width: 1)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 6),
            ),
            hint: Text('/dev/ttyUSB*',
              style: TextStyle(color: _C.grey, fontSize: fs)),
            items: ports.map((p) => DropdownMenuItem(
              value: p,
              child: Text(p, style: TextStyle(
                color: _C.white, fontSize: fs, fontFamily: 'monospace')),
            )).toList(),
            onChanged: (v) => setState(() => _selectedPort = v ?? ''),
          ),
          SizedBox(height: 6 * widget.sf),

          // Drone seç
          DropdownButtonFormField<String>(
            value: _selectedDrone,
            dropdownColor: _C.card,
            style: TextStyle(color: _C.white, fontSize: fs),
            decoration: InputDecoration(
              labelText: 'Drone',
              labelStyle: TextStyle(color: _C.muted, fontSize: fs * 0.9),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: _C.border, width: 1)),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: _C.cyan, width: 1)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 6),
            ),
            items: const [
              DropdownMenuItem(value: 'tuna_1',      child: Text('TUNA 1')),
              DropdownMenuItem(value: 'insan_takip', child: Text('İNSAN TAKİP')),
              DropdownMenuItem(value: 'kamikaze',    child: Text('KAMİKAZE')),
              DropdownMenuItem(value: 'tasiyici',    child: Text('TAŞIYICI')),
              DropdownMenuItem(value: 'alan_tarama', child: Text('ALAN TARAMA')),
            ],
            onChanged: (v) => setState(() => _selectedDrone = v ?? 'tuna_1'),
          ),
          SizedBox(height: 8 * widget.sf),

          // Bağlan / Kes
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _ts.isConnected
                  ? _C.red.withOpacity(0.2)
                  : _C.cyan.withOpacity(0.15),
                side: BorderSide(
                  color: _ts.isConnected ? _C.red : _C.cyan, width: 1),
                padding: EdgeInsets.symmetric(vertical: 10 * widget.sf),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () async {
                if (_ts.isConnected) {
                  _ts.disconnect();
                  setState(() {});
                } else {
                  if (_selectedPort.isEmpty) {
                    Get.snackbar('Hata', 'Port seçin',
                      snackPosition: SnackPosition.BOTTOM);
                    return;
                  }
                  final ok = await _ts.connect(_selectedPort, _selectedDrone);
                  setState(() {});
                  Get.snackbar(
                    ok ? '✅ Bağlandı' : '❌ Hata',
                    ok ? '$_selectedPort → $_selectedDrone' : 'Port açılamadı',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              child: Text(
                _ts.isConnected ? 'BAĞLANTIYI KES' : 'BAĞLAN',
                style: TextStyle(
                  color: _ts.isConnected ? _C.red : _C.cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: fs, fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
//  DRONE KARTI
// ================================================================
class _DroneCard extends StatelessWidget {
  final String id;
  final UavModel uav;
  final bool selected;
  final double sf;
  final VoidCallback onTap;
  const _DroneCard({required this.id, required this.uav,
    required this.selected, required this.sf, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final col = selected ? _C.cyan : (uav.isOnline ? _C.amber : _C.grey);
    final fs  = (10 * sf).clamp(9.0, 13.0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 6 * sf),
        padding: EdgeInsets.all(8 * sf),
        decoration: BoxDecoration(
          color: selected ? _C.cyan.withOpacity(0.06) : _C.card,
          border: Border.all(
            color: selected ? _C.cyan.withOpacity(0.5) : _C.border, width: 1.5),
          borderRadius: BorderRadius.circular(7 * sf),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.airplanemode_active,
                color: col, size: (16 * sf).clamp(13, 22)),
              SizedBox(width: 6 * sf),
              Expanded(child: Text(id.toUpperCase().replaceAll('_', ' '),
                style: TextStyle(color: _C.white,
                  fontSize: fs, fontWeight: FontWeight.bold,
                  fontFamily: 'monospace'))),
              if (uav.isOnline)
                Text('● CANLI', style: TextStyle(
                  color: _C.green, fontSize: (fs * 0.85).clamp(8, 11),
                  fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            ]),
            SizedBox(height: 5 * sf),
            Row(children: [
              _tag('COM3', _C.dim, fs),
              SizedBox(width: 4 * sf),
              _tag('57600', _C.dim, fs),
              SizedBox(width: 4 * sf),
              _tag(uav.isOnline ? 'AKTİF' : 'ÇEVRIMDIŞI',
                uav.isOnline ? _C.green : _C.red, fs),
            ]),
            SizedBox(height: 4 * sf),
            Row(children: [
              Text('BAT: ', style: TextStyle(color: _C.dim,
                fontSize: (fs*0.85).clamp(8,11), fontFamily: 'monospace')),
              Text('%${uav.battery}', style: TextStyle(
                color: uav.isBatteryLow ? _C.red : _C.green,
                fontSize: (fs*0.85).clamp(8,11), fontWeight: FontWeight.bold,
                fontFamily: 'monospace')),
              SizedBox(width: 8 * sf),
              Text('UÇUŞ: ', style: TextStyle(color: _C.dim,
                fontSize: (fs*0.85).clamp(8,11), fontFamily: 'monospace')),
              Text('00:00', style: TextStyle(color: _C.cyan,
                fontSize: (fs*0.85).clamp(8,11), fontWeight: FontWeight.bold,
                fontFamily: 'monospace')),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _tag(String t, Color c, double fs) => Container(
    padding: EdgeInsets.symmetric(horizontal: 5*sf, vertical: 1.5*sf),
    decoration: BoxDecoration(
      color: c.withOpacity(0.12),
      border: Border.all(color: c.withOpacity(0.4), width: 1),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(t, style: TextStyle(
      color: c, fontSize: (fs * 0.85).clamp(7, 10),
      fontWeight: FontWeight.bold, fontFamily: 'monospace')),
  );
}

// ================================================================
//  ALT DURUM ÇUBUĞU
// ================================================================
class _StatusBar extends StatelessWidget {
  final _P p;
  final double sf;
  const _StatusBar({required this.p, required this.sf, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _C.panel,
        border: Border(top: BorderSide(color: _C.border, width: 1.5)),
      ),
      padding: EdgeInsets.all(6 * sf),
      child: Obx(() {
        final uav = p.uav;
        return Row(
          children: [
            // ARM
            _StatCard(
              title: 'ARM DURUM',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8*sf, vertical: 3*sf),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: p.armed ? _C.red : _C.green, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                      color: (p.armed ? _C.red : _C.green).withOpacity(0.1),
                    ),
                    child: Text(p.armed ? 'ARMED' : 'DISARMED',
                      style: TextStyle(
                        color: p.armed ? _C.red : _C.green,
                        fontSize: (11 * sf).clamp(9, 15),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5, fontFamily: 'monospace')),
                  ),
                  SizedBox(height: 4*sf),
                  Text(p.mode, style: TextStyle(
                    color: _C.amber,
                    fontSize: (10 * sf).clamp(8, 13),
                    fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                ],
              ),
              sf: sf,
            ),
            SizedBox(width: 6*sf),
            _StatCard(title: 'İRTİFA',
              value: uav == null ? '--' : uav.altitude.toStringAsFixed(1),
              unit: 'METRE', valColor: _C.amber, sf: sf),
            SizedBox(width: 6*sf),
            _StatCard(title: 'HIZ',
              value: uav == null ? '--' : uav.speed.toStringAsFixed(1),
              unit: 'm/s', valColor: _C.cyan, sf: sf),
            SizedBox(width: 6*sf),
            _StatCard(title: 'DİKEY HIZ',
              value: uav == null ? '--'
                : '${p.verticalSpeed > 0 ? '+' : ''}${p.verticalSpeed.toStringAsFixed(1)}',
              unit: p.verticalSpeed >= 0 ? 'm/s · YUKARI' : 'm/s · ALÇALIYOR',
              valColor: p.verticalSpeed >= 0 ? _C.green : _C.red, sf: sf),
            SizedBox(width: 6*sf),
            _StatCard(title: 'BATARYA',
              value: uav == null ? '--' : '%${uav.battery}',
              unit: uav == null ? '' : '${uav.battery_volt.toStringAsFixed(1)} V',
              valColor: uav == null
                ? _C.grey
                : (uav.battery < 20 ? _C.red : _C.green),
              sf: sf),
            SizedBox(width: 6*sf),
            _StatCard(title: 'GPS · UYDU',
              value: p.gpsFix == 3 ? '3D FIX' : 'NO FIX',
              unit: '${p.gpsFix == 3 ? '10' : '0'} UYDU',
              valColor: p.gpsFix == 3 ? _C.green : _C.red, sf: sf),
            SizedBox(width: 6*sf),
            _StatCard(
              title: 'KONUM',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.lat != null
                    ? '${p.lat!.toStringAsFixed(5)}°N' : '--',
                    style: TextStyle(
                      color: _C.white, fontFamily: 'monospace',
                      fontSize: (11*sf).clamp(9,14),
                      fontWeight: FontWeight.bold)),
                  SizedBox(height: 2*sf),
                  Text(p.lon != null
                    ? '${p.lon!.toStringAsFixed(5)}°E' : '--',
                    style: TextStyle(
                      color: _C.white, fontFamily: 'monospace',
                      fontSize: (11*sf).clamp(9,14),
                      fontWeight: FontWeight.bold)),
                ],
              ),
              sf: sf,
            ),
            SizedBox(width: 6*sf),
            _StatCard(title: 'PORT · BAUD',
              value: 'COM3',
              unit: '57600 baud', valColor: _C.cyan, sf: sf),
            SizedBox(width: 6*sf),
            // Uçuş süresi
            Expanded(
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: _C.card,
                  border: Border.all(
                    color: _C.cyan.withOpacity(0.4), width: 1.5),
                  borderRadius: BorderRadius.circular(7 * sf),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 12*sf, vertical: 6*sf),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('UÇUŞ SÜRESİ', style: TextStyle(
                      color: _C.dim, fontSize: (8*sf).clamp(7,11),
                      fontWeight: FontWeight.bold, letterSpacing: 2,
                      fontFamily: 'monospace')),
                    SizedBox(height: 4*sf),
                    Text('00:00:00', style: TextStyle(
                      color: _C.cyan,
                      fontSize: (22 * sf).clamp(14, 30),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3, fontFamily: 'monospace')),
                    SizedBox(height: 3*sf),
                    Text(p.ctrl.selectedUavId.value.isEmpty
                      ? '--'
                      : p.ctrl.selectedUavId.value.toUpperCase(),
                      style: TextStyle(
                        color: _C.cyan.withOpacity(0.7),
                        fontSize: (9*sf).clamp(8,12),
                        fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ================================================================
//  STAT KARTI
// ================================================================
class _StatCard extends StatelessWidget {
  final String title;
  final String? value;
  final String? unit;
  final Color valColor;
  final Widget? child;
  final double sf;

  const _StatCard({
    required this.title,
    this.value,
    this.unit,
    this.valColor = _C.white,
    this.child,
    required this.sf,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: _C.card,
          border: Border.all(color: _C.border2, width: 1.5),
          borderRadius: BorderRadius.circular(7 * sf),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 10*sf, vertical: 6*sf),
        child: child ?? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(
              color: _C.dim,
              fontSize: (8 * sf).clamp(7, 11),
              fontWeight: FontWeight.bold,
              letterSpacing: 2, fontFamily: 'monospace')),
            SizedBox(height: 3*sf),
            Text(value ?? '--', style: TextStyle(
              color: valColor,
              fontSize: (16 * sf).clamp(11, 22),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5, fontFamily: 'monospace')),
            if (unit != null && unit!.isNotEmpty)
              Text(unit!, style: TextStyle(
                color: _C.grey,
                fontSize: (8.5 * sf).clamp(7, 11),
                fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }
}

// ================================================================
//  INSTRUMENT PAINTERS (CustomPainter)
// ================================================================

void _tick(Canvas c, Offset ct, double r, double angDeg,
    double lenRatio, double sw, Color col) {
  final a = (angDeg - 90) * math.pi / 180;
  c.drawLine(
    Offset(ct.dx + r * 0.92 * math.cos(a), ct.dy + r * 0.92 * math.sin(a)),
    Offset(ct.dx + r * (0.92 - lenRatio) * math.cos(a),
           ct.dy + r * (0.92 - lenRatio) * math.sin(a)),
    Paint()..color = col..strokeWidth = sw..strokeCap = StrokeCap.butt,
  );
}

void _label(Canvas c, Offset ct, double lr, double angDeg,
    String text, TextStyle style) {
  final a = (angDeg - 90) * math.pi / 180;
  final pos = lr == 0
      ? Offset(ct.dx, ct.dy)
      : Offset(ct.dx + lr * math.cos(a), ct.dy + lr * math.sin(a));
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
}

void _needle(Canvas c, Offset ct, double len, double angDeg,
    Color col, double width) {
  final a = (angDeg - 90) * math.pi / 180;
  c.drawLine(
    Offset(ct.dx - len * 0.2 * math.cos(a), ct.dy - len * 0.2 * math.sin(a)),
    Offset(ct.dx + len * math.cos(a), ct.dy + len * math.sin(a)),
    Paint()..color = col..strokeWidth = width..strokeCap = StrokeCap.round,
  );
}

void _valuebox(Canvas c, Offset ct, double r, String val, String unit, Color col) {
  final rr = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset(ct.dx, ct.dy + r * 0.32),
      width: r * 0.78, height: r * 0.24),
    const Radius.circular(4));
  c.drawRRect(rr, Paint()..color = Colors.black.withOpacity(0.75));
  c.drawRRect(rr, Paint()
    ..color = col.withOpacity(0.45)
    ..style = PaintingStyle.stroke..strokeWidth = 1);
  final tp = TextPainter(
    text: TextSpan(children: [
      TextSpan(text: val, style: TextStyle(
        color: col, fontSize: r * 0.14,
        fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      if (unit.isNotEmpty)
        TextSpan(text: ' $unit', style: TextStyle(
          color: col.withOpacity(0.7), fontSize: r * 0.09,
          fontFamily: 'monospace')),
    ]),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, Offset(ct.dx - tp.width / 2, ct.dy + r * 0.32 - tp.height / 2));
}

void _dialBase(Canvas c, Offset ct, double r) {
  c.drawCircle(ct, r, Paint()..color = const Color(0xFF0D1A27));
  c.drawCircle(ct, r, Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xFF253545)..strokeWidth = 2.5);
}

void _center(Canvas c, Offset ct, double r, Color col) {
  c.drawCircle(ct, r * 0.065, Paint()..color = const Color(0xFF1E2D3D));
  c.drawCircle(ct, r * 0.042, Paint()..color = col);
}

// ── 1. Airspeed ───────────────────────────────────────────────
class AirspeedPainter extends CustomPainter {
  final double speed;
  AirspeedPainter(this.speed);

  double _ang(double v) => v / 40 * 270 - 135;

  @override
  void paint(Canvas canvas, Size size) {
    final ct = Offset(size.width / 2, size.height / 2);
    final r  = size.width / 2;
    _dialBase(canvas, ct, r);

    void arc(double from, double to, Color col) {
      final Paint p = Paint()
        ..color = col..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.09..strokeCap = StrokeCap.butt;
      final sa = (_ang(from) - 90) * math.pi / 180;
      final sw = (_ang(to) - _ang(from)) * math.pi / 180;
      canvas.drawArc(Rect.fromCircle(center: ct, radius: r * 0.86),
        sa, sw, false, p);
    }
    arc(0, 20, const Color(0xFF00E676));
    arc(20, 32, const Color(0xFFFFB300));
    arc(32, 40, const Color(0xFFE53935));

    for (int i = 0; i <= 40; i += 5) {
      final major = i % 10 == 0;
      _tick(canvas, ct, r, _ang(i.toDouble()),
        major ? 0.14 : 0.08, major ? 2 : 1, const Color(0xFFECF0F1));
      if (major) _label(canvas, ct, r * 0.68, _ang(i.toDouble()), '$i',
        TextStyle(color: const Color(0xFFECF0F1),
          fontSize: r * 0.11, fontWeight: FontWeight.bold,
          fontFamily: 'monospace'));
    }

    _needle(canvas, ct, r * 0.72, _ang(speed.clamp(0, 40)),
      const Color(0xFFECF0F1), r * 0.03);
    _valuebox(canvas, ct, r, speed.toStringAsFixed(1), 'm/s',
      const Color(0xFF00E5FF));
    _center(canvas, ct, r, const Color(0xFFECF0F1));
  }

  @override
  bool shouldRepaint(AirspeedPainter o) => o.speed != speed;
}

// ── 2. Attitude ───────────────────────────────────────────────
class AttitudePainter extends CustomPainter {
  final double roll, pitch;
  AttitudePainter(this.roll, this.pitch);

  @override
  void paint(Canvas canvas, Size size) {
    final ct = Offset(size.width / 2, size.height / 2);
    final r  = size.width / 2;

    final clipOval = ui.Path()..addOval(Rect.fromCircle(center: ct, radius: r * 0.92));
    canvas.clipPath(clipOval);
    canvas.save();
    canvas.translate(ct.dx, ct.dy);
    canvas.rotate(roll * math.pi / 180);

    final py = pitch * r * 0.04;
    canvas.drawRect(Rect.fromLTRB(-r, -r * 2 + py, r, py),
      Paint()..color = const Color(0xFF1A5FA8));
    canvas.drawRect(Rect.fromLTRB(-r, py, r, r * 2),
      Paint()..color = const Color(0xFF5C3A28));
    canvas.drawLine(Offset(-r, py), Offset(r, py),
      Paint()..color = const Color(0xFFECF0F1)..strokeWidth = 2);

    for (int d = -30; d <= 30; d += 5) {
      if (d == 0) continue;
      final y = py - d * r * 0.04;
      final hw = d % 10 == 0 ? r * 0.3 : r * 0.17;
      canvas.drawLine(Offset(-hw, y), Offset(hw, y),
        Paint()..color = const Color(0xFFECF0F1).withOpacity(0.8)..strokeWidth = 1);
    }
    canvas.restore();

    for (int a in [-60, -45, -30, -20, -10, 0, 10, 20, 30, 45, 60]) {
      final rad = (a - 90) * math.pi / 180;
      final major = a.abs() % 30 == 0;
      canvas.drawLine(
        Offset(ct.dx + r * 0.92 * math.cos(rad),
               ct.dy + r * 0.92 * math.sin(rad)),
        Offset(ct.dx + r * (major ? 0.80 : 0.85) * math.cos(rad),
               ct.dy + r * (major ? 0.80 : 0.85) * math.sin(rad)),
        Paint()..color = const Color(0xFFECF0F1)
          ..strokeWidth = major ? 2 : 1,
      );
    }

    final rRad = (roll - 90) * math.pi / 180;
    final tri = ui.Path()
      ..moveTo(ct.dx + r * 0.86 * math.cos(rRad),
               ct.dy + r * 0.86 * math.sin(rRad))
      ..lineTo(ct.dx + r * 0.77 * math.cos(rRad - 0.08),
               ct.dy + r * 0.77 * math.sin(rRad - 0.08))
      ..lineTo(ct.dx + r * 0.77 * math.cos(rRad + 0.08),
               ct.dy + r * 0.77 * math.sin(rRad + 0.08))
      ..close();
    canvas.drawPath(tri, Paint()..color = const Color(0xFFFFB300));

    final pp = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = r * 0.04..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(ct.dx - r * 0.4, ct.dy),
      Offset(ct.dx - r * 0.15, ct.dy), pp);
    canvas.drawLine(Offset(ct.dx + r * 0.15, ct.dy),
      Offset(ct.dx + r * 0.4, ct.dy), pp);
    canvas.drawLine(Offset(ct.dx - r * 0.06, ct.dy),
      Offset(ct.dx + r * 0.06, ct.dy), pp);
    canvas.drawCircle(ct, r * 0.04, Paint()..color = const Color(0xFFFFB300));

    canvas.drawCircle(ct, r, Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF253545)..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(AttitudePainter o) => o.roll != roll || o.pitch != pitch;
}

// ── 3. Altimeter ──────────────────────────────────────────────
class AltimeterPainter extends CustomPainter {
  final double alt;
  AltimeterPainter(this.alt);

  @override
  void paint(Canvas canvas, Size size) {
    final ct = Offset(size.width / 2, size.height / 2);
    final r  = size.width / 2;
    _dialBase(canvas, ct, r);

    for (int i = 0; i < 10; i++) {
      final ang = i / 10 * 360 - 90;
      final major = i % 5 == 0;
      _tick(canvas, ct, r, ang, major ? 0.14 : 0.08, major ? 2 : 1,
        const Color(0xFFECF0F1));
      if (i % 2 == 0) _label(canvas, ct, r * 0.7, ang, '${i * 100}',
        TextStyle(color: const Color(0xFFECF0F1),
          fontSize: r * 0.10, fontWeight: FontWeight.bold,
          fontFamily: 'monospace'));
    }

    _needle(canvas, ct, r * 0.5,
      (alt % 10000) / 10000 * 360 - 90,
      const Color(0xFFECF0F1).withOpacity(0.5), r * 0.018);
    _needle(canvas, ct, r * 0.72,
      (alt % 1000) / 1000 * 360 - 90,
      const Color(0xFFECF0F1), r * 0.03);

    _valuebox(canvas, ct, r, alt.toStringAsFixed(0), 'm',
      const Color(0xFFFFB300));
    _center(canvas, ct, r, const Color(0xFFECF0F1));
  }

  @override
  bool shouldRepaint(AltimeterPainter o) => o.alt != alt;
}

// ── 4. Yaw / Roll + Battery ───────────────────────────────────
class YawPainter extends CustomPainter {
  final double roll;
  final int battery;
  final bool armed;
  YawPainter(this.roll, this.battery, this.armed);

  @override
  void paint(Canvas canvas, Size size) {
    final ct = Offset(size.width / 2, size.height / 2);
    final r  = size.width / 2;
    _dialBase(canvas, ct, r);

    for (int i = -180; i < 180; i += 10) {
      final major = i.abs() % 30 == 0;
      _tick(canvas, ct, r, (i - 90).toDouble(),
        major ? 0.13 : 0.06, major ? 1.8 : 0.8,
        major ? const Color(0xFFECF0F1) : const Color(0xFF546E7A));
    }

    final batColor = battery > 50
      ? const Color(0xFF00E676)
      : battery > 20 ? const Color(0xFFFFB300) : const Color(0xFFE53935);
    canvas.drawArc(
      Rect.fromCircle(center: ct, radius: r * 0.91),
      -math.pi / 2, -(battery / 100 * 2 * math.pi), false,
      Paint()..color = batColor
        ..style = PaintingStyle.stroke..strokeWidth = r * 0.055
        ..strokeCap = StrokeCap.round);

    _drawDrone(canvas, ct, r * 0.32);

    final rRad = (roll - 90) * math.pi / 180;
    final tri = ui.Path()
      ..moveTo(ct.dx + r * 0.8 * math.cos(rRad),
               ct.dy + r * 0.8 * math.sin(rRad))
      ..lineTo(ct.dx + r * 0.71 * math.cos(rRad - 0.07),
               ct.dy + r * 0.71 * math.sin(rRad - 0.07))
      ..lineTo(ct.dx + r * 0.71 * math.cos(rRad + 0.07),
               ct.dy + r * 0.71 * math.sin(rRad + 0.07))
      ..close();
    canvas.drawPath(tri, Paint()..color = const Color(0xFF00E5FF));

    _label(canvas, ct, 0, 90, armed ? 'ARMED' : 'DISARMED',
      TextStyle(color: armed ? const Color(0xFFE53935) : const Color(0xFF00E676),
        fontSize: r * 0.11, fontWeight: FontWeight.bold, fontFamily: 'monospace'));

    final btp = TextPainter(
      text: TextSpan(text: '%$battery', style: TextStyle(
        color: batColor, fontSize: r * 0.13,
        fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      textDirection: TextDirection.ltr,
    )..layout();
    btp.paint(canvas, Offset(ct.dx - btp.width / 2, ct.dy + r * 0.45));
  }

  void _drawDrone(Canvas canvas, Offset ct, double r) {
    final bp = Paint()..color = const Color(0xFFECF0F1);
    canvas.drawRect(
      Rect.fromCenter(center: ct, width: r * 0.5, height: r * 0.22), bp);
    final ap = Paint()
      ..color = const Color(0xFFECF0F1)..strokeWidth = r * 0.08
      ..strokeCap = StrokeCap.round;
    final cp = Paint()
      ..color = const Color(0xFF00E5FF)..strokeWidth = r * 0.06
      ..style = PaintingStyle.stroke;
    for (final d in [
      [Offset(-0.55, -0.55), Offset(-0.95, -0.95)],
      [Offset(0.55, -0.55), Offset(0.95, -0.95)],
      [Offset(-0.55, 0.55), Offset(-0.95, 0.95)],
      [Offset(0.55, 0.55), Offset(0.95, 0.95)],
    ]) {
      canvas.drawLine(
        Offset(ct.dx + d[0].dx * r, ct.dy + d[0].dy * r),
        Offset(ct.dx + d[1].dx * r, ct.dy + d[1].dy * r), ap);
      canvas.drawCircle(
        Offset(ct.dx + d[1].dx * r, ct.dy + d[1].dy * r), r * 0.2, cp);
    }
  }

  @override
  bool shouldRepaint(YawPainter o) =>
    o.roll != roll || o.battery != battery || o.armed != armed;
}

// ── 5. Heading ────────────────────────────────────────────────
class HeadingPainter extends CustomPainter {
  final double heading;
  final int gpsFix;
  HeadingPainter(this.heading, this.gpsFix);

  @override
  void paint(Canvas canvas, Size size) {
    final ct = Offset(size.width / 2, size.height / 2);
    final r  = size.width / 2;
    _dialBase(canvas, ct, r);

    canvas.save();
    canvas.translate(ct.dx, ct.dy);
    canvas.rotate(-heading * math.pi / 180);

    for (final e in {'N': 0.0, 'E': 90.0, 'S': 180.0, 'W': 270.0}.entries) {
      final a = (e.value - 90) * math.pi / 180;
      final tp = TextPainter(
        text: TextSpan(text: e.key, style: TextStyle(
          color: e.key == 'N' ? const Color(0xFFE53935) : const Color(0xFFECF0F1),
          fontSize: r * 0.16, fontWeight: FontWeight.w900,
          fontFamily: 'monospace')),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(
        r * 0.68 * math.cos(a) - tp.width / 2,
        r * 0.68 * math.sin(a) - tp.height / 2));
    }

    for (int i = 0; i < 36; i++) {
      final major = i % 3 == 0;
      final a = (i * 10 - 90) * math.pi / 180;
      canvas.drawLine(
        Offset(r * 0.88 * math.cos(a), r * 0.88 * math.sin(a)),
        Offset(r * (major ? 0.76 : 0.82) * math.cos(a),
               r * (major ? 0.76 : 0.82) * math.sin(a)),
        Paint()..color = major
          ? const Color(0xFFECF0F1) : const Color(0xFF546E7A)
          ..strokeWidth = major ? 1.8 : 0.8);
    }
    canvas.restore();

    final tri = ui.Path()
      ..moveTo(ct.dx, ct.dy - r * 0.82)
      ..lineTo(ct.dx - r * 0.055, ct.dy - r * 0.68)
      ..lineTo(ct.dx + r * 0.055, ct.dy - r * 0.68)
      ..close();
    canvas.drawPath(tri, Paint()..color = const Color(0xFF00E5FF));

    _valuebox(canvas, ct, r, '${heading.toStringAsFixed(0)}°', '',
      const Color(0xFF00E5FF));

    final gCol = gpsFix == 3 ? const Color(0xFF00E676) : const Color(0xFFE53935);
    final gtp = TextPainter(
      text: TextSpan(
        text: gpsFix == 3 ? '● 3D FIX' : '○ NO FIX',
        style: TextStyle(color: gCol, fontSize: r * 0.10,
          fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      textDirection: TextDirection.ltr,
    )..layout();
    gtp.paint(canvas, Offset(ct.dx - gtp.width / 2, ct.dy + r * 0.52));

    _center(canvas, ct, r, const Color(0xFF00E5FF));
  }

  @override
  bool shouldRepaint(HeadingPainter o) =>
    o.heading != heading || o.gpsFix != gpsFix;
}

// ── 6. VSI ────────────────────────────────────────────────────
class VSIPainter extends CustomPainter {
  final double vs;
  VSIPainter(this.vs);

  @override
  void paint(Canvas canvas, Size size) {
    final ct = Offset(size.width / 2, size.height / 2);
    final r  = size.width / 2;
    _dialBase(canvas, ct, r);

    const max = 10.0;
    void arc(double from, double to, Color col) {
      final sa = (from / max * 135 - 90 - 90) * math.pi / 180;
      final sw = ((to - from) / max * 135) * math.pi / 180;
      canvas.drawArc(Rect.fromCircle(center: ct, radius: r * 0.86),
        sa, sw, false,
        Paint()..color = col..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.09..strokeCap = StrokeCap.butt);
    }
    arc(0, max, const Color(0xFF00E676));
    arc(-max, 0, const Color(0xFFE53935));

    for (int v = -10; v <= 10; v += 2) {
      final ang = v / max * 135 - 90;
      final major = v % 5 == 0;
      _tick(canvas, ct, r, ang, major ? 0.14 : 0.08, major ? 2 : 1,
        const Color(0xFFECF0F1));
      if (major) _label(canvas, ct, r * 0.69, ang,
        '${v > 0 ? '+' : ''}$v',
        TextStyle(
          color: v > 0 ? const Color(0xFF00E676)
            : v < 0 ? const Color(0xFFE53935) : const Color(0xFFECF0F1),
          fontSize: r * 0.10, fontWeight: FontWeight.bold,
          fontFamily: 'monospace'));
    }

    final col = vs > 0 ? const Color(0xFF00E676)
      : vs < 0 ? const Color(0xFFE53935) : const Color(0xFFECF0F1);
    _needle(canvas, ct, r * 0.72,
      vs.clamp(-max, max) / max * 135 - 90, col, r * 0.03);

    _valuebox(canvas, ct, r,
      '${vs > 0 ? '+' : ''}${vs.toStringAsFixed(1)}', 'm/s', col);
    _center(canvas, ct, r, col);
  }

  @override
  bool shouldRepaint(VSIPainter o) => o.vs != vs;
}