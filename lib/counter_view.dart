import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});
  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  Color _getLogColor (String log) {
    if (log.contains("menambahkan")) {
      return Colors.green;
    } else if (log.contains("mengurangi")) {
      return Colors.red;
    } else if (log.contains("Reset")) {
      return Colors.orange;
    }
    return Colors.black;
  }

  void _showResetConfirmation() {
    showDialog(
      context : context, 
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Reset"),
        content: const Text("Apakah Anda yakin ingin mereset counter?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Tutup dialog
            },
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _controller.reset();
              });
              Navigator.of(context).pop(); // Tutup dialog setelah reset

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar (
                  content: Text("Counter telah direset."),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating
                )
              );
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

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

            const Text("5 Aktivitas Terakhir:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._controller.activityLogs.map((log) => Padding(
              padding: const EdgeInsets.all(4.0), // Jarak antar teks
              child: Text(log, style: TextStyle(color: _getLogColor(log))),
            )),
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
              heroTag: "btn_dec",
              onPressed: () => setState(() => _controller.decrement()),
              backgroundColor: Colors.red[50],
              child: const Icon(Icons.remove, color: Colors.red),
            ),
            
            // TOMBOL RESET DENGAN DIALOG
            FloatingActionButton(
              heroTag: "btn_reset",
              onPressed: _showResetConfirmation, // Panggil fungsi dialog
              backgroundColor: Colors.orange[50],
              child: const Icon(Icons.refresh, color: Colors.orange),
            ),
            
            FloatingActionButton(
              heroTag: "btn_inc",
              onPressed: () => setState(() => _controller.increment()),
              backgroundColor: Colors.green[50],
              child: const Icon(Icons.add, color: Colors.green),
            ),
          ]
        ),
      ),
    );
  }
}
