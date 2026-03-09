import 'package:flutter/material.dart';
import 'package:logbook_app/features/logbook/models/log_model.dart';
import 'package:logbook_app/features/logbook/log_controller.dart'; 
import 'package:logbook_app/features/auth/login_view.dart';
import 'package:logbook_app/services/access_control_service.dart';
import 'package:logbook_app/features/logbook/log_editor_page.dart'; 
import 'package:intl/intl.dart'; 
import 'package:intl/date_symbol_data_local.dart'; 
import '../../services/mongo_service.dart';

class LogView extends StatefulWidget {
  final dynamic currentUser; 
  
  const LogView({super.key, required this.currentUser});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {

  late LogController _controller;
  
  bool _isLoading = false; 
  bool _isOffline = false;
  String _searchQuery = ""; 

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

    final String teamId = widget.currentUser['teamId'] ?? 'default_team';

    try {
      await initializeDateFormatting('id_ID', null);
      
      // 1. Coba koneksi ke MongoDB terlebih dahulu
      await MongoService().connect().timeout(
        const Duration(seconds: 5), // Saya perkecil jadi 5 detik agar saat offline tidak nunggu loading kelamaan
        onTimeout: () => throw Exception("Timeout"),
      );
      
    } catch (e) {
      setState(() => _isOffline = true); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Offline Mode: Menggunakan data lokal."),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // 2. [PERBAIKAN UTAMA] 
      // Pindahkan loadLogs ke dalam blok 'finally' agar fungsi ini 
      // TETAP DIPANGGIL baik saat online maupun offline!
      await _controller.loadLogs(teamId);

      // Setelah data lokal selesai dimuat, matikan loading spinner
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isOffline = false); 
    try {
      final String teamId = widget.currentUser['teamId'] ?? 'default_team';
      await _controller.loadLogs(teamId);
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
      case 'Mechanical': return Colors.green.shade100; // Hijau untuk Mechanical (sesuai instruksi)
      case 'Electronic': return Colors.blue.shade100;  // Biru untuk Electronic (sesuai instruksi)
      case 'Software': return Colors.purple.shade100;  // Warna lain untuk software
      default: return Colors.grey.shade100;
    }
  }

  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: widget.currentUser, 
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserRole = widget.currentUser['role'] ?? 'Anggota';
    final String currentUserId = widget.currentUser['uid'] ?? 'unknown_user';
    final String currentUsername = widget.currentUser['username'] ?? 'User';

    final bool canCreate = AccessControlService.canPerform(
      currentUserRole, 
      AccessControlService.actionCreate
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Logbook: $currentUsername'),
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

                // ==========================================
                // TASK 5 (HINT 2): FILTER VISIBILITAS DATA
                // Tampilkan data JIKA: Pencarian Cocok DAN (Saya Pemiliknya ATAU Catatan Publik)
                // ==========================================
                final currentLogs = logs.where((log) {
                  final matchesSearch = log.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                      log.description.toLowerCase().contains(_searchQuery.toLowerCase());
                  final canSee = (log.authorId == currentUserId) || (log.isPublic == true);
                  return matchesSearch && canSee;
                }).toList();
                if (currentLogs.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshData,
                    child: ListView(
                      // physics ini WAJIB ada agar layar tetap bisa ditarik ke bawah meski kosong
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        
                        // 1. Ilustrasi/Ikon yang lebih relevan dan menarik
                        const Icon(
                          Icons.assignment_add, 
                          size: 80, 
                          color: Colors.blueGrey
                        ),
                        const SizedBox(height: 16),
                        
                        // 2. Teks instruksional sesuai dengan permintaan tugas
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            "Belum ada aktivitas hari ini?\nMulai catat kemajuan proyek Anda!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16, 
                              color: Colors.black54,
                              height: 1.5, // Memberikan jarak antar baris agar rapi
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // 3. Tombol CTA (Call to Action)
                        if (canCreate)
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => _goToEditor(),
                              icon: const Icon(Icons.add),
                              label: const Text("Buat Catatan"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
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
                      
                      final bool isOwner = (log.authorId == currentUserId);

                      // ==========================================
                      // TASK 5 (HINT 3): KEDAULATAN EDITOR
                      // Akses Edit & Delete sekarang MURNI hanya untuk Owner. Abaikan role Ketua.
                      // ==========================================
                      final bool canModify = isOwner; 

                      Widget logCard = Card(
                        color: _getCategoryColor(log.category),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          // ==========================================
                          // TASK 4 (POIN 3): CONNECTIVITY AWARENESS
                          // Ikon Awan Hijau jika sudah sync, Awan Oranye jika masih pending
                          // ==========================================
                          leading: Icon(
                            log.isSynced ? Icons.cloud_done : Icons.cloud_upload_outlined,
                            color: log.isSynced ? Colors.green : Colors.orange,
                          ),
                          title: Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, 
                            children: [
                              Text(log.description),
                              const SizedBox(height: 4),
                              // Menambahkan Indikator Teks Public/Private
                              Text(
                                "${log.category} • ${_formatDateTime(log.date)} • ${log.isPublic ? '🌐 Public' : '🔒 Private'}",
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                          // Hanya owner yang bisa melihat tombol edit
                          trailing: canModify 
                            ? IconButton(
                                icon: const Icon(Icons.edit, color: Colors.black54),
                                onPressed: () => _goToEditor(log: log, index: realIndex), 
                              )
                            : null, 
                        ),
                      );

                      // Hanya owner yang bisa menggeser untuk menghapus
                      if (canModify) {
                        return Dismissible(
                          key: Key(log.id ?? log.date.toIso8601String()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            _controller.removeLog(
                              realIndex, 
                              currentUserRole, 
                              currentUserId
                            ); 
                          },
                          child: logCard,
                        );
                      }

                      return logCard;
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canCreate 
        ? FloatingActionButton(
            onPressed: () => _goToEditor(), 
            child: const Icon(Icons.add),
          ) 
        : null, 
    );
  }
}