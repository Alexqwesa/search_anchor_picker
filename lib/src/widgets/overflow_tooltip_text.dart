import 'package:flutter/material.dart';
import 'package:generic_search_selector/src/widgets/passive_tooltip.dart';

/// Text that shows a tooltip only when it is ellipsized.
class OverflowTooltipText extends StatelessWidget {
  const OverflowTooltipText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.textAlign,
    this.tooltip,
  });

  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign? textAlign;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(
          text: text,
          style: style ?? DefaultTextStyle.of(context).style,
        );
        final painter = TextPainter(
          text: span,
          maxLines: maxLines,
          textDirection: Directionality.of(context),
          textAlign: textAlign ?? TextAlign.start,
          ellipsis: '...',
        )..layout(maxWidth: constraints.maxWidth);
        final child = Text(
          text,
          style: style,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
        );
        if (!painter.didExceedMaxLines) return child;
        return PassiveTooltip(message: tooltip ?? text, child: child);
      },
    );
  }
}
