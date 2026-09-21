import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';

import '../config/app_config.dart';
import 'cover_url.dart';

/// The color a cover is remembered by: its most vivid dominant hue, nudged
/// into a mid-lightness range so it reads on both light and dark pages.
///
/// [rgba] is raw RGBA pixel data (a small thumbnail is plenty). Vivid pixels
/// vote for a hue, weighted by saturation and brightness, so a yellow cover
/// with a bit of black lettering comes out yellow, not brown. A cover with no
/// vivid pixels (black-and-white artwork) gets a neutral grey. Null when the
/// image has no opaque pixels.
Color? dominantCoverColor(Uint8List rgba) {
  const bins = 12;
  final weight = List<double>.filled(bins, 0);
  final reds = List<double>.filled(bins, 0);
  final greens = List<double>.filled(bins, 0);
  final blues = List<double>.filled(bins, 0);
  var pixels = 0;
  var allR = 0.0, allG = 0.0, allB = 0.0;

  for (var i = 0; i + 3 < rgba.length; i += 4) {
    if (rgba[i + 3] < 128) continue;
    final r = rgba[i], g = rgba[i + 1], b = rgba[i + 2];
    pixels++;
    allR += r;
    allG += g;
    allB += b;
    final hsv = HSVColor.fromColor(ui.Color.fromARGB(255, r, g, b));
    // Near-grey and near-black pixels carry no hue worth showing.
    if (hsv.saturation < 0.25 || hsv.value < 0.2) continue;
    final w = hsv.saturation * hsv.value;
    final bin = (hsv.hue / (360 / bins)).floor() % bins;
    weight[bin] += w;
    reds[bin] += r * w;
    greens[bin] += g * w;
    blues[bin] += b * w;
  }
  if (pixels == 0) return null;

  var best = 0;
  for (var i = 1; i < bins; i++) {
    if (weight[i] > weight[best]) best = i;
  }
  final vivid = weight[best] >= pixels * 0.03;
  final color = vivid
      ? ui.Color.fromARGB(
          255,
          (reds[best] / weight[best]).round(),
          (greens[best] / weight[best]).round(),
          (blues[best] / weight[best]).round(),
        )
      : ui.Color.fromARGB(
          255,
          (allR / pixels).round(),
          (allG / pixels).round(),
          (allB / pixels).round(),
        );
  return _legible(color, vivid: vivid);
}

Color _legible(Color color, {required bool vivid}) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withSaturation(vivid ? hsl.saturation.clamp(0.5, 0.9) : 0)
      .withLightness(hsl.lightness.clamp(0.42, 0.62))
      .toColor();
}

/// Loads [url] (a cover) and returns its [dominantCoverColor]; null when the
/// image cannot be read. Results are kept for the session.
Future<Color?> coverColor(String url) =>
    _colors.putIfAbsent(url, () => _load(url));

final _colors = <String, Future<Color?>>{};

Future<Color?> _load(String url) async {
  try {
    // Same URL the covers are shown with, so the file is already on disk.
    final provider = ResizeImage(
      CachedNetworkImageProvider(
        resizeCoverUrl(url, CoverSize.large),
        headers: const {'User-Agent': AppConfig.userAgent},
      ),
      width: 48,
    );
    final completed = Completer<ui.Image>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completed.isCompleted) completed.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (error, stack) {
        if (!completed.isCompleted) completed.completeError(error, stack);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    final image = await completed.future.timeout(const Duration(seconds: 15));
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    return dominantCoverColor(data.buffer.asUint8List());
  } catch (_) {
    // A missing cover or a failed download just means the default color.
    unawaited(_colors.remove(url));
    return null;
  }
}
