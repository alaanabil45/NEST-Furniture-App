import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:path_provider/path_provider.dart';

class CutoutException implements Exception {
  CutoutException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CutoutResult {
  const CutoutResult({
    required this.png,
    required this.width,
    required this.height,
    required this.original,
  });

  /// Transparent PNG of the piece, cropped to its edges.
  final Uint8List png;
  final int width;
  final int height;

  /// The (resized) photo, for the before / after comparison.
  final Uint8List original;

  double get aspect => width / height;
}

class _Composed {
  const _Composed(this.png, this.width, this.height);

  final Uint8List png;
  final int width;
  final int height;
}

/// Removes the background of a photo on the phone with Google ML Kit
/// (Subject Segmentation, Android only).
class BackgroundRemover {
  static Future<CutoutResult> run(
    String path, {
    void Function(String status)? onStatus,
  }) async {
    onStatus?.call('Preparing your photo…');

    // Decode (this also applies the photo's rotation) and shrink it.
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1024);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final w = image.width;
    final h = image.height;
    final pngData = await image.toByteData(format: ui.ImageByteFormat.png);
    final rgbaData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    codec.dispose();
    if (pngData == null || rgbaData == null) {
      throw CutoutException('Could not read that photo.');
    }
    final original = pngData.buffer.asUint8List(
      pngData.offsetInBytes,
      pngData.lengthInBytes,
    );
    final rgba = rgbaData.buffer.asUint8List(
      rgbaData.offsetInBytes,
      rgbaData.lengthInBytes,
    );

    // ML Kit reads a file, so save the prepared photo for a moment.
    final temp = await getTemporaryDirectory();
    final prep = File(
      '${temp.path}/nest_prep_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await prep.writeAsBytes(original, flush: true);

    onStatus?.call('Finding the piece…');
    final segmenter = SubjectSegmenter(
      options: SubjectSegmenterOptions(
        enableForegroundConfidenceMask: true,
        enableForegroundBitmap: false,
        enableMultipleSubjects: SubjectResultOptions(
          enableConfidenceMask: false,
          enableSubjectBitmap: false,
        ),
      ),
    );

    bool looksLikeDownload(String text) {
      final t = text.toLowerCase();
      return t.contains('download') ||
          t.contains('module') ||
          t.contains('wait') ||
          t.contains('unavailable');
    }

    List<num>? mask;
    String? lastError;
    final started = DateTime.now();
    const maxAttempts = 20;
    try {
      // The first time, Google Play services has to download the AI model,
      // which can take a minute, so keep trying for a while.
      for (var attempt = 0; attempt < maxAttempts && mask == null; attempt++) {
        try {
          final result = await segmenter.processImage(
            InputImage.fromFilePath(prep.path),
          );
          final m = result.foregroundConfidenceMask;
          if (m != null && m.isNotEmpty) {
            mask = m;
          } else {
            lastError = 'The model returned an empty result.';
          }
        } catch (error) {
          lastError = '$error';
          debugPrint('NEST segmentation attempt ${attempt + 1} failed: $error');
        }

        if (mask != null) break;

        // A real error (not a download) will not fix itself, so stop early.
        if (attempt >= 2 &&
            lastError != null &&
            !looksLikeDownload(lastError)) {
          break;
        }

        if (attempt < maxAttempts - 1) {
          final seconds = DateTime.now().difference(started).inSeconds;
          onStatus?.call(
            'Downloading the AI model… ${seconds}s (first time only)',
          );
          await Future<void>.delayed(const Duration(seconds: 4));
        }
      }
    } finally {
      segmenter.close();
      try {
        await prep.delete();
      } catch (_) {}
    }

    final found = mask;
    if (found == null) {
      final detail = (lastError ?? 'unknown').replaceAll('\n', ' ');
      throw CutoutException('The AI model did not respond. ($detail)');
    }

    onStatus?.call('Cutting out the background…');
    final confidence = Float32List(found.length);
    for (var i = 0; i < confidence.length; i++) {
      confidence[i] = found[i].toDouble();
    }

    final composed = await Isolate.run(() => _compose(rgba, confidence, w, h));
    return CutoutResult(
      png: composed.png,
      width: composed.width,
      height: composed.height,
      original: original,
    );
  }
}

/// Runs in a background isolate: applies the mask, crops, encodes a PNG.
_Composed _compose(Uint8List rgba, Float32List mask, int w, int h) {
  var mw = w;
  var mh = h;
  if (mask.length != w * h) {
    mw = math.sqrt(mask.length * w / h).round();
    mh = mw == 0 ? 0 : mask.length ~/ mw;
    if (mw <= 0 || mw * mh != mask.length) {
      throw CutoutException('Unexpected result from the AI model.');
    }
  }

  final alpha = Uint8List(w * h);
  var foreground = 0;
  var minX = w;
  var minY = h;
  var maxX = -1;
  var maxY = -1;

  for (var y = 0; y < h; y++) {
    final my = mh == h ? y : (y * mh ~/ h);
    for (var x = 0; x < w; x++) {
      final mx = mw == w ? x : (x * mw ~/ w);
      final c = mask[my * mw + mx];
      var a = ((c - 0.35) / 0.3).clamp(0.0, 1.0).toDouble();
      a = a * a * (3 - 2 * a);
      final v = (a * 255).round();
      alpha[y * w + x] = v;
      if (v > 16) {
        foreground++;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (maxX < 0 || foreground < w * h * 0.02) {
    throw CutoutException(
      'We couldn’t find a clear piece in that photo. Try a plainer background and good light.',
    );
  }

  final pad = (math.max(maxX - minX, maxY - minY) * 0.03).round();
  final x0 = math.max(0, minX - pad);
  final y0 = math.max(0, minY - pad);
  final x1 = math.min(w - 1, maxX + pad);
  final y1 = math.min(h - 1, maxY + pad);
  final cw = x1 - x0 + 1;
  final ch = y1 - y0 + 1;

  final cropped = Uint8List(cw * ch * 4);
  for (var y = 0; y < ch; y++) {
    final srcRow = (y + y0) * w + x0;
    var di = y * cw * 4;
    for (var x = 0; x < cw; x++) {
      final si = (srcRow + x) * 4;
      cropped[di] = rgba[si];
      cropped[di + 1] = rgba[si + 1];
      cropped[di + 2] = rgba[si + 2];
      cropped[di + 3] = alpha[srcRow + x];
      di += 4;
    }
  }

  return _Composed(_encodePng(cropped, cw, ch), cw, ch);
}

// ------------------------------------------------------------ PNG encoder

final List<int> _crcTable = () {
  final table = List<int>.filled(256, 0);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    table[n] = c;
  }
  return table;
}();

int _crc32(Uint8List data) {
  var c = 0xFFFFFFFF;
  for (final b in data) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

Uint8List _encodePng(Uint8List rgba, int w, int h) {
  final stride = w * 4;
  final raw = Uint8List(h * (stride + 1));
  for (var y = 0; y < h; y++) {
    final o = y * (stride + 1);
    raw[o] = 0;
    raw.setRange(o + 1, o + 1 + stride, rgba, y * stride);
  }
  final compressed = ZLibCodec(level: 4).encode(raw);

  final out = BytesBuilder();
  out.add(const [137, 80, 78, 71, 13, 10, 26, 10]);

  void chunk(String type, List<int> data) {
    final body = Uint8List(4 + data.length)
      ..setRange(0, 4, type.codeUnits)
      ..setRange(4, 4 + data.length, data);
    final length = ByteData(4)..setUint32(0, data.length);
    final crc = ByteData(4)..setUint32(0, _crc32(body));
    out.add(length.buffer.asUint8List());
    out.add(body);
    out.add(crc.buffer.asUint8List());
  }

  final header = ByteData(13)
    ..setUint32(0, w)
    ..setUint32(4, h)
    ..setUint8(8, 8)
    ..setUint8(9, 6)
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  chunk('IHDR', header.buffer.asUint8List());
  chunk('IDAT', compressed);
  chunk('IEND', const <int>[]);
  return out.toBytes();
}
