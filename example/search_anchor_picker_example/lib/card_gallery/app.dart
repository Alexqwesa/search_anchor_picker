import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'examples.dart';

const galleryCardMaxWidth = 600.0;

class CardsGalleryApp extends StatelessWidget {
  const CardsGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Picker scenario cards',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const CardsGalleryPage(),
    );
  }
}

class CardsGalleryPage extends StatefulWidget {
  const CardsGalleryPage({super.key});

  @override
  State<CardsGalleryPage> createState() => _CardsGalleryPageState();
}

class _CardsGalleryPageState extends State<CardsGalleryPage> {
  late final List<Widget> _cards = galleryCards();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Picker scenario cards')),
      body: SelectionArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const padding = 16.0;
            const spacing = 16.0;
            final available = math.max(0.0, constraints.maxWidth - padding * 2);
            final cardWidth = math.min(galleryCardMaxWidth, available);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Each card is one way to use SearchAnchorPicker. The field holds selected people as chips; + add opens the popup. Use the code icon for that card’s source.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final card in _cards)
                        SizedBox(width: cardWidth, child: card),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
