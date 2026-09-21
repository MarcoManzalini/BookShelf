import 'dart:typed_data';

import 'package:bookshelf/core/utils/cover_color.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _join(List<Uint8List> parts) =>
    Uint8List.fromList([for (final p in parts) ...p]);

Uint8List _pixels(List<(int, int, int, int)> colors, {int each = 1}) {
  final bytes = <int>[];
  for (final (r, g, b, a) in colors) {
    for (var i = 0; i < each; i++) {
      bytes.addAll([r, g, b, a]);
    }
  }
  return Uint8List.fromList(bytes);
}

void main() {
  double hue(Color c) => HSLColor.fromColor(c).hue;

  test('a mostly yellow cover with black lettering comes out yellow', () {
    final color = dominantCoverColor(
      _join([
        _pixels([(240, 220, 20, 255)], each: 80),
        _pixels([(10, 10, 10, 255)], each: 20),
      ]),
    )!;

    expect(hue(color), inInclusiveRange(45, 65));
  });

  test('the biggest vivid area wins over a small brighter accent', () {
    final color = dominantCoverColor(
      _join([
        _pixels([(20, 110, 200, 255)], each: 70),
        _pixels([(255, 40, 40, 255)], each: 10),
      ]),
    )!;

    expect(hue(color), inInclusiveRange(200, 225));
  });

  test('the result reads on light and dark pages', () {
    for (final rgb in [
      (255, 255, 120), // pale
      (10, 5, 60), // very dark
    ]) {
      final color = dominantCoverColor(
        _pixels([(rgb.$1, rgb.$2, rgb.$3, 255)], each: 50),
      )!;
      final lightness = HSLColor.fromColor(color).lightness;

      expect(lightness, inInclusiveRange(0.41, 0.63));
    }
  });

  test('black-and-white artwork gives a neutral grey', () {
    final color = dominantCoverColor(
      _pixels([(0, 0, 0, 255), (255, 255, 255, 255)], each: 50),
    )!;

    expect(HSLColor.fromColor(color).saturation, lessThan(0.05));
  });

  test('transparent or empty images give nothing', () {
    expect(dominantCoverColor(Uint8List(0)), isNull);
    expect(dominantCoverColor(_pixels([(200, 0, 0, 0)], each: 10)), isNull);
  });
}
