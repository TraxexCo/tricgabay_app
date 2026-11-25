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
  bool _touched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid => _controller.text.trim().length >= widget.minLength;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final needsText = widget.minLength > 0;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.body != null) ...[
            Text(widget.body!),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            maxLength: widget.maxLength,
            minLines: needsText ? 3 : 1,
            maxLines: 5,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() => _touched = true),
            decoration: InputDecoration(
              labelText: widget.label,
              alignLabelWithHint: true,
              helperText: needsText
                  ? l.noteMinimumValue(widget.minLength.toString())
                  : null,
              errorText: needsText && _touched && !_valid
                  ? l.noteTooShortValue(
                      (widget.minLength - _controller.text.trim().length)
                          .toString(),
                    )
                  : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          // Always tappable: a too-short note shows why instead of a
          // button that silently does nothing.
          onPressed: () {
            if (_valid) {
              Navigator.pop(context, _controller.text.trim());
            } else {
              setState(() => _touched = true);
            }
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
