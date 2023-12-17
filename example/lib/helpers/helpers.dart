import 'package:flutter/material.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'edit_text.dart';

Widget defaultScaffolding(PageBuildFor buildFor, Widget pageContent) {
  return switch (buildFor) {
    // Don't wrap popup routes in a Scaffold, since that expands to fit the entire page, which
    // obscures the popup dialog shim
    BuildForRoute(isPopup: true) => Center(
        child: Card(
          child: pageContent,
        ),
      ),
    _ => Scaffold(
        body: StateTreeInspector(
          child: Center(
            child: pageContent,
          ),
        ),
      )
  };
}

Widget editText(
  String initialValue,
  String hint,
  void Function(String) onChanged,
) {
  return Container(
    constraints: const BoxConstraints(maxWidth: 300),
    child: EditText(
      initialValue: initialValue,
      hint: hint,
      onChanged: onChanged,
    ),
  );
}

Widget button(String text, void Function() onPressed) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    ),
  );
}
