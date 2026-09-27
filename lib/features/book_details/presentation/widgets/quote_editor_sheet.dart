import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../../quotes/data/text_recognizer.dart';
import '../../../quotes/domain/entities/book_quote.dart';

typedef QuoteDraft = ({String text, int? page});

/// Writes a new quote or edits [initial]. The text can be typed, or read
/// from a photo of the page and then trimmed.
Future<QuoteDraft?> showQuoteEditorSheet(
  BuildContext context, {
  BookQuote? initial,
  TextRecognizer recognizer = const TextRecognizer(),
}) {
  return showModalBottomSheet<QuoteDraft>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _QuoteEditor(initial: initial, recognizer: recognizer),
  );
}

class _QuoteEditor extends StatefulWidget {
  const _QuoteEditor({required this.initial, required this.recognizer});

  final BookQuote? initial;
  final TextRecognizer recognizer;

  @override
  State<_QuoteEditor> createState() => _QuoteEditorState();
}

class _QuoteEditorState extends State<_QuoteEditor> {
  late final _text = TextEditingController(text: widget.initial?.text);
  late final _page =
      TextEditingController(text: widget.initial?.page?.toString() ?? '');
  bool _scanning = false;

  /// Shown under the buttons after a scan: guidance or what went wrong.
  String? _scanMessage;
  bool _scanFailed = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _page.dispose();
    super.dispose();
  }

  Future<void> _scan(ImageSource source) async {
    final l10n = context.l10n;
    final XFile? photo;
    try {
      // Large enough for small print to stay readable.
      photo = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 90,
      );
    } catch (_) {
      // Permission denied or picker unavailable.
      if (mounted) _showScanResult(l10n.quoteScanError, failed: true);
      return;
    }
    if (photo == null || !mounted) return;
    setState(() {
      _scanning = true;
      _scanMessage = null;
    });
    try {
      final text = await widget.recognizer.recognize(photo.path);
      if (!mounted) return;
      if (text.isEmpty) {
        _showScanResult(l10n.quoteScanEmpty, failed: true);
        return;
      }
      _text.text = text.length > BookQuote.maxLength
          ? text.substring(0, BookQuote.maxLength)
          : text;
      _showScanResult(l10n.quoteScanHint, failed: false);
    } catch (_) {
      if (mounted) _showScanResult(l10n.quoteScanError, failed: true);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _showScanResult(String message, {required bool failed}) {
    setState(() {
      _scanMessage = message;
      _scanFailed = failed;
    });
  }

  void _save() {
    final page = int.tryParse(_page.text.trim());
    Navigator.pop<QuoteDraft>(
      context,
      (text: _text.text.trim(), page: page != null && page > 0 ? page : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.initial == null ? l10n.quoteAdd : l10n.quoteEdit,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _scanning ? null : () => _scan(ImageSource.camera),
                    icon: const Icon(Icons.document_scanner_outlined, size: 18),
                    label: Text(l10n.quoteScanCamera),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _scanning ? null : () => _scan(ImageSource.gallery),
                    icon: const Icon(Icons.photo_outlined, size: 18),
                    label: Text(l10n.quoteScanGallery),
                  ),
                ),
              ],
            ),
            if (_scanning) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.quoteScanning, style: theme.textTheme.bodySmall),
                ],
              ),
            ] else if (_scanMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _scanMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _scanFailed
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              autofocus: widget.initial == null,
              minLines: 3,
              maxLines: 10,
              maxLength: BookQuote.maxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.quoteText,
                hintText: l10n.quoteTextHint,
                prefixIcon: const Icon(Icons.format_quote_rounded),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _page,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: l10n.quotePage,
                prefixIcon: const Icon(Icons.bookmark_border_rounded),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _text.text.trim().isEmpty || _scanning ? null : _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
