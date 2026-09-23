import 'package:flutter/material.dart';
import 'package:search_anchor_picker/search_anchor_picker.dart';

void main() => runApp(const ExampleApp());

/// Minimal SearchAnchorPicker usage for pub.dev.
class ExampleApp extends StatefulWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final _selected = <int>{};
  final _config = PickerConfig<int>(
    itemsLoader: (_, _) async => [1, 2, 3],
    idOf: (id) => id,
    labelOf: (id) => 'Item $id',
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SearchAnchorPicker<int>(
            config: _config,
            initialSelectedIds: _selected.toList(),
            onClose: (result) {
              setState(() {
                _selected
                  ..addAll(result.added)
                  ..removeAll(result.removed);
              });
            },
          ),
        ),
      ),
    );
  }
}
