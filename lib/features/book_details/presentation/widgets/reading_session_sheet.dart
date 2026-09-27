import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/utils/minutes_text.dart';
import '../../../library/domain/entities/user_book.dart';

/// What the reader reports at the end of a session. For an audiobook
/// [endPage] is the minute reached.
typedef ReadingSession = ({int endPage, int? minutes});

/// Bottom sheet with a stopwatch, the minutes and the page reached.
Future<ReadingSession?> showReadingSessionSheet(
  BuildContext context,
  UserBook userBook,
) {
  return showModalBottomSheet<ReadingSession>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _SessionSheet(userBook: userBook),
  );
}

class _SessionSheet extends StatefulWidget {
  const _SessionSheet({required this.userBook});

  final UserBook userBook;

  @override
  State<_SessionSheet> createState() => _SessionSheetState();
}

class _SessionSheetState extends State<_SessionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _audio = widget.userBook.isAudio;
  late final _page = TextEditingController(
    text: _audio
        ? MinutesText.edit(widget.userBook.currentPage)
        : '${widget.userBook.currentPage}',
  );

  int? _readEnd(String? value) => _audio
      ? MinutesText.parse(value ?? '')
      : int.tryParse(value?.trim() ?? '');
  final _minutes = TextEditingController();
  final _watch = Stopwatch();
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    _page.dispose();
    _minutes.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      if (_watch.isRunning) {
        _watch.stop();
        _ticker?.cancel();
        // Round up: a 20 s glance still counts as a minute of reading.
        final minutes = (_watch.elapsed.inSeconds / 60).ceil();
        if (minutes > 0) _minutes.text = '$minutes';
      } else {
        _watch.start();
        _ticker = Timer.periodic(
          const Duration(seconds: 1),
          (_) => setState(() {}),
        );
      }
    });
  }

  String get _elapsed {
    final t = _watch.elapsed;
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = t.inHours;
    final mm = two(t.inMinutes.remainder(60));
    final ss = two(t.inSeconds.remainder(60));
    return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final minutes = int.tryParse(_minutes.text.trim());
    Navigator.pop(
      context,
      (
        endPage: _readEnd(_page.text)!,
        minutes: (minutes != null && minutes > 0) ? minutes : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final total = widget.userBook.progressTotal;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.sessionTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _elapsed,
                        style: AppFonts.text(
                          size: 40,
                          weight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _toggle,
                      icon: Icon(
                        _watch.isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(
                        _watch.isRunning
                            ? l10n.sessionPause
                            : l10n.sessionStart,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minutes,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.sessionMinutes),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return null;
                    final n = int.tryParse(text);
                    return (n == null || n < 1 || n > 1440)
                        ? l10n.validationPageInvalid
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _page,
                  keyboardType: _audio
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.number,
                  decoration: InputDecoration(
                    labelText:
                        _audio ? l10n.positionReached : l10n.sessionEndPage,
                    hintText: _audio ? l10n.durationHint : null,
                    suffixText: total == null
                        ? null
                        : '/ ${_audio ? MinutesText.edit(total) : total}',
                  ),
                  validator: (value) {
                    final n = _readEnd(value);
                    if (n == null || n < 0) {
                      return _audio
                          ? l10n.durationInvalid
                          : l10n.validationPageInvalid;
                    }
                    if (total != null && n > total) {
                      return _audio
                          ? l10n.positionInvalid
                          : l10n.validationPageInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: _save, child: Text(l10n.save)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
