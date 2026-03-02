import 'package:flutter/material.dart';
import 'package:logbook_app/features/logbook/models/log_model.dart';
import 'package:logbook_app/features/logbook/log_controller.dart'; 
import 'package:logbook_app/features/auth/login_view.dart';
import 'package:intl/intl.dart'; 
import 'package:intl/date_symbol_data_local.dart'; 
import '../../services/mongo_service.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {

  late LogController _controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  bool _isLoading = false; 
  bool _isOffline = false;
  String _searchQuery = ""; 
  String _selectedCategory = "Pribadi";

  @override
  void initState() {
    super.initState();
    _controller = LogController();
    Future.microtask(() => _initDatabase());
  }

  Future<void> _initDatabase() async {
    setState(() {
      _isLoading = true;
      _isOffline = false; 
    });
    try {
      await initializeDateFormatting('id_ID', null);
      await MongoService().connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception("Timeout"),
      );
      await _controller.loadFromDisk();
    } catch (e) {
      setState(() => _isOffline = true); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Offline Mode: Gagal terhubung ke Cloud."),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isOffline = false); 
    try {
      await _controller.loadFromDisk();
    } catch (e) {
      setState(() => _isOffline = true); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Gagal memperbarui data. Anda sedang offline."),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

   
    if (difference.inMinutes < 1) {
      return "Baru saja";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} menit yang lalu";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} jam yang lalu";
    } else {
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Urgent': return Colors.red.shade100;
      case 'Pekerjaan': return Colors.blue.shade100;
      case 'Pribadi': default: return Colors.green.shade100;
    }
  }

  void _showLogDialog({LogModel? existingLog, int? index}) {
    final bool isEdit = existingLog != null && index != null;
    
    if (isEdit) {
      _titleController.text = existingLog.title;
      _contentController.text = existingLog.description;
      _selectedCategory = existingLog.category; 
    } else {
      _titleController.clear();
      _contentController.clear();
      _selectedCategory = 'Pribadi'; 
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? "Edit Catatan" : "Tambah Catatan Baru"),
              content: Column(
                mainAxisSize: MainAxisSize.min, 
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: "Judul Catatan"),
                  ),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(hintText: "Isi Deskripsi"),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: "Kategori"),
                    items: ['Pekerjaan', 'Pribadi', 'Urgent'].map((String category) {
                      return DropdownMenuItem(value: category, child: Text(category));
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setStateDialog(() { _selectedCategory = newValue; });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("Batal")
                ),
                ElevatedButton(
                  onPressed: () {
                    if (isEdit) {
                      _controller.updateLog(index, _titleController.text, _contentController.text, _selectedCategory);
                    } else {
                      _controller.addLog(_titleController.text, _contentController.text, _selectedCategory);
                    }
                    Navigator.pop(context);
                  },
                  child: Text(isEdit ? "Update" : "Simpan"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logbook: ${widget.username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
                (Route<dynamic> route) => false, 
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                labelText: "Cari Catatan berdasarkan judul...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.logsNotifier, 
              builder: (context, logs, child) {
                
                if (_isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Menghubungkan ke MongoDB Atlas..."),
                      ],
                    ),
                  );
                }

                if (_isOffline) {
                  return RefreshIndicator(
                    onRefresh: _refreshData,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        const Icon(Icons.wifi_off, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text("Anda sedang Offline.", 
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                          )
                        ),
                        const SizedBox(height: 8),
                        const Center(child: Text("Tarik layar ke bawah untuk mencoba lagi.")),
                      ],
                    ),
                  );
                }

                final currentLogs = logs.where((log) => 
                  log.title.toLowerCase().contains(_searchQuery.toLowerCase())
                ).toList();

                if (currentLogs.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshData,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Center(child: Text("Belum ada catatan di Cloud.")),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            onPressed: () => _showLogDialog(),
                            child: const Text("Buat Catatan Pertama"),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(), 
                    itemCount: currentLogs.length,
                    itemBuilder: (context, index) {
                      final log = currentLogs[index];
                      final realIndex = logs.indexOf(log);
                      
                      return Dismissible(
                        key: Key(log.id?.toHexString() ?? log.date.toIso8601String()), 
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          _controller.removeLog(realIndex); 
                        },
                        child: Card(
                          color: _getCategoryColor(log.category),
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: Icon(
                              Icons.circle, 
                              color: log.category == 'Urgent' ? Colors.red : Colors.blue, 
                              size: 16
                            ),
                            title: Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, 
                              children: [
                                Text(log.description),
                                const SizedBox(height: 4),
                                Text(
                                  "${log.category} • ${_formatDateTime(log.date)}",
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.black54),
                              onPressed: () => _showLogDialog(existingLog: log, index: realIndex),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLogDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}