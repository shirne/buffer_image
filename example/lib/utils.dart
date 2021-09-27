import 'package:flutter/material.dart';

Future<bool?> alert<bool>(BuildContext context, String message,
    {String? title, List<Widget>? actions}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 200, horizontal: 50),
          child: AlertDialog(
              title: title == null ? null : Text(title),
              content: Column(
                children: message
                    .split(RegExp("[\r\n]+"))
                    .map<Widget>((row) => Text(row))
                    .toList(),
              ),
              actions: actions ??
                  [
                    TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.pop(context, true);
                        })
                  ]),
        ),
      );
    },
  );
}
