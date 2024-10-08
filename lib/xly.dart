library xly;

import 'package:flutter/material.dart';

/// A test widget for the xly package.
class TestWidget extends StatelessWidget {
  const TestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      child: const Center(
        child: Text('This is a test widget from xly package'),
      ),
    );
  }
}