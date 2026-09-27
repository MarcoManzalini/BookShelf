import 'package:flutter/material.dart';

import '../utils/l10n_extension.dart';

/// Asks for one value in a dialog and returns it parsed by [parse], or null
/// when cancelled.
///
/// The dialog owns its text controller: disposing one right after
/// `showDialog` returns breaks the field, which is still on screen while the
/// dialog animates out.
Future<T?> showTextInputDialog<T>(
  BuildContext context, {
  required String title,
  required T? Function(String text) parse,
  String initialText = '',
  String? labelText,
  String? hintText,
  String? suffixText,
  TextInputType? keyboardType,
  TextCapitalization textCapitalization = TextCapitalization.none,
  String? Function(String text)? validator,
}) {
  return showDialog<T>(
    context: context,
    builder: (_) => _TextInputDialog<T>(
      title: title,
      parse: parse,
      initialText: initialText,
      labelText: labelText,
      hintText: hintText,
      suffixText: suffixText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
    ),
  );
}

class _TextInputDialog<T> extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.parse,
    required this.initialText,
    required this.labelText,
    required this.hintText,
    required this.suffixText,
    required this.keyboardType,
    required this.textCapitalization,
    required this.validator,
  });

  final String title;
  final T? Function(String text) parse;
  final String initialText;
  final String? labelText;
  final String? hintText;
  final String? suffixText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String text)? validator;

  @override
  State<_TextInputDialog<T>> createState() => _TextInputDialogState<T>();
}

class _TextInputDialogState<T> extends State<_TextInputDialog<T>> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, widget.parse(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final validator = widget.validator;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: widget.keyboardType,
          textCapitalization: widget.textCapitalization,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            suffixText: widget.suffixText,
          ),
          validator:
              validator == null ? null : (value) => validator(value ?? ''),
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
