import 'package:flutter/material.dart';
import 'package:logbook_app/features/logbook/models/log_model.dart';
import 'package:logbook_app/features/logbook/log_controller.dart'; 
import 'package:logbook_app/features/auth/login_view.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {

  final LogController _controller = LogController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String _selectedCategory = "Pribadi";

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Urgent': return Colors.red.shade100;
      case 'Pekerjaan': return Colors.blue.shade100;
      case 'Pribadi': default: return Colors.green.shade100;
    }
  }

  void _showLogDialog({LogModel? existingLog}) {
    final bool isEdit = existingLog != null;
    
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
        // Menggunakan StatefulBuilder agar Dropdown bisa diubah di dalam dialog
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
                  // DROPDOWN KATEGORI
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
                      _controller.updateLog(existingLog.timestamp, _titleController.text, _contentController.text, _selectedCategory);
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
            tooltip: 'Logout', 
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Konfirmasi Logout"),
                  content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context), // Batal
                      child: const Text("Batal"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginView()),
                          (Route<dynamic> route) => false, 
                        );
                      },
                      child: const Text("Logout", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        // === BATAS AKHIR ACTIONS ===
      ),
      body: Column(
        children: [
          // 1. SEARCH FEATURE (TextField)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) => _controller.searchLog(value),
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
            // MENDENGARKAN FILTERED LOGS, BUKAN LOGS NOTIFIER UTAMA
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.filteredLogs, 
              builder: (context, currentLogs, child) {
                
                // 2. EMPTY STATE
                if (currentLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.speaker_notes_off, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          "Belum ada catatan di sini.",
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: currentLogs.length,
                  itemBuilder: (context, index) {
                    final log = currentLogs[index];
                    
                    // 3. SWIPE TO DELETE (Dismissible)
                    return Dismissible(
                      key: Key(log.timestamp.toIso8601String()), // Key unik
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        _controller.removeLog(log.timestamp); 
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Catatan berhasil dihapus")),
                        );
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
                                "${log.category} • ${log.timestamp.toString().substring(0, 16)}",
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.black54),
                            onPressed: () => _showLogDialog(existingLog: log),
                          ),
                        ),
                      ),
                    );
                  },
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