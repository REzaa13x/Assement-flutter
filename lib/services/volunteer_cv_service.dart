import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' show XFile;

class VolunteerCvService {
  static const maxBytes = 2 * 1024 * 1024;

  static Future<Uint8List> readPdf(PlatformFile file) async {
    if (!file.name.trim().toLowerCase().endsWith('.pdf')) {
      throw Exception('Hanya menerima file PDF.');
    }
    if (file.size > maxBytes) {
      throw Exception('Ukuran file melebihi batas 2 MB.');
    }
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.readStream != null) {
      final builder = BytesBuilder(copy: false);
      await for (final chunk in file.readStream!) {
        builder.add(chunk);
        if (builder.length > maxBytes) {
          throw Exception('Ukuran file melebihi batas 2 MB.');
        }
      }
      bytes = builder.takeBytes();
    }
    if (bytes == null && !kIsWeb && file.path != null) {
      bytes = await XFile(file.path!).readAsBytes();
    }
    if (bytes == null || bytes.isEmpty) {
      throw Exception(
          'File PDF kosong atau tidak dapat dibaca. Unduh file ke perangkat lalu pilih kembali.');
    }
    if (bytes.length > maxBytes) {
      throw Exception('Ukuran file melebihi batas 2 MB.');
    }
    // PDF headers may follow a short binary prefix; MIME alone is insufficient.
    final header = String.fromCharCodes(bytes.take(1024));
    if (!header.contains('%PDF-')) {
      throw Exception(
          'Isi file bukan PDF yang valid. Silakan pilih file PDF asli.');
    }
    return bytes;
  }
}
