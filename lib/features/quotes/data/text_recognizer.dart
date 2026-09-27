import 'package:flutter/services.dart';

/// Reads the text in a photo of a page, on the device (Apple Vision on iOS,
/// ML Kit on Android; see AppDelegate.swift and MainActivity.kt).
class TextRecognizer {
  const TextRecognizer();

  static const _channel = MethodChannel('bookshelf/text_recognition');

  /// The recognized text as one passage, or an empty string when the photo
  /// has no readable text. Throws [PlatformException] if recognition fails.
  Future<String> recognize(String imagePath) async {
    final lines = await _channel.invokeListMethod<String>(
      'recognize',
      {'path': imagePath},
    );
    return joinLines(lines ?? const []);
  }

  static final _hyphenBreak = RegExp(r'[-­]$');
  static final _spaces = RegExp(r'\s+');

  /// Joins the lines of a printed page into running text: a word hyphenated
  /// across two lines is put back together.
  static String joinLines(List<String> lines) {
    final buffer = StringBuffer();
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final text = buffer.toString();
      if (text.isEmpty) {
        buffer.write(line);
      } else if (_hyphenBreak.hasMatch(text)) {
        buffer
          ..clear()
          ..write(text.substring(0, text.length - 1))
          ..write(line);
      } else {
        buffer.write(' $line');
      }
    }
    return buffer.toString().replaceAll(_spaces, ' ').trim();
  }
}
