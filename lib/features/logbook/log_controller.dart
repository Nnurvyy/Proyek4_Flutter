import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app/features/logbook/models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);

  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);
  static const String _storageKey = 'users_logs_data';

  LogController() { loadFromDisk(); }

  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogs.value = logsNotifier.value;
    } else {
      filteredLogs.value = logsNotifier.value
      .where((log) => log.title.toLowerCase().contains(query.toLowerCase())).toList();
    }
  }

  void addLog(String title, String desc, String category) {
    final newLog = LogModel(title: title, description: desc, timestamp : DateTime.now(), category: category,);
    logsNotifier.value = [...logsNotifier.value, newLog];
    filteredLogs.value = logsNotifier.value;
    saveToDisk();
  }

  void updateLog(DateTime id, String title, String desc, String category) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final index = currentLogs.indexWhere((log) => log.timestamp == id);

    if (index != -1) {
      currentLogs[index] = LogModel(title: title, description: desc, timestamp: id, category: category);
      logsNotifier.value = currentLogs;
      filteredLogs.value = currentLogs; 
      saveToDisk();
    }
  }

  void removeLog(DateTime id) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs.removeWhere((log) => log.timestamp == id);
    logsNotifier.value = currentLogs;

    final currentFiltered = List<LogModel>.from(filteredLogs.value);
    currentFiltered.removeWhere((log) => log.timestamp == id);
    filteredLogs.value = currentFiltered;

    saveToDisk();
  }

  void saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(logsNotifier.value.map((e) => e.toMap()).toList());
    await prefs.setString(_storageKey, encodedData);
  }

  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      final List decoded = jsonDecode(data);
      logsNotifier.value = decoded.map((e) => LogModel.fromMap(e)).toList();
      filteredLogs.value = logsNotifier.value;
    }
  }
}