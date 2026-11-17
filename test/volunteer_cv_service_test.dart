import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/volunteer_cv_service.dart';

void main() {
  test('reads PDF returned as document stream without a filesystem path',
      () async {
    final bytes = utf8.encode('%PDF-1.4\nCV');
    final file = PlatformFile(
        name: 'CV.PDF',
        size: bytes.length,
        readStream: Stream.fromIterable(
            [bytes.take(4).toList(), bytes.skip(4).toList()]));
    expect(await VolunteerCvService.readPdf(file), bytes);
  });
  test('rejects empty or renamed files before uploading', () async {
    for (final bytes in [<int>[], utf8.encode('not a PDF')]) {
      expect(
          VolunteerCvService.readPdf(PlatformFile(
              name: 'cv.pdf',
              size: bytes.length,
              bytes: Uint8List.fromList(bytes))),
          throwsException);
    }
  });
  test('checks actual bytes even if picker reports an incorrect size',
      () async {
    expect(
        VolunteerCvService.readPdf(PlatformFile(
            name: 'cv.pdf',
            size: 1,
            bytes: Uint8List(VolunteerCvService.maxBytes + 1))),
        throwsException);
  });
}
