import 'package:flutter/material.dart';

import '../../core/l10n/app_l10n.dart';

/// Asks for a short note. Returns the trimmed text, an empty string when an
/// optional note is left blank, or null when cancelled.
Future<String?> showNoteDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
  String? body,
  int maxLength = 300,
  int minLength = 0,
}) => showDialog<String>(
  context: context,
  builder: (_) => _NoteDialog(
    title: title,
    label: label,
    confirmLabel: confirmLabel,
    body: body,
    maxLength: maxLength,
    minLength: minLength,
  ),
);

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    required this.body,
    required this.maxLength,
    required this.minLength,
  });

  final String title;
  final String label;
  final String confirmLabel;
  final String? body;
  final int maxLength;
  final int minLength;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  // Owned by the dialog so it outlives the closing animation.
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.body != null) Text(widget.body!),
        TextField(
          controller: _controller,
          maxLength: widget.maxLength,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(labelText: widget.label),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: () {
          final text = _controller.text.trim();
          if (text.length >= widget.minLength) Navigator.pop(context, text);
        },
        child: Text(widget.confirmLabel),
      ),
    ],
  );
}
