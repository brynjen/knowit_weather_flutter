import 'package:flutter/material.dart';

class BasicDialog extends StatelessWidget {
  BasicDialog({required this.texts, required this.okButton, required this.onConfirm});
  final List<String> texts;
  final String okButton;
  final Function onConfirm;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final text in texts) {
      children.add(Text(text));
    }
    children.add(const SizedBox(height: 20));
    children.add(Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Avbryt', style: Theme.of(context).textTheme.button),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop();
          },
          child: Text(okButton, style: Theme.of(context).textTheme.button),
        ),
      ],
    ));
    return Dialog(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}
