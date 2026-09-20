import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../bloc/book_details_bloc.dart';

/// Saves when the field loses focus (including when the page is popped).
class NotesField extends StatefulWidget {
  const NotesField({super.key, required this.initialNotes});

  final String? initialNotes;

  @override
  State<NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<NotesField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialNotes);
  final _focusNode = FocusNode();
  late String _saved = widget.initialNotes?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) return;
    final text = _controller.text.trim();
    if (text == _saved) return;
    _saved = text;
    context.read<BookDetailsBloc>().add(BookDetailsNotesChanged(text));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      minLines: 3,
      maxLines: 8,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(hintText: context.l10n.notesHint),
    );
  }
}
