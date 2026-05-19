import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreLogService {
  static final FirestoreLogService _instance = FirestoreLogService._internal();
  factory FirestoreLogService() => _instance;
  FirestoreLogService._internal();

  static const _projectId = 'sancaktar-2025';
  static const _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  FirebaseFirestore? _db;
  Timer? _timer;
  Map<String, Map<String, dynamic>> _buffer = {};

  bool get _isLinux => defaultTargetPlatform == TargetPlatform.linux && !kIsWeb;

  // ── BAŞLAT ───────────────────────────────────────
  void start() {
    if (!_isLinux) _db = FirebaseFirestore.instance;
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _flush());
    print('✅ FirestoreLogService başlatıldı (${_isLinux ? "REST" : "SDK"})');
  }

  void stop() => _timer?.cancel();

  // ── TELEMETRİ BUFFER ─────────────────────────────
  void updateBuffer(String droneId, Map<String, dynamic> data) {
    _buffer[droneId] = {
      ...data,
      'drone_id': droneId,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _flush() async {
    if (_buffer.isEmpty) return;
    for (final entry in _buffer.entries) {
      await _writeDoc('telemetry_logs', entry.value);
    }
    print('✅ Telemetri log yazıldı: ${_buffer.length} drone');
    _buffer.clear();
  }

  // ── KOMUT LOG ────────────────────────────────────
  Future<void> logCommand({
    required String droneId,
    required String action,
    required String sentByUid,
  }) async {
    await _writeDoc('command_history', {
      'drone_id':    droneId,
      'action':      action,
      'sent_by_uid': sentByUid,
      'timestamp':   DateTime.now().toIso8601String(),
    });
  }

  // ── GİRİŞ LOG ────────────────────────────────────
  Future<void> logLogin({
    required String uid,
    required String email,
  }) async {
    await _writeDoc('login_logs', {
      'uid':       uid,
      'email':     email,
      'platform':  _isLinux ? 'Linux' : 'Mobile',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ── VERİ OKU (Log Ekranı İçin) ───────────────────
  Future<List<Map<String, dynamic>>> fetchLogs(String collection,
      {int limit = 50}) async {
    if (_isLinux) {
      return _fetchRest(collection, limit: limit);
    } else {
      return _fetchSdk(collection, limit: limit);
    }
  }

  // ── REST YAZMA ───────────────────────────────────
  Future<void> _writeDoc(String collection, Map<String, dynamic> data) async {
    if (_isLinux) {
      await _writeRest(collection, data);
    } else {
      try {
        await _db!.collection(collection).add({
          ...data,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('❌ SDK yazma hatası: $e');
      }
    }
  }

  Future<void> _writeRest(String collection, Map<String, dynamic> data) async {
    try {
      final fields = _toFirestoreFields(data);
      await http.post(
        Uri.parse('$_baseUrl/$collection'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': fields}),
      );
    } catch (e) {
      print('❌ REST yazma hatası: $e');
    }
  }

  // ── REST OKUMA ───────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchRest(String collection,
      {int limit = 50}) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/$collection?pageSize=$limit'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body);
      final docs = body['documents'] as List? ?? [];
      return docs.map((d) => _fromFirestoreFields(d['fields'] as Map)).toList();
    } catch (e) {
      print('❌ REST okuma hatası: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSdk(String collection,
      {int limit = 50}) async {
    try {
      final snap = await _db!
          .collection(collection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      print('❌ SDK okuma hatası: $e');
      return [];
    }
  }

  // ── FIRESTORE FORMAT ─────────────────────────────
  Map<String, dynamic> _toFirestoreFields(Map<String, dynamic> data) {
    return data.map((k, v) {
      if (v is String)  return MapEntry(k, {'stringValue': v});
      if (v is int)     return MapEntry(k, {'integerValue': v.toString()});
      if (v is double)  return MapEntry(k, {'doubleValue': v});
      if (v is bool)    return MapEntry(k, {'booleanValue': v});
      return MapEntry(k, {'stringValue': v.toString()});
    });
  }

  Map<String, dynamic> _fromFirestoreFields(Map fields) {
    return fields.map((k, v) {
      final val = (v as Map).values.first;
      return MapEntry(k.toString(), val);
    });
  }
}