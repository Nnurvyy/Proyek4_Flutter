import 'package:flutter/material.dart';
import 'counter_controller.dart';
import 'package:logbook_app/features/onboarding/onboarding_view.dart';

class CounterView extends StatefulWidget {
  final String username;

  const CounterView({super.key, required this.username});
  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
 
  late CounterController _controller;
  bool _isLoading = true; 

  @override
  void initState() {
    super.initState();
    _controller = CounterController(widget.username);
    _loadInitialData();
  }

  void _loadInitialData() async {
    await _controller.loadData();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour >= 0 && hour < 11) {
      return "Selamat Pagi";
    } else if (hour >= 11 && hour < 15) {
      return "Selamat Siang";
    } else if (hour >= 15 && hour < 18) {
      return "Selamat Sore";
    } else {
      return "Selamat Malam";
    }
  }

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
      appBar: AppBar(
        title: Column(
          children : [
            Text(
              "${_getGreeting()}, ${widget.username}!",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              "LogBook App",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Konfirmasi Logout"),
                    content: const Text("Apakah Anda yakin? Data yang belum disimpan mungkin akan hilang."),
                    actions : [
                      TextButton(
                        onPressed: () =>  Navigator.pop(context),
                         
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const OnBoardingView()),
                            (route) => false,
                          );
                        },
                        child: const Text("Ya, Keluar", style: TextStyle(color:Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),

      body: _isLoading ? const Center(child: CircularProgressIndicator()) 
      : Center(
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

              Expanded(
                child: ListView(
                  children: _controller.activityLogs.map((log) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                    child: Text(log, style: TextStyle(color: _getLogColor(log)), textAlign: TextAlign.center),
                  )).toList(),
                )
              )
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
