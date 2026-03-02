import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logbook_app/features/logbook/models/log_model.dart';
// Pastikan path ini sesuai
import '../../services/mongo_service.dart';
import '../../helpers/log_helper.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier<List<LogModel>>([]);

  static const String _storageKey = 'user_logs_data';
  List<LogModel> get logs => logsNotifier.value;

  LogController() {
    loadFromDisk();
  }

 
  Future<void> addLog(String title, String desc, String category) async {
    final newLog = LogModel(
      id: ObjectId(),
      title: title,
      description: desc,
      date: DateTime.now(),
      category: category, 
    );

    try {
      await MongoService().insertLog(newLog);

      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs.add(newLog);
      logsNotifier.value = currentLogs;

      await LogHelper.writeLog("SUCCESS: Tambah data dengan ID lokal", source: "log_controller.dart");
    } catch (e) {
      await LogHelper.writeLog("ERROR: Gagal sinkronisasi Add - $e", level: 1);
    }
  }

  
  Future<void> updateLog(int index, String newTitle, String newDesc, String newCategory) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final oldLog = currentLogs[index];

    final updatedLog = LogModel(
      id: oldLog.id, 
      title: newTitle,
      description: newDesc,
      date: DateTime.now(),
      category: newCategory, 
    );

    try {
      await MongoService().updateLog(updatedLog);

      currentLogs[index] = updatedLog;
      logsNotifier.value = currentLogs;

      await LogHelper.writeLog("SUCCESS: Sinkronisasi Update Berhasil", source: "log_controller.dart", level: 2);
    } catch (e) {
      await LogHelper.writeLog("ERROR: Gagal sinkronisasi Update - $e", source: "log_controller.dart", level: 1);
    }
  }

  Future<void> removeLog(int index) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final targetLog = currentLogs[index];

    try {
      if (targetLog.id == null) throw Exception("ID Log tidak ditemukan.");

      await MongoService().deleteLog(targetLog.id!);

      currentLogs.removeAt(index);
      logsNotifier.value = currentLogs;

      await LogHelper.writeLog("SUCCESS: Sinkronisasi Hapus Berhasil", source: "log_controller.dart", level: 2);
    } catch (e) {
      await LogHelper.writeLog("ERROR: Gagal sinkronisasi Hapus - $e", source: "log_controller.dart", level: 1);
    }
  }

  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(logsNotifier.value.map((log) => log.toMap()).toList());
    await prefs.setString(_storageKey, encodedData);
  }

  Future<void> loadFromDisk() async {
    final cloudData = await MongoService().getLogs();
    logsNotifier.value = cloudData;
  }
}