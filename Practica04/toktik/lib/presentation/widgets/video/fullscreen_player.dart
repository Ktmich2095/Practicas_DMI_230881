import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../domain/entities/video_post.dart';
import '../../providers/playback_coordinator.dart';
import '../../shared/video_buttons.dart';
import 'expandable_caption.dart';

class FullscreenPlayer extends StatefulWidget {
  final VideoPost video;
  final PlaybackCoordinator playback;
  const FullscreenPlayer({
    super.key,
    required this.video,
    required this.playback,
  });
  @override
  State<FullscreenPlayer> createState() => _FullscreenPlayerState();
}

class _FullscreenPlayerState extends State<FullscreenPlayer> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compact = MediaQuery.orientationOf(context) == Orientation.landscape;
    final c = widget.playback.controllers[widget.video.id];
    final failed = widget.playback.errors.contains(widget.video.id);
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF11151D)),
        if (failed)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off_outlined, size: 48),
                const SizedBox(height: 12),
                const Text('No se pudo reproducir este video'),
                TextButton(
                  onPressed: widget.playback.retry,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          )
        else if (c == null || !c.value.isInitialized)
          Center(child: CircularProgressIndicator(color: colors.primary))
        else
          ValueListenableBuilder(
            valueListenable: c,
            builder: (context, value, _) => Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: widget.playback.togglePause,
                  child: ClipRect(
                    child: SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: value.size.width,
                          height: value.size.height,
                          child: VideoPlayer(c),
                        ),
                      ),
                    ),
                  ),
                ),
                if (value.hasError)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Error de reproducción'),
                        TextButton(
                          onPressed: widget.playback.retry,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                if (value.isBuffering)
                  const Center(child: CircularProgressIndicator()),
                if (widget.playback.paused)
                  const IgnorePointer(
                    child: Center(
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 80,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoProgressIndicator(
                    c,
                    allowScrubbing: false,
                    colors: VideoProgressColors(
                      playedColor: colors.primary,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black54,
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black87,
                ],
                stops: [0, .25, .5, 1],
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: compact ? 24 : 100,
          child: VideoButtons(video: widget.video, playback: widget.playback),
        ),
        Positioned(
          left: 20,
          right: compact ? 280 : 88,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '@${widget.video.creator}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              ExpandableCaption(
                text: widget.video.caption,
                maxHeight: MediaQuery.sizeOf(context).height * .22,
              ),
              Text(
                widget.video.source,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (widget.video.license != null)
                Text(
                  widget.video.license!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.white54),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
