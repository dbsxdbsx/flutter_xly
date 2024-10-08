import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XLY Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('XLY Example'),
        ),
        body: const Center(
          child: TestWidget(),
        ),
      ),
    );
  }
}