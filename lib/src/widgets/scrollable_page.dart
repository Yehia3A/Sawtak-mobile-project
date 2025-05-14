import 'package:flutter/material.dart';

class ScrollablePage extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ScrollablePage({Key? key, required this.child, this.padding})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: padding, child: child);
  }
}
