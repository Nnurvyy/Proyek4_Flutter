import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;
import 'package:hive/hive.dart'; 
import 'package:logbook_app/features/logbook/models/log_model.dart';
import '../../services/mongo_service.dart';
import '../../helpers/log_helper.dart';
import '../../services/access_control_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async'; // Diperlukan untuk StreamSubscription

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier<List<LogModel>>([]);
  late final Box<LogModel> _myBox; 
  
  // Tambahkan variabel untuk menyimpan listener koneksi
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  List<LogModel> get logs => logsNotifier.value;

  LogController() {
    _myBox = Hive.box<LogModel>('offline_logs'); 
    _initConnectivityListener(); // Panggil listener saat controller diinisialisasi
  }

  // --- 1. INISIALISASI LISTENER KONEKSI ---
  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Jika mendeteksi ada koneksi Wifi atau Mobile Data
      if (results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.mobile)) {
        LogHelper.writeLog("NETWORK: Internet terdeteksi, memeriksa data tertahan...", source: "log_controller.dart");
        syncPendingLogs(); // Picu sinkronisasi
      }
    });
  }

  // Jangan lupa bersihkan listener untuk mencegah memory leak
  void dispose() {
    _connectivitySubscription?.cancel();
    logsNotifier.dispose();
  }

  // --- 2. FUNGSI UNTUK SINKRONISASI DATA PENDING ---
  Future<void> syncPendingLogs() async {
    final pendingLogs = _myBox.values.where((log) => log.isSynced == false).toList();

    if (pendingLogs.isEmpty) return; // Tidak ada data yang tertahan

    await LogHelper.writeLog("SYNC: Menemukan ${pendingLogs.length} data tertahan. Memulai sinkronisasi...", level: 2);

    for (var log in pendingLogs) {
      try {
        // Coba kirim ke Cloud
        await MongoService().insertLog(log);
        
        // Jika berhasil, update status di lokal menjadi tersinkronisasi
        log.isSynced = true;
        
        // Cari index log ini di Hive dan perbarui
        final index = _myBox.values.toList().indexWhere((element) => element.id == log.id);
        if (index != -1) {
          await _myBox.putAt(index, log);
        }

        await LogHelper.writeLog("SYNC SUCCESS: Data '${log.title}' berhasil diunggah", level: 2);
      } catch (e) {
        await LogHelper.writeLog("SYNC FAILED: Gagal mengunggah '${log.title}' - $e", level: 1);
        // Biarkan isSynced tetap false, akan dicoba lagi nanti
      }
    }
    
    // Refresh UI dengan data terbaru
    logsNotifier.value = _myBox.values.toList();
  }

  // --- 3. UBAH FUNGSI ADD LOG ---
  Future<void> addLog(String title, String desc, String category, String authorId, String teamId, bool isPublic) async {
    final newLog = LogModel(
      id: ObjectId().oid, // <-- PERBAIKAN DI SINI: Menggunakan .oid pengganti toHexString
      title: title,
      description: desc,
      date: DateTime.now(),
      category: category, 
      authorId: authorId, 
      teamId: teamId,
      isSynced: false, // Default awal set false dulu
      isPublic: isPublic,
    );

    // ACTION 1: Simpan ke Hive (Instan)
    await _myBox.add(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog];

    // ACTION 2: Kirim ke Cloud (Background)
    try {
      await MongoService().insertLog(newLog);
      
      // Jika berhasil, update isSynced menjadi true di Hive
      newLog.isSynced = true;
      final index = _myBox.values.toList().indexWhere((element) => element.id == newLog.id);
      if (index != -1) await _myBox.putAt(index, newLog);

      await LogHelper.writeLog("SUCCESS: Data tersinkron ke Cloud", source: "log_controller.dart");
    } catch (e) {
      await LogHelper.writeLog("WARNING: Data tersimpan lokal (Pending Sync), akan sinkron saat online", level: 1);
    }
  }

  /// 1. LOAD DATA (Offline-First Strategy)
  Future<void> loadLogs(String teamId) async {
    // Langkah 1: Ambil data dari Hive (Sangat Cepat/Instan)
    logsNotifier.value = _myBox.values.toList();

    // Langkah 2: Sync dari Cloud (Background)
    try {
      // [PERBAIKAN]: Sinkronkan data offline TERLEBIH DAHULU
      await syncPendingLogs();

      final cloudData = await MongoService().getLogs(teamId);

      // [PERBAIKAN]: Amankan data yang mungkin masih pending/gagal terkirim barusan
      final pendingLogs = _myBox.values.where((log) => log.isSynced == false).toList();

      // Update Hive dengan data terbaru dari Cloud agar sinkron
      await _myBox.clear();
      await _myBox.addAll(cloudData);
      
      // [PERBAIKAN]: Kembalikan data offline ke dalam Hive
      if (pendingLogs.isNotEmpty) {
        await _myBox.addAll(pendingLogs);
      }

      // Update UI dengan data gabungan (Cloud + Pending)
      logsNotifier.value = _myBox.values.toList();

      await LogHelper.writeLog(
        "SYNC: Data berhasil diperbarui dari Atlas",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "OFFLINE: Menggunakan data cache lokal",
        level: 2,
      );
    }
  }

  /// 3. UPDATE DATA (Diselaraskan dengan Offline-First)
  Future<void> updateLog(int index, String newTitle, String newDesc, String newCategory, String currentUserRole, String currentUserId, bool isPublic) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final oldLog = currentLogs[index];

    // Validasi Keamanan Level Controller
    final isOwner = oldLog.authorId == currentUserId;
    if (!AccessControlService.canPerform(currentUserRole, AccessControlService.actionUpdate, isOwner: isOwner)) {
      await LogHelper.writeLog("SECURITY BREACH: Unauthorized update attempt by UserID: $currentUserId", level: 1, source: "log_controller.dart");
      return; 
    }

    final updatedLog = LogModel(
      id: oldLog.id, 
      title: newTitle,
      description: newDesc,
      date: DateTime.now(),
      category: newCategory, 
      authorId: oldLog.authorId, 
      teamId: oldLog.teamId, 
      isPublic: isPublic,    
    );

    // ACTION 1: Update ke Hive (Instan)
    await _myBox.putAt(index, updatedLog);
    
    // Update UI seketika
    currentLogs[index] = updatedLog;
    logsNotifier.value = currentLogs;

    // ACTION 2: Update ke MongoDB Atlas (Background)
    try {
      await MongoService().updateLog(updatedLog);
      await LogHelper.writeLog("SUCCESS: Sinkronisasi Update Berhasil", source: "log_controller.dart", level: 2);
    } catch (e) {
      await LogHelper.writeLog("WARNING: Update tersimpan lokal, gagal sinkron ke Cloud", source: "log_controller.dart", level: 1);
    }
  }

  /// 4. REMOVE DATA (Diselaraskan dengan Offline-First)
  Future<void> removeLog(int index, String currentUserRole, String currentUserId) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final targetLog = currentLogs[index];

    // Validasi Keamanan Level Controller
    final isOwner = targetLog.authorId == currentUserId;
    if (!AccessControlService.canPerform(currentUserRole, AccessControlService.actionDelete, isOwner: isOwner)) {
      await LogHelper.writeLog("SECURITY BREACH: Unauthorized delete attempt by UserID: $currentUserId", level: 1, source: "log_controller.dart");
      return; 
    }

    // ACTION 1: Hapus dari Hive (Instan)
    await _myBox.deleteAt(index);
    
    // Update UI seketika
    currentLogs.removeAt(index);
    logsNotifier.value = currentLogs;

    // ACTION 2: Hapus dari MongoDB Atlas (Background)
    try {
      if (targetLog.id != null) {
        await MongoService().deleteLog(targetLog.id!); 
        await LogHelper.writeLog("SUCCESS: Sinkronisasi Hapus Berhasil", source: "log_controller.dart", level: 2);
      }
    } catch (e) {
      await LogHelper.writeLog("WARNING: Hapus berhasil di lokal, gagal sinkron ke Cloud", source: "log_controller.dart", level: 1);
    }
  }
}