import 'package:flutter/material.dart';

/// Remote photo with bundled placeholder, visible progress and retry.
class RemoteImage extends StatefulWidget {
  final String url;
  final double height;
  const RemoteImage({super.key, required this.url, this.height = 300});
  @override
  State<RemoteImage> createState() => _RemoteImageState();
}

class _RemoteImageState extends State<RemoteImage> {
  int attempt = 0;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    width: double.infinity,
    child: Stack(
      fit: StackFit.expand,
      children: [
        FadeInImage(
          key: ValueKey('${widget.url}-$attempt'),
          placeholder: const AssetImage('assets/images/jar-loading.gif'),
          image: NetworkImage(widget.url),
          fit: BoxFit.cover,
          placeholderFit: BoxFit.contain,
          imageErrorBuilder: (context, error, stack) => ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.broken_image_outlined),
                  const Text('No se pudo cargar la imagen'),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    onPressed: () async {
                      await NetworkImage(widget.url).evict();
                      if (mounted) setState(() => attempt++);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
