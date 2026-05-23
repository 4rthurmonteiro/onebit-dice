import 'package:flutter/material.dart';

/// Root widget of the 1-Bit Dice application.
class App extends StatelessWidget {
  /// Creates the root [App] widget.
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '1-Bit Dice',
      home: Scaffold(body: Center(child: Text('1-Bit Dice'))),
    );
  }
}
