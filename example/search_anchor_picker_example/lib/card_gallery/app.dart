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
  late final List<GallerySection> _sections = gallerySections();

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
            final theme = Theme.of(context);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Each card is one way to use SearchAnchorPicker. The field holds selected people as chips; + add opens the popup. Use the code icon for that card’s source.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  for (final section in _sections) ...[
                    const SizedBox(height: 28),
                    Text(section.title, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(section.caption, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final card in section.cards) SizedBox(width: cardWidth, child: card),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
