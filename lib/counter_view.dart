import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});
  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LogBook: SRP Version")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 150),
            Text('Atur step: ${_controller.step}'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Slider(
                value: _controller.step.toDouble(), // Ubah int ke double agar Slider mau baca
                min: 1,  // Minimal step 1
                max: 20, // Maksimal step 20
                divisions: 19, // Agar slider "patah-patah" di angka bulat (integers)
                label: _controller.step.toString(), // Label saat digeser
                onChanged: (double newValue) {
                  // Saat digeser, panggil setState agar UI berubah
                  // dan panggil controller untuk simpan logika barunya
                  setState(() {
                    _controller.updateStep(newValue);
                  });
                },
              ),
            ),
            const SizedBox( height: 50),
            const Text("Total Hitungan:"),
            Text('${_controller.value}', style: const TextStyle(fontSize: 40)),
            const SizedBox( height: 30), // Spasi antara elemen
            const Divider(),  // Garis pemisah
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton : Padding(
        padding: const EdgeInsets.symmetric( horizontal : 10.0),
        child : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              onPressed: () => setState(() => _controller.decrement()),
              child: const Icon(Icons.remove),
            ),
            FloatingActionButton(
              onPressed: () => setState(() => _controller.reset()),
              child: const Icon(Icons.refresh),
            ),
            FloatingActionButton(
              onPressed: () => setState(() => _controller.increment()),
              child: const Icon(Icons.add),
            )
          ]
        ),
      ),
    );
  }
}
