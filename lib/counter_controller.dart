class CounterController {
  int _counter = 0;
  int _step = 1;
  int get value => _counter;
  int get step => _step;
  void increment() => _counter+=_step;
  void decrement() => { if (_counter > 0) _counter-=_step };
  void reset() => _counter = 0;
  void updateStep(double newStep) => _step = newStep.round();
}