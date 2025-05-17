import 'package:flutter/material.dart';

class ScrollablePage extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ScrollablePage({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: padding, child: child);
  }
}
