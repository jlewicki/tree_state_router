import 'package:flutter/material.dart';

class EditText extends StatefulWidget {
  const EditText({
    super.key,
    this.initialValue,
    this.hint,
    required this.onChanged,
  });

  final String? initialValue;
  final String? hint;
  final void Function(String value) onChanged;

  @override
  State<EditText> createState() => _EditTextState();
}

class _EditTextState extends State<EditText> {
  final _controller = TextEditingController();

  @override
  void initState() {
    _controller.text = widget.initialValue ?? '';
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: TextField(
        controller: _controller,
        onChanged: (val) => widget.onChanged(val),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: widget.hint ?? '',
        ),
      ),
    );
  }
}
