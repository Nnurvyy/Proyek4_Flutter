import 'package:intl/intl.dart';

class CounterController {
  int _counter = 0;
  int _step = 1;
  List<String> _activityLogs = [];

  List<String> get activityLogs => _activityLogs;
  int get value => _counter;
  int get step => _step;

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
  } 

  void decrement() {
    if (_counter > 0) {
      _counter -= _step;
    }
    _addLog("User mengurangi nilai sebesar -$_step");
  } 
  void reset() {
    _counter = 0;
    _addLog("User melakukan Reset counter");
  } 
  void updateStep(double newStep) {
    _step = newStep.round();
    _addLog("User mengubah step menjadi $_step");
  } 
}