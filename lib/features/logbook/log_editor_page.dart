import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app/features/logbook/models/log_model.dart';
import 'package:logbook_app/features/logbook/log_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final dynamic currentUser;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.currentUser,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _selectedCategory; 
  
  // 1. Tambahkan state isPublic di dalam State class
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    
    // 2. Inisialisasi nilai isPublic (ambil dari log jika edit, atau false jika baru)
    _isPublic = widget.log?.isPublic ?? false;
    
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );
    
    // Inisialisasi kategori
    _selectedCategory = widget.log?.category ?? 'Mechanical';


    // Listener agar Pratinjau terupdate otomatis
    _descController.addListener(() {
      setState(() {});
    });
  }

  void _save() {
    if (widget.log == null) {
      widget.controller.addLog(
        _titleController.text,
        _descController.text,
        _selectedCategory,           
        widget.currentUser['uid'] ?? 'unknown_user',   // [PERBAIKI INI] Tambahkan default
        widget.currentUser['teamId'] ?? 'default_team',// [PERBAIKI INI] Tambahkan default
        _isPublic,                   
      );
    } else {
      final String userRole = widget.currentUser['role'] ?? 'Anggota'; 
      
      widget.controller.updateLog(
        widget.index!,
        _titleController.text,
        _descController.text,
        _selectedCategory,           
        userRole,                    
        widget.currentUser['uid'] ?? 'unknown_user',   // [PERBAIKI INI] Tambahkan default
        _isPublic,                   
      );
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.log == null ? "Catatan Baru" : "Edit Catatan"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Editor"),
              Tab(text: "Pratinjau"),
            ],
          ),
          actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Editor
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Judul"),
                  ),
                  const SizedBox(height: 10),
                  
                  // Dropdown untuk Kategori
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: "Kategori"),
                    items: ['Mechanical', 'Electronic', 'Software'].map((String category) {
                      return DropdownMenuItem(value: category, child: Text(category));
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                  ),
                  
                  // 3. Tambahkan SwitchListTile untuk mengatur Catatan Publik/Privat
                  SwitchListTile(
                    title: const Text("Buat Catatan Publik"),
                    subtitle: const Text("Anggota tim lain bisa melihat catatan ini"),
                    value: _isPublic,
                    contentPadding: EdgeInsets.zero, // Menghilangkan padding agar sejajar dengan textfield
                    activeColor: Colors.blue,
                    onChanged: (bool value) {
                      setState(() {
                        _isPublic = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: "Tulis laporan dengan format Markdown...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab 2: Markdown Preview
            Markdown(data: _descController.text),
          ],
        ),
      ),
    );
  }
}