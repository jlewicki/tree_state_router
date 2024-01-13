import 'package:flutter/material.dart';

class AuthFormFieldGroup extends StatelessWidget {
  const AuthFormFieldGroup({
    Key? key,
    required this.formFields,
    this.title = '',
  }) : super(key: key);

  final String title;
  final List<AuthFormField> formFields;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.only(bottom: 24),
            alignment: Alignment.center,
            child: Text(
              title,
              style: const TextStyle(fontSize: 28),
            ),
          ),
          for (var field in formFields)
            Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              constraints: const BoxConstraints(maxWidth: 250),
              child: TextFormField(
                enabled: field.isEnabled,
                initialValue: field.initialValue,
                validator: field.validator,
                autofocus: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: field.label,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AuthFormField {
  final String key;
  final String label;
  final String initialValue;
  final bool isRequired;
  final bool isEnabled;
  final FormFieldValidator<String>? validator;
  const AuthFormField(
    this.key,
    this.label,
    this.initialValue, {
    this.isRequired = true,
    this.validator,
    this.isEnabled = true,
  });
}
