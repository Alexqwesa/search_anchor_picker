import 'package:flutter/material.dart';

import 'package:search_anchor_picker/widgets.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ReproPage());
  }
}

class ReproPage extends StatelessWidget {
  const ReproPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tooltip scroll repro')),
      body: ListView.builder(
        itemCount: 50,
        itemBuilder: (context, index) {
          final label = 'Row $index with a very long text that overflows';
          return Padding(
            padding: const EdgeInsets.all(8),
            child: PassiveTooltip(
              // enableTapToDismiss: false,
              // ignorePointer: true,
              message:
                  'Tooltip for row $index                              .\n\n\n\n\n',
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.blue.shade50,
                child: Text(label, overflow: TextOverflow.ellipsis),
              ),
            ),
          );
        },
      ),
    );
  }
}
