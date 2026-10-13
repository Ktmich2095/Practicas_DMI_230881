import 'package:flutter/material.dart';

/// Only the expanded text panel claims scroll gestures; the rest is the feed.
class ExpandableCaption extends StatefulWidget {
  final String text;
  final double maxHeight;
  const ExpandableCaption({
    super.key,
    required this.text,
    required this.maxHeight,
  });
  @override
  State<ExpandableCaption> createState() => _ExpandableCaptionState();
}

class _ExpandableCaptionState extends State<ExpandableCaption> {
  bool expanded = false;
  @override
  void didUpdateWidget(ExpandableCaption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) expanded = false;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const style = TextStyle(fontSize: 14, height: 1.5);
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: style),
        maxLines: 2,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.maxWidth);
      final overflow = painter.didExceedMaxLines;
      painter.dispose();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (expanded)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: widget.maxHeight),
              child: SingleChildScrollView(
                key: const ValueKey('expanded-description'),
                child: Text(widget.text, style: style),
              ),
            )
          else
            Text(
              widget.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          if (overflow)
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                minimumSize: const Size(48, 36),
              ),
              onPressed: () => setState(() => expanded = !expanded),
              child: Text(expanded ? 'Ver menos' : 'Ver más'),
            ),
        ],
      );
    },
  );
}
