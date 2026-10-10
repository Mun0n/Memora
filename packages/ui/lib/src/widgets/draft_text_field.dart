import 'package:flutter/material.dart';

/// Text field that reseeds only when [revision] changes (avoids rebuild loops).
class DraftTextField extends StatefulWidget {
  const DraftTextField({
    super.key,
    required this.revision,
    required this.initialText,
    required this.onChanged,
    required this.labelText,
  });

  final Object revision;
  final String initialText;
  final ValueChanged<String> onChanged;
  final String labelText;

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
      onChanged: widget.onChanged,
    );
  }
}
