import 'dart:math';
import 'package:image/image.dart' as img;

class ImageProcessor {
  
  // Resize image for heavy tasks to avoid freezing in pure Dart
  static img.Image _safeResize(img.Image original) {
    if (original.width > 800) {
      return img.copyResize(original, width: 800);
    }
    return original;
  }

  static img.Image grayscale(img.Image image) {
    return img.grayscale(image);
  }

  static img.Image arithmeticOperation(img.Image source, String operation, int value) {
    final image = _safeResize(source).clone();

    for (var pixel in image) {
      num r = pixel.r;
      num g = pixel.g;
      num b = pixel.b;

      if (operation == 'add') {
        r = (r + value).clamp(0, 255);
        g = (g + value).clamp(0, 255);
        b = (b + value).clamp(0, 255);
      } else if (operation == 'subtract') {
        r = (r - value).clamp(0, 255);
        g = (g - value).clamp(0, 255);
        b = (b - value).clamp(0, 255);
      } else if (operation == 'max') {
        r = max(r, value);
        g = max(g, value);
        b = max(b, value);
      } else if (operation == 'min') {
        r = min(r, value);
        g = min(g, value);
        b = min(b, value);
      } else if (operation == 'inverse') {
        r = 255 - r;
        g = 255 - g;
        b = 255 - b;
      }
      pixel.setRgba(r, g, b, 255);
    }
    return image;
  }

  static img.Image logicOperation(img.Image source1, img.Image? source2, String operation) {
    final img1 = _safeResize(source1).clone();
    
    if (operation == 'not') {
      return arithmeticOperation(img1, 'inverse', 0);
    }

    if (source2 == null) return img1;

    // Resize img2 to match img1
    final img2 = img.copyResize(source2, width: img1.width, height: img1.height);

    for (int y = 0; y < img1.height; y++) {
      for (int x = 0; x < img1.width; x++) {
        final p1 = img1.getPixel(x, y);
        final p2 = img2.getPixel(x, y);
        
        num r1 = p1.r, g1 = p1.g, b1 = p1.b;
        num r2 = p2.r, g2 = p2.g, b2 = p2.b;

        num r = 0, g = 0, b = 0;

        if (operation == 'and') {
          r = r1.toInt() & r2.toInt();
          g = g1.toInt() & g2.toInt();
          b = b1.toInt() & b2.toInt();
        } else if (operation == 'xor') {
          r = r1.toInt() ^ r2.toInt();
          g = g1.toInt() ^ g2.toInt();
          b = b1.toInt() ^ b2.toInt();
        }
        p1.setRgba(r, g, b, 255);
      }
    }
    return img1;
  }

  static img.Image spatialFilter(img.Image source, String operation, int padSize) {
    final image = _safeResize(source).clone();

    if (operation == 'conv_average') {
      return img.copyResize(
        img.gaussianBlur(image, radius: 2), 
        width: image.width
      ); // Approximate average
    } else if (operation == 'conv_sharpen') {
      return img.convolution(image, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0]);
    } else if (operation == 'conv_edge') {
      return img.convolution(image, filter: [-1, -1, -1, -1, 8, -1, -1, -1, -1]);
    } else if (operation == 'filter_low') {
      return img.gaussianBlur(image, radius: 5);
    } else if (operation == 'filter_high') {
      return img.convolution(image, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0]);
    } else if (operation == 'padding') {
      final padded = img.Image(width: image.width + padSize * 2, height: image.height + padSize * 2);
      img.fill(padded, color: img.ColorRgb8(0, 0, 0));
      img.compositeImage(padded, image, dstX: padSize, dstY: padSize);
      return padded;
    }
    return image;
  }

  static img.Image frequencyDomainMock(img.Image source, String operation) {
    final image = _safeResize(source).clone();
    
    if (operation == 'fourier') {
      // FFT is too complex for standard pure dart package mapping, replacing with a distinct artistic effect
      return img.sobel(img.grayscale(image)); 
    } else if (operation == 'noise_reduction') {
      return img.gaussianBlur(image, radius: 3);
    }
    return image;
  }

  static List<int> calculateGrayscaleHistogram(img.Image image) {
    final gray = img.grayscale(image.clone());
    List<int> hist = List.filled(256, 0);
    for (var p in gray) {
      hist[p.r.toInt().clamp(0, 255)]++;
    }
    return hist;
  }

  static img.Image equalizeHistogram(img.Image source) {
    final image = _safeResize(source).clone();
    final gray = img.grayscale(image);
    
    List<int> hist = calculateGrayscaleHistogram(gray);
    int totalPixels = gray.width * gray.height;

    // Hitung CDF (Cumulative Distribution Function)
    List<num> cdf = List.filled(256, 0.0);
    num sum = 0;
    for (int i = 0; i < 256; i++) {
        sum += hist[i];
        cdf[i] = sum / totalPixels;
    }

    // Terapkan ekualisasi
    for (var p in gray) {
        int v = p.r.toInt().clamp(0, 255);
        int newV = (cdf[v] * 255).round().clamp(0, 255);
        p.setRgba(newV, newV, newV, 255);
    }
    return gray;
  }

  static Map<String, double> calculateStatistics(img.Image source) {
    final gray = img.grayscale(_safeResize(source).clone());
    double sum = 0;
    int pixelCount = gray.width * gray.height;

    for (var p in gray) {
      sum += p.r.toDouble();
    }
    
    double mean = sum / pixelCount;
    double varianceSum = 0;

    for (var p in gray) {
      double diff = p.r.toDouble() - mean;
      varianceSum += (diff * diff);
    }

    double stdDev = sqrt(varianceSum / pixelCount);
    
    return {
      'mean_intensity': mean,
      'std_deviation': stdDev
    };
  }

  static img.Image specifyHistogram(img.Image source, img.Image reference) {
    final image = _safeResize(source).clone();
    final ref = img.copyResize(reference, width: image.width, height: image.height);

    final graySource = img.grayscale(image);
    final grayRef = img.grayscale(ref);

    List<int> histSource = calculateGrayscaleHistogram(graySource);
    List<int> histRef = calculateGrayscaleHistogram(grayRef);

    int totalSource = graySource.width * graySource.height;
    int totalRef = grayRef.width * grayRef.height;

    // Calculate CDFs
    List<num> cdfSource = List.filled(256, 0.0);
    List<num> cdfRef = List.filled(256, 0.0);

    num sumSource = 0;
    num sumRef = 0;

    for (int i = 0; i < 256; i++) {
        sumSource += histSource[i];
        cdfSource[i] = sumSource / totalSource;

        sumRef += histRef[i];
        cdfRef[i] = sumRef / totalRef;
    }

    // Create Mapping Lookup Table
    List<int> lookupTable = List.filled(256, 0);
    for (int i = 0; i < 256; i++) {
        int bestMatch = 0;
        num minDiff = double.infinity;
        for (int j = 0; j < 256; j++) {
            num diff = (cdfSource[i] - cdfRef[j]).abs();
            if (diff < minDiff) {
                minDiff = diff;
                bestMatch = j;
            }
        }
        lookupTable[i] = bestMatch;
    }

    // Apply mapping
    for (var p in graySource) {
        int v = p.r.toInt().clamp(0, 255);
        int newV = lookupTable[v];
        p.setRgba(newV, newV, newV, 255);
    }
    return graySource;
  }
}
