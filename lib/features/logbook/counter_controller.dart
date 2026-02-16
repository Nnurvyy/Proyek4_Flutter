import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CounterController {

  final String username;

  CounterController(this.username);

  int _counter = 0;
  int _step = 1;
  List<String> _activityLogs = [];

  List<String> get activityLogs => _activityLogs;
  int get value => _counter;
  int get step => _step;


  String get _keyCounter => 'counter_$username';
  String get _keyLogs => 'logs_$username';

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _counter = prefs.getInt(_keyCounter) ?? 0;
    _activityLogs = prefs.getStringList(_keyLogs) ?? [];
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCounter, _counter);
    await prefs.setStringList(_keyLogs, _activityLogs);
  }
  void _addLog(String action){
    DateTime now = DateTime.now();
    String formattedTime = DateFormat('HH:mm').format(now);
    String logMessage = "$action pada jam $formattedTime";
    _activityLogs.insert(0, logMessage);
    if (_activityLogs.length > 5) {
      _activityLogs.removeLast();
    }
  }
  void increment(){
    _counter+=_step;
    _addLog("User menambahkan nilai sebesar +$_step");
    _saveData();
  } 

  void decrement() {
    if (_counter > 0) {
      _counter -= _step;
    }
    _addLog("User mengurangi nilai sebesar -$_step");
    _saveData();
  } 
  void reset() {
    _counter = 0;
    _addLog("User melakukan Reset counter");
    _saveData();
  } 
  void updateStep(double newStep) {
    _step = newStep.round();
  } 
}