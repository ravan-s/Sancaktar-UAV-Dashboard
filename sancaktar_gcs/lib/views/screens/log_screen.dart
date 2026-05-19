import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_log_service.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _svc = FirestoreLogService();

  List<Map<String, dynamic>> _telemetry = [];
  List<Map<String, dynamic>> _commands  = [];
  List<Map<String, dynamic>> _logins    = [];
  bool _loading = true;

  // Renk paleti
  static const _bg     = Color(0xFF030A12);
  static const _panel  = Color(0xFF060E18);
  static const _card   = Color(0xFF0A1520);
  static const _border = Color(0xFF1E3045);
  static const _cyan   = Color(0xFF00E5FF);
  static const _green  = Color(0xFF00E676);
  static const _amber  = Color(0xFFFFB300);
  static const _red    = Color(0xFFE53935);
  static const _muted  = Color(0xFF7EA8BE);
  static const _dim    = Color(0xFF37474F);
  static const _white  = Color(0xFFECF0F1);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _svc.fetchLogs('telemetry_logs'),
      _svc.fetchLogs('command_history'),
      _svc.fetchLogs('login_logs'),
    ]);
    setState(() {
      _telemetry = results[0];
      _commands  = results[1];
      _logins    = results[2];
      _loading   = false;
    });
  }

  String _fmt(dynamic ts) {
    if (ts == null) return '--';
    try {
      final dt = DateTime.parse(ts.toString());
      return DateFormat('dd.MM.yy HH:mm:ss').format(dt);
    } catch (_) {
      return ts.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _panel,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _cyan, size: 18),
          onPressed: () => Get.back(),
        ),
        title: const Text('UÇUŞ LOGLARı',
          style: TextStyle(
            color: _white, fontWeight: FontWeight.w900,
            fontSize: 14, letterSpacing: 3, fontFamily: 'monospace')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _cyan),
            onPressed: _loadAll,
            tooltip: 'Yenile',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: _cyan,
          labelColor: _cyan,
          unselectedLabelColor: _muted,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 11,
            letterSpacing: 1.5, fontFamily: 'monospace'),
          tabs: [
            Tab(text: 'TELEMETRİ  (${_telemetry.length})'),
            Tab(text: 'KOMUTLAR  (${_commands.length})'),
            Tab(text: 'GİRİŞLER  (${_logins.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _cyan))
          : TabBarView(
              controller: _tab,
              children: [
                _TelemetryTab(data: _telemetry, fmt: _fmt),
                _CommandTab(data: _commands, fmt: _fmt),
                _LoginTab(data: _logins, fmt: _fmt),
              ],
            ),
    );
  }
}

// ================================================================
//  TELEMETRİ TABLOSU
// ================================================================
class _TelemetryTab extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String Function(dynamic) fmt;
  const _TelemetryTab({required this.data, required this.fmt});

  static const _bg    = Color(0xFF030A12);
  static const _card  = Color(0xFF0A1520);
  static const _border= Color(0xFF1E3045);
  static const _cyan  = Color(0xFF00E5FF);
  static const _green = Color(0xFF00E676);
  static const _amber = Color(0xFFFFB300);
  static const _red   = Color(0xFFE53935);
  static const _muted = Color(0xFF7EA8BE);
  static const _dim   = Color(0xFF37474F);
  static const _white = Color(0xFFECF0F1);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _empty('Telemetri logu bulunamadı');
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final d = data[i];
        final bat = int.tryParse(d['battery']?.toString() ?? '0') ?? 0;
        final batColor = bat > 50 ? _green : bat > 20 ? _amber : _red;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _card,
            border: Border.all(color: _border, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık satırı
              Row(children: [
                const Icon(Icons.airplanemode_active,
                  color: _cyan, size: 14),
                const SizedBox(width: 6),
                Text((d['drone_id'] ?? '--').toString().toUpperCase(),
                  style: const TextStyle(
                    color: _cyan, fontWeight: FontWeight.bold,
                    fontSize: 12, fontFamily: 'monospace')),
                const Spacer(),
                Text(fmt(d['timestamp']),
                  style: const TextStyle(
                    color: _dim, fontSize: 10, fontFamily: 'monospace')),
              ]),
              const SizedBox(height: 8),
              // Veri satırları
              Wrap(spacing: 12, runSpacing: 6, children: [
                _chip('İRTİFA', '${d['altitude'] ?? '--'} m', _amber),
                _chip('HIZ',    '${d['speed'] ?? '--'} m/s', _cyan),
                _chip('BATARYA','%${d['battery'] ?? '--'}', batColor),
                _chip('MOD',    d['flight_mode']?.toString() ?? '--', _muted),
                _chip('ARM',    (d['is_armed'] == true || d['is_armed'] == 'true')
                    ? 'ARMED' : 'DISARMED',
                    (d['is_armed'] == true || d['is_armed'] == 'true')
                    ? _red : _green),
                if (d['lat'] != null)
                  _chip('KONUM',
                    '${double.tryParse(d['lat'].toString())?.toStringAsFixed(4)}°N',
                    _muted),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String label, String val, Color col) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: col.withOpacity(0.08),
      border: Border.all(color: col.withOpacity(0.3), width: 1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: RichText(text: TextSpan(children: [
      TextSpan(text: '$label  ',
        style: const TextStyle(
          color: Color(0xFF546E7A), fontSize: 9,
          fontFamily: 'monospace', fontWeight: FontWeight.bold)),
      TextSpan(text: val,
        style: TextStyle(
          color: col, fontSize: 11,
          fontFamily: 'monospace', fontWeight: FontWeight.bold)),
    ])),
  );
}

// ================================================================
//  KOMUT TABLOSU
// ================================================================
class _CommandTab extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String Function(dynamic) fmt;
  const _CommandTab({required this.data, required this.fmt});

  static const _card  = Color(0xFF0A1520);
  static const _border= Color(0xFF1E3045);
  static const _cyan  = Color(0xFF00E5FF);
  static const _amber = Color(0xFFFFB300);
  static const _muted = Color(0xFF7EA8BE);
  static const _dim   = Color(0xFF37474F);

  Color _actionColor(String? action) {
    switch (action) {
      case 'TAKEOFF': return const Color(0xFF00E676);
      case 'LAND':    return const Color(0xFF00E5FF);
      case 'RTL':     return const Color(0xFFFFB300);
      case 'HOLD':    return const Color(0xFFE53935);
      default:        return _muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _empty('Komut logu bulunamadı');
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final d = data[i];
        final action = d['action']?.toString();
        final col = _actionColor(action);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _card,
            border: Border(left: BorderSide(color: col, width: 3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: col.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: col.withOpacity(0.4)),
              ),
              child: Text(action ?? '--',
                style: TextStyle(
                  color: col, fontWeight: FontWeight.w900,
                  fontSize: 12, fontFamily: 'monospace',
                  letterSpacing: 1.5)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((d['drone_id'] ?? '--').toString().toUpperCase(),
                  style: const TextStyle(
                    color: _cyan, fontSize: 11,
                    fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('UID: ${d['sent_by_uid'] ?? '--'}',
                  style: const TextStyle(
                    color: _dim, fontSize: 9, fontFamily: 'monospace')),
              ],
            )),
            Text(fmt(d['timestamp']),
              style: const TextStyle(
                color: _dim, fontSize: 10, fontFamily: 'monospace')),
          ]),
        );
      },
    );
  }
}

// ================================================================
//  GİRİŞ TABLOSU
// ================================================================
class _LoginTab extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String Function(dynamic) fmt;
  const _LoginTab({required this.data, required this.fmt});

  static const _card  = Color(0xFF0A1520);
  static const _border= Color(0xFF1E3045);
  static const _cyan  = Color(0xFF00E5FF);
  static const _green = Color(0xFF00E676);
  static const _muted = Color(0xFF7EA8BE);
  static const _dim   = Color(0xFF37474F);
  static const _white = Color(0xFFECF0F1);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _empty('Giriş logu bulunamadı');
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final d = data[i];
        final platform = d['platform']?.toString() ?? '--';
        final isLinux = platform == 'Linux';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _card,
            border: Border.all(color: _border, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(isLinux ? Icons.computer : Icons.phone_android,
              color: _cyan, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d['email']?.toString() ?? '--',
                  style: const TextStyle(
                    color: _white, fontSize: 12,
                    fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('UID: ${d['uid'] ?? '--'}',
                  style: const TextStyle(
                    color: _dim, fontSize: 9, fontFamily: 'monospace')),
              ],
            )),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: _green.withOpacity(0.3)),
                  ),
                  child: Text(platform,
                    style: const TextStyle(
                      color: _green, fontSize: 9,
                      fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                Text(fmt(d['timestamp']),
                  style: const TextStyle(
                    color: _dim, fontSize: 10, fontFamily: 'monospace')),
              ],
            ),
          ]),
        );
      },
    );
  }
}

// ── Boş durum ────────────────────────────────────────────────
Widget _empty(String msg) => Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.inbox, color: Color(0xFF37474F), size: 48),
      const SizedBox(height: 12),
      Text(msg, style: const TextStyle(
        color: Color(0xFF546E7A), fontSize: 13, fontFamily: 'monospace')),
    ],
  ),
);