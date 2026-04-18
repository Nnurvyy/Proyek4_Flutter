import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image/image.dart' as img;
import 'image_processor.dart';

class ImageTask {
  final Uint8List imageBytes;
  final String category;
  final String operation;
  final int value;

  final Uint8List? referenceBytes;

  ImageTask(this.imageBytes, this.category, this.operation, this.value, {this.referenceBytes});
}

// Global function for Isolate
Uint8List processImageInIsolate(ImageTask task) {
  final image = img.decodeImage(task.imageBytes);
  if (image == null) return task.imageBytes;

  img.Image result = image;
  if (task.category == 'Grayscale') {
    result = ImageProcessor.grayscale(image);
  } else if (task.category == 'Arithmetic') {
    result = ImageProcessor.arithmeticOperation(image, task.operation, task.value);
  } else if (task.category == 'Logic') {
    img.Image? refImg;
    if (task.referenceBytes != null) refImg = img.decodeImage(task.referenceBytes!);
    result = ImageProcessor.logicOperation(image, refImg, task.operation);
  } else if (task.category == 'Spatial Filter') {
    result = ImageProcessor.spatialFilter(image, task.operation, task.value);
  } else if (task.category == 'Frequency Domain / Other') {
    result = ImageProcessor.frequencyDomainMock(image, task.operation);
  } else if (task.category == 'Histogram Equalization') {
    result = ImageProcessor.equalizeHistogram(image);
  } else if (task.category == 'Histogram Specification') {
    if (task.referenceBytes != null) {
        final refImg = img.decodeImage(task.referenceBytes!);
        if (refImg != null) {
            result = ImageProcessor.specifyHistogram(image, refImg);
        }
    }
  }

  return img.encodePng(result);
}

Map<String, double> calculateStatsInIsolate(HistogramTask task) {
  final image = img.decodeImage(task.imageBytes);
  if (image == null) return {'mean_intensity': 0.0, 'std_deviation': 0.0};
  return ImageProcessor.calculateStatistics(image);
}

class HistogramTask {
  final Uint8List imageBytes;
  HistogramTask(this.imageBytes);
}

List<int> calculateHistogramInIsolate(HistogramTask task) {
  final image = img.decodeImage(task.imageBytes);
  if (image == null) return List.filled(256, 0);
  return ImageProcessor.calculateGrayscaleHistogram(image);
}

class ImageManipulationView extends StatefulWidget {
  const ImageManipulationView({super.key});

  @override
  State<ImageManipulationView> createState() => _ImageManipulationViewState();
}

class _ImageManipulationViewState extends State<ImageManipulationView> {
  Uint8List? _originalImage;
  Uint8List? _referenceImage; // New reference image
  Uint8List? _modifiedImage;
  List<int>? _histogramData;
  Map<String, double>? _statisticsData; // New statistics data

  bool _isProcessing = false;

  final ImagePicker _picker = ImagePicker();

  String _selectedCategory = 'Grayscale';
  String _selectedOperation = '';
  int _sliderValue = 50;

  final Map<String, List<String>> _operationsMenu = {
    'Grayscale': ['convert'],
    'Arithmetic': ['add', 'subtract', 'max', 'min', 'inverse'],
    'Logic': ['not', 'and', 'xor'],
    'Spatial Filter': [
      'conv_average',
      'conv_sharpen',
      'conv_edge',
      'filter_low',
      'filter_high',
      'padding'
    ],
    'Frequency Domain / Other': ['fourier', 'noise_reduction'],
    'Histogram': ['view'],
    'Histogram Equalization': ['equalize'],
    'Histogram Specification': ['specify'],
    'Statistics': ['calculate'],
  };

  @override
  void initState() {
    super.initState();
    _selectedOperation = _operationsMenu[_selectedCategory]!.first;
  }

  Future<void> _pickImage({bool isReference = false}) async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      setState(() {
        if (isReference) {
          _referenceImage = bytes;
        } else {
          _originalImage = bytes;
          _modifiedImage = null;
          _histogramData = null;
          _statisticsData = null;
        }
      });
    }
  }

  Future<void> _processImage() async {
    if (_originalImage == null) return;

    setState(() {
      _isProcessing = true;
      _histogramData = null;
      _statisticsData = null;
      _modifiedImage = null;
    });

    try {
      if (_selectedCategory == 'Histogram') {
        final result = await compute(calculateHistogramInIsolate, HistogramTask(_originalImage!));
        setState(() {
          _histogramData = result;
        });
      } else if (_selectedCategory == 'Statistics') {
        final result = await compute(calculateStatsInIsolate, HistogramTask(_originalImage!));
        setState(() {
          _statisticsData = result;
        });
      } else {
        final result = await compute(
            processImageInIsolate,
            ImageTask(
              _originalImage!,
              _selectedCategory,
              _selectedOperation,
              _sliderValue,
              referenceBytes: _referenceImage
            ));
        setState(() {
          _modifiedImage = result;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Widget _buildHistogramChart() {
    if (_histogramData == null) return const SizedBox();

    double maxVal = _histogramData!.reduce((curr, next) => curr > next ? curr : next).toDouble();
    if (maxVal == 0) maxVal = 1;

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < 256; i++) {
        barGroups.add(
            BarChartGroupData(
                x: i,
                barRods: [
                    BarChartRodData(
                        toY: _histogramData![i].toDouble(),
                        color: Colors.blueAccent,
                        width: 1.5,
                        borderRadius: BorderRadius.zero,
                    )
                ],
            )
        );
    }

    return Container(
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          maxY: maxVal,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manipulasi Citra'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Panel Gambar Original & Modified
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text("Citra Asli", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                          image: _originalImage != null
                              ? DecorationImage(
                                  image: MemoryImage(_originalImage!),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: _originalImage == null
                            ? const Center(child: Icon(Icons.image, size: 50, color: Colors.grey))
                            : null,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.upload),
                        label: const Text("Pilih Foto Utama"),
                        onPressed: () => _pickImage(isReference: false),
                      ),
                      const SizedBox(height: 12),
                      
                      // Reference Image Section (Only visible when needed)
                      if (_selectedCategory == 'Histogram Specification' || 
                         (_selectedCategory == 'Logic' && (_selectedOperation == 'and' || _selectedOperation == 'xor')))
                        Column(
                          children: [
                            const Divider(),
                            const Text("Citra Referensi", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                                image: _referenceImage != null
                                    ? DecorationImage(
                                        image: MemoryImage(_referenceImage!),
                                        fit: BoxFit.cover)
                                    : null,
                              ),
                              child: _referenceImage == null
                                  ? const Center(child: Icon(Icons.image, size: 30, color: Colors.grey))
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.upload),
                              label: const Text("Pilih Referensi"),
                              onPressed: () => _pickImage(isReference: true),
                            )
                          ],
                        )
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      const Text("Hasil Proses", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      const SizedBox(height: 8),
                      // Tampilan Output (Gambar atau Teks Statistik)
                      _statisticsData != null
                          ? Container(
                              height: 200,
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.indigo.shade100, width: 2),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Statistik Piksel (Luma):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 12),
                                  Text("Mean Intensity:\n${_statisticsData!['mean_intensity']?.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, color: Colors.indigo)),
                                  const SizedBox(height: 12),
                                  Text("Standard Deviation:\n${_statisticsData!['std_deviation']?.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, color: Colors.indigo)),
                                ],
                              ),
                            )
                          : Container(
                              height: 200,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.indigo.shade100, width: 2),
                        ),
                        child: _isProcessing
                            ? const CircularProgressIndicator()
                            : _modifiedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(_modifiedImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                                  )
                                : const Text("Belum Ada Hasil", style: TextStyle(color: Colors.indigo)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Konfigurasi Alat
            Text("Pengaturan Alat Pengolah", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  // Dropdown Kategori
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Kategori Filter",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.category, color: Colors.indigo),
                    ),
                    value: _selectedCategory,
                    items: _operationsMenu.keys.map((String key) {
                      return DropdownMenuItem<String>(value: key, child: Text(key));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCategory = val;
                          _selectedOperation = _operationsMenu[val]!.first;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dropdown Operasi
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Pilih Operasi Spesifik",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.settings, color: Colors.indigo),
                    ),
                    value: _selectedOperation,
                    items: _operationsMenu[_selectedCategory]!.map((String op) {
                      return DropdownMenuItem<String>(value: op, child: Text(op.toUpperCase()));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedOperation = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Slider Nilai Form (untuk Aritmatika, Padding dsb)
                  if (_selectedCategory == 'Arithmetic' || _selectedCategory == 'Spatial Filter')
                    Column(
                      children: [
                        Text("Intensitas / Value: $_sliderValue", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Slider(
                          value: _sliderValue.toDouble(),
                          min: 0,
                          max: 255,
                          divisions: 255,
                          label: _sliderValue.toString(),
                          activeColor: Colors.indigo,
                          onChanged: (val) {
                            setState(() {
                              _sliderValue = val.toInt();
                            });
                          },
                        ),
                      ],
                    ),
                    
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: (_originalImage == null || _isProcessing) ? null : _processImage,
                      icon: const Icon(Icons.memory),
                      label: const Text("PROSES CITRA SEKARANG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tampilan Histogram jika dipilih 
            if (_selectedCategory == 'Histogram' && _histogramData != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Text("Grafik Histogram Luma (Grayscale)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildHistogramChart(),
                ],
              )
          ],
        ),
      ),
    );
  }
}
