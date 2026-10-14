import 'package:flutter/material.dart';

/// Text field that reseeds only when [revision] changes (avoids rebuild loops).
class DraftTextField extends StatefulWidget {
  const DraftTextField({
    super.key,
    required this.revision,
    required this.initialText,
    required this.onChanged,
    required this.labelText,
    this.maxLines = 1,
    this.readOnly = false,
  });

  final Object revision;
  final String initialText;
  final ValueChanged<String> onChanged;
  final String labelText;
  final int? maxLines;
  final bool readOnly;

  @override
  State<DraftTextField> createState() => _DraftTextFieldState();
}

class _DraftTextFieldState extends State<DraftTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(covariant DraftTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) {
      _controller.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(labelText: widget.labelText),
      onChanged: widget.readOnly ? null : widget.onChanged,
      maxLines: widget.maxLines,
      readOnly: widget.readOnly,
      enableInteractiveSelection: !widget.readOnly,
    );
  }
}
