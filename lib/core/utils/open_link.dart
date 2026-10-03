import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n_extension.dart';

/// Opens [uri] in the browser; tells the reader when that is not possible.
/// Returns whether it opened.
Future<bool> openExternalLink(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = context.l10n.linkOpenFailed;
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!opened) messenger.showSnackBar(SnackBar(content: Text(failed)));
  return opened;
}
