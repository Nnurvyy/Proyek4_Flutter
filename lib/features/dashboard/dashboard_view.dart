import 'package:flutter/material.dart';
import 'package:logbook_app/features/logbook/log_view.dart';
import 'package:logbook_app/features/vision/vision_view.dart';
import 'package:logbook_app/features/auth/login_view.dart';
import 'package:logbook_app/features/image_manipulation/image_manipulation_view.dart';
import 'package:logbook_app/features/face_dataset/face_dataset_view.dart';

class DashboardView extends StatelessWidget {
  final Map<String, dynamic> currentUser;

  const DashboardView({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final String currentUsername = currentUser['username'] ?? 'User';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Dashboard Utama",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Salutation
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Halo, $currentUsername!",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Pilih menu di bawah untuk melanjutkan aktivitas Anda.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                "Menu Layanan",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Menu 1: Manipulasi Citra
              _buildMenuCard(
                context,
                title: "Manipulasi Citra",
                description: "Upload foto untuk memanipulasi citra.",
                icon: Icons.image,
                color1: const Color(0xFF9C27B0),
                color2: const Color(0xFF6A1B9A),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ImageManipulationView(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Menu 2: Deteksi Jalan Rusak
              _buildMenuCard(
                context,
                title: "Deteksi Jalan Rusak",
                description: "Kamera pintar untuk deteksi jalan rusak secara real-time.",
                icon: Icons.camera_alt,
                color1: const Color(0xFF00BCD4),
                color2: const Color(0xFF0097A7),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VisionView(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Menu 3: Rekam Dataset Wajah
              _buildMenuCard(
                context,
                title: "Rekam Dataset Wajah",
                description: "Kumpulkan 20 deteksi wajah (Face Dataset) otomatis.",
                icon: Icons.face,
                color1: const Color(0xFFFF9800),
                color2: const Color(0xFFF57C00),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FaceDatasetView(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Menu 4: Logbook
              _buildMenuCard(
                context,
                title: "Logbook Tim",
                description: "Kelola catatan dan logbook aktivitas tim Anda.",
                icon: Icons.book,
                color1: const Color(0xFF4CAF50),
                color2: const Color(0xFF388E3C),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LogView(currentUser: currentUser),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color1, color2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
