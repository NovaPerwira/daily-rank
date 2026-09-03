import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// OCR on-device menggunakan Google ML Kit (hanya mobile: Android & iOS)
Future<String> performOcr(String path) async {
  final inputImage = InputImage.fromFile(File(path));
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final recognized = await recognizer.processImage(inputImage);
  await recognizer.close();
  return recognized.text;
}
