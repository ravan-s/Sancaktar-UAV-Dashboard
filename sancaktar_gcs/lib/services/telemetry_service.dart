import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../controllers/uav_controller.dart';
import '../models/uav_model.dart';
import 'package:get/get.dart';

class TelemetryService {
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  TelemetryService._internal();

  SerialPort?         _port;
  SerialPortReader?   _reader;
  StreamSubscription? _sub;
  String?             _activeDroneId;

  final Map<String, dynamic> _cache = {};
  final List<int>            _buffer = [];

  static List<String> getAvailablePorts() => SerialPort.availablePorts;

  Future<bool> connect(String portName, String droneId) async {
    try {
      disconnect();
      _port = SerialPort(portName);
      if (!_port!.openReadWrite()) {
        print('❌ Port açılamadı: $portName');
        return false;
      }
      final config    = SerialPortConfig();
      config.baudRate = 57600;
      config.bits     = 8;
      config.stopBits = 1;
      config.parity   = SerialPortParity.none;
      _port!.config   = config;

      _activeDroneId = droneId;
      _reader        = SerialPortReader(_port!);
      _sub           = _reader!.stream.listen((data) {
        _parseMavlink(data, droneId);
      });

      print('✅ USB bağlantı: $portName → $droneId');
      unawaited(_requestDataStreams());
      return true;
    } catch (e) {
      print('❌ Bağlantı hatası: $e');
      return false;
    }
  }

  Future<void> _requestDataStreams() async {
    await Future.delayed(const Duration(seconds: 2));
    final streams = [
      {'id': 1,  'rate': 2},
      {'id': 2,  'rate': 2},
      {'id': 6,  'rate': 5},
      {'id': 10, 'rate': 5},
      {'id': 11, 'rate': 2},
    ];
    for (final s in streams) {
      final packet = _buildRequestStream(s['id']!, s['rate']!);
      _port?.write(Uint8List.fromList(packet));
      await Future.delayed(const Duration(milliseconds: 100));
      print('📡 Stream istendi: ID=${s['id']} rate=${s['rate']}Hz');
    }
  }

  List<int> _buildRequestStream(int streamId, int rate) {
    final payload = [
      rate & 0xFF, (rate >> 8) & 0xFF,
      0xFF, 0xFF,
      streamId,
      1,
    ];
    final header = [
      0xFE, payload.length, 0, 255, 190, 66,
    ];
    final crc = _mavlinkCrc([...header.sublist(1), ...payload], 148);
    return [...header, ...payload, crc & 0xFF, (crc >> 8) & 0xFF];
  }

  int _mavlinkCrc(List<int> data, int crcExtra) {
    int crc = 0xFFFF;
    for (final byte in data) {
      int tmp = byte ^ (crc & 0xFF);
      tmp ^= (tmp << 4) & 0xFF;
      crc = ((crc >> 8) ^ (tmp << 8) ^ (tmp << 3) ^ (tmp >> 4)) & 0xFFFF;
    }
    int tmp = crcExtra ^ (crc & 0xFF);
    tmp ^= (tmp << 4) & 0xFF;
    crc = ((crc >> 8) ^ (tmp << 8) ^ (tmp << 3) ^ (tmp >> 4)) & 0xFFFF;
    return crc;
  }

  void _parseMavlink(Uint8List data, String droneId) {
    try {
      final buf = Uint8List.fromList([..._buffer, ...data]);
      _buffer.clear();
      int i = 0;
      while (i < buf.length) {
        if (buf[i] == 0xFE) {
          if (i + 8 > buf.length) { _buffer.addAll(buf.sublist(i)); break; }
          final msgLen = buf[i + 1];
          final total  = 8 + msgLen;
          if (i + total > buf.length) { _buffer.addAll(buf.sublist(i)); break; }
          final msgId   = buf[i + 5];
          final payload = buf.sublist(i + 6, i + 6 + msgLen);
          _handleMessage(msgId, payload, droneId);
          i += total;
        } else if (buf[i] == 0xFD) {
          if (i + 10 > buf.length) { _buffer.addAll(buf.sublist(i)); break; }
          final msgLen = buf[i + 1];
          final total  = 12 + msgLen;
          if (i + total > buf.length) { _buffer.addAll(buf.sublist(i)); break; }
          final msgId   = buf[i + 7] | (buf[i + 8] << 8) | (buf[i + 9] << 16);
          final payload = buf.sublist(i + 10, i + 10 + msgLen);
          _handleMessage(msgId, payload, droneId);
          i += total;
        } else {
          i++;
        }
      }
    } catch (e) {
      print('Parse hatası: $e');
    }
  }

  void _handleMessage(int msgId, Uint8List payload, String droneId) {
    switch (msgId) {
      case 0:   _handleHeartbeat(payload, droneId);     break;
      case 1:   _handleSysStatus(payload, droneId);     break;
      case 30:  _handleAttitude(payload, droneId);      break;
      case 33:  _handlePosition(payload, droneId);      break;
      case 74:  _handleVfrHud(payload, droneId);        break;
      case 147: _handleBatteryStatus(payload, droneId); break;
    }
  }

  void _handleHeartbeat(Uint8List p, String droneId) {
    if (p.length < 6) return;
    final bd       = p.buffer.asByteData(p.offsetInBytes);
    final baseMode = p.length > 6 ? p[6] : 0;
    _cache['is_armed']            = (baseMode & 0x80) != 0;
    _cache['flight_mode']         = _flightMode(bd.getUint32(0, Endian.little));
    _cache['connection_strength'] = 100;
    print('💓 Heartbeat — armed: ${_cache['is_armed']}, mode: ${_cache['flight_mode']}');
    _updateController(droneId);
  }

  void _handleSysStatus(Uint8List p, String droneId) {
    if (p.length < 9) return;
    final bd      = p.buffer.asByteData(p.offsetInBytes);
    final voltage = p.length >= 16 ? bd.getUint16(14, Endian.little) / 1000.0 : 0.0;
    final pct     = p.length >= 31 ? bd.getInt8(30) : -1;
    _cache['battery_volt'] = voltage;
    _cache['battery']      = (pct < 0 || pct > 100) ? null : pct;
    _updateController(droneId);
  }

  void _handleAttitude(Uint8List p, String droneId) {
    if (p.length < 24) return;
    final bd    = p.buffer.asByteData(p.offsetInBytes);
    _cache['roll']  = bd.getFloat32(4, Endian.little) * 180 / 3.14159;
    _cache['pitch'] = bd.getFloat32(8, Endian.little) * 180 / 3.14159;
    _updateController(droneId);
  }

  void _handlePosition(Uint8List p, String droneId) {
    if (p.length < 28) return;
    final bd = p.buffer.asByteData(p.offsetInBytes);
    _cache['lat'] = bd.getInt32(0, Endian.little) / 1e7;
    _cache['lon'] = bd.getInt32(4, Endian.little) / 1e7;
    _cache['alt'] = bd.getInt32(8, Endian.little) / 1000.0;
    _updateController(droneId);
  }

  void _handleVfrHud(Uint8List p, String droneId) {
    if (p.length < 20) return;
    _cache['speed'] = p.buffer.asByteData(p.offsetInBytes)
        .getFloat32(0, Endian.little);
    _updateController(droneId);
  }

  void _handleBatteryStatus(Uint8List p, String droneId) {
    if (p.length < 6) return;
    final bd   = p.buffer.asByteData(p.offsetInBytes);
    final pct  = p.length > 33 ? p[33] : -1;
    final mv   = bd.getUint16(4, Endian.little);
    _cache['battery']      = (pct < 0 || pct > 100) ? 0 : pct;
    _cache['battery_volt'] = mv == 0xFFFF ? 0.0 : mv / 1000.0;
    _updateController(droneId);
  }

  void _updateController(String droneId) {
    try {
      final ctrl = Get.find<UavController>();
      ctrl.updateUavFromUsb(droneId, UavModel(
        lat:               _cache['lat'],
        lon:               _cache['lon'],
        altitude:          (_cache['alt']          as num?)?.toDouble() ?? 0.0,
        speed:             (_cache['speed']         as num?)?.toDouble() ?? 0.0,
        battery:           (_cache['battery']       as num?)?.toInt()    ?? 0,
        battery_volt:      (_cache['battery_volt']  as num?)?.toDouble() ?? 0.0,
        isArmed:           _cache['is_armed']       ?? false,
        flightMode:        _cache['flight_mode']    ?? 'UNKNOWN',
        connectionStrength: 100,
      ));
    } catch (_) {}
  }

  String _flightMode(int mode) {
    const modes = {
      0: 'STABILIZE', 2: 'ALT_HOLD', 3: 'AUTO',
      4: 'GUIDED',    5: 'LOITER',   6: 'RTL',
      9: 'LAND',      16: 'POSHOLD',
    };
    return modes[mode] ?? 'UNKNOWN';
  }

  void disconnect() {
    _sub?.cancel();
    _reader = null;
    try {
      _port?.close();
      _port?.dispose();
    } catch (_) {}
    _port          = null;
    _activeDroneId = null;
    _cache.clear();
    print('🔌 USB bağlantısı kesildi.');
  }

  bool    get isConnected   => _port?.isOpen == true;
  String? get activeDroneId => _activeDroneId;
}