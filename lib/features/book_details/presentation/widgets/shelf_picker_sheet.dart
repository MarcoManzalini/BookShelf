import 'package:flutter/material.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../../library/domain/entities/shelf_names.dart';
import '../../../library/presentation/widgets/shelf_color.dart';

/// Bottom sheet to put a book on shelves: tick existing ones or create a new
/// one. Returns the chosen shelves, or null when dismissed.
Future<List<String>?> showShelfPickerSheet(
  BuildContext context, {
  required List<String> current,
  required Iterable<String> available,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ShelfPicker(current: current, available: available),
  );
}

class _ShelfPicker extends StatefulWidget {
  const _ShelfPicker({required this.current, required this.available});

  final List<String> current;
  final Iterable<String> available;

  @override
  State<_ShelfPicker> createState() => _ShelfPickerState();
}

class _ShelfPickerState extends State<_ShelfPicker> {
  late final List<String> _all;
  late final Set<String> _selected;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _all = ShelfNames.clean([...widget.available, ...widget.current]);
    _selected = {for (final s in widget.current) s.toLowerCase()};
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _has(String name) => _selected.contains(name.toLowerCase());

  void _toggle(String name) => setState(() {
        final key = name.toLowerCase();
        if (!_selected.remove(key)) _selected.add(key);
      });

  void _create() {
    final name = ShelfNames.normalize(_controller.text);
    if (name == null) return;
    setState(() {
      // Typing an existing name (any case) selects it instead of duplicating.
      final existing = _all.where((s) => ShelfNames.same(s, name));
      if (existing.isEmpty) _all.add(name);
      _selected.add(name.toLowerCase());
      _controller.clear();
    });
  }

  void _done() {
    final chosen = _all.where(_has).toList();
    Navigator.pop(context, chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final atLimit = _selected.length >= ShelfNames.maxPerBook;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.shelvesTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(72, 40),
                      ),
                      onPressed: _done,
                      child: Text(l10n.save),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  maxLength: ShelfNames.maxLength,
                  onSubmitted: (_) => _create(),
                  decoration: InputDecoration(
                    hintText: l10n.newShelfHint,
                    counterText: '',
                    suffixIcon: IconButton(
                      tooltip: l10n.addShelf,
                      icon: const Icon(Icons.add_rounded),
                      onPressed: _create,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final name in _all)
                      CheckboxListTile(
                        value: _has(name),
                        onChanged: (_has(name) || !atLimit)
                            ? (_) => _toggle(name)
                            : null,
                        secondary: CircleAvatar(
                          radius: 8,
                          backgroundColor: shelfColor(name),
                        ),
                        title: Text(name),
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
