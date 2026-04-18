import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:logbook_app/main.dart'; // To access global cameras

class FaceDatasetView extends StatefulWidget {
  const FaceDatasetView({super.key});

  @override
  State<FaceDatasetView> createState() => _FaceDatasetViewState();
}

class _FaceDatasetViewState extends State<FaceDatasetView> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  final TextEditingController _nameController = TextEditingController();
  
  bool _isCollecting = false;
  int _collectedCount = 0;
  final int _targetCount = 20;
  Timer? _captureTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) return;
    
    // Gunakan kamera depan jika ada
    CameraDescription? frontCamera;
    for (var camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        frontCamera = camera;
        break;
      }
    }
    frontCamera ??= cameras.first;

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _startCollection() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan nama wajah tersebut.')),
      );
      return;
    }

    setState(() {
      _isCollecting = true;
      _collectedCount = 0;
    });

    _captureTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      if (_collectedCount >= _targetCount) {
        _stopCollection();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selesai! 20 Wajah telah dikumpulkan.')),
        );
        return;
      }
      
      await _captureAndProcessFace(name);
    });
  }

  void _stopCollection() {
    _captureTimer?.cancel();
    setState(() {
      _isCollecting = false;
    });
  }

  Future<void> _captureAndProcessFace(String name) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      final XFile photo = await _cameraController!.takePicture();
      final InputImage inputImage = InputImage.fromFilePath(photo.path);
      
      // Deteksi wajah
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        // Ambil wajah pertama
        final face = faces.first;
        final boundingBox = face.boundingBox;

        // Potong (Crop) gambar murni pada wajah
        final bytes = await File(photo.path).readAsBytes();
        final img.Image? originalImage = img.decodeImage(bytes);

        if (originalImage != null) {
          final croppedFace = img.copyCrop(
            originalImage, 
            x: boundingBox.left.toInt().clamp(0, originalImage.width), 
            y: boundingBox.top.toInt().clamp(0, originalImage.height), 
            width: boundingBox.width.toInt().clamp(1, originalImage.width), 
            height: boundingBox.height.toInt().clamp(1, originalImage.height)
          );

          // Simpan ke direktori lokal
          final directory = await getApplicationDocumentsDirectory();
          final datasetDir = Directory('${directory.path}/dataset/$name');
          if (!await datasetDir.exists()) {
            await datasetDir.create(recursive: true);
          }

          final filePath = '${datasetDir.path}/img_${_collectedCount + 1}.jpg';
          final newFile = File(filePath);
          await newFile.writeAsBytes(img.encodeJpg(croppedFace));

          setState(() {
            _collectedCount++;
          });
        }
      }
    } catch (e) {
      debugPrint("Error processing face: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kolektor Dataset Wajah'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_cameraController!),
                if (_isCollecting)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    alignment: Alignment.center,
                    child: Text(
                      'Merekam... $_collectedCount / $_targetCount',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Wajah (Label)',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_isCollecting,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isCollecting ? _stopCollection : _startCollection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCollecting ? Colors.red : Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _isCollecting ? 'Berhenti' : 'Mulai Rekam Dataset (20 Foto)',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
