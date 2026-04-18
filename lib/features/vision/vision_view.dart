import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:gal/gal.dart';
import 'vision_controller.dart';
import 'damage_painter.dart';

class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  late VisionController _visionController;

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();
    _visionController.startMockDetection();
  }

  @override
  void dispose() {
    _visionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // PERBAIKAN 2: ListenableBuilder dipindah ke PALING ATAS
    // Agar AppBar (Tombol Flash & Mata) ikut di-refresh saat ditekan
    return ListenableBuilder(
      listenable: _visionController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text("Smart-Patrol Vision"),
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(
                  _visionController.isFlashlightOn
                      ? Icons.flash_on
                      : Icons.flash_off,
                  color: _visionController.isFlashlightOn ? Colors.yellow : Colors.white,
                ),
                onPressed: _visionController.toggleFlashlight,
              ),
              IconButton(
                icon: Icon(
                  _visionController.isOverlayVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: _visionController.toggleOverlay,
              ),
            ],
          ),
          body: !_visionController.isInitialized
              ? _buildLoadingState()
              : _buildVisionStack(),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final image = await _visionController.takePhoto();
              if (image != null && context.mounted) {
                try {
                  await Gal.putImage(image.path);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Foto berhasil disimpan ke Galeri!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menyimpan foto: $e')),
                  );
                }
              }
            },
            child: const Icon(Icons.camera),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          const Text("Menghubungkan ke Sensor...", style: TextStyle(color: Colors.white)),
          if (_visionController.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(_visionController.errorMessage!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              child: const Text("Buka Pengaturan Izin"),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildVisionStack() {
    final size = MediaQuery.of(context).size;
    final cameraValue = _visionController.controller!.value;
    
    // PERBAIKAN 3: Logika Anti-Gepeng (Transform Scale)
    // Menghitung rasio layar vs rasio kamera agar gambar memenuhi layar (Cover)
    double scale = size.aspectRatio * cameraValue.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Stack(
      fit: StackFit.expand,
      children: [
        // LAYER 1: Kamera (Sekarang sudah tidak gepeng!)
        ClipRect(
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: Center(
              child: CameraPreview(_visionController.controller!),
            ),
          ),
        ),

        // LAYER 2: Overlay (Sekarang bisa di-hide/show!)
        if (_visionController.isOverlayVisible)
          Positioned.fill(
            child: CustomPaint(
              painter: DamagePainter(_visionController.currentDetections),
            ),
          ),
      ],
    );
  }
}