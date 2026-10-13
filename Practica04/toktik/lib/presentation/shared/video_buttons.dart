import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/helpers/human_formats.dart';
import '../../domain/entities/video_post.dart';
import '../providers/discover_provider.dart';
import '../providers/playback_coordinator.dart';
import '../providers/settings_provider.dart';
import '../../config/theme/season_style.dart';

class VideoButtons extends StatelessWidget {
  final VideoPost video;
  final PlaybackCoordinator playback;
  const VideoButtons({super.key, required this.video, required this.playback});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiscoverProvider>();
    final favorite = provider.isFavorite(video);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: favorite ? 'Quitar de favoritos' : 'Guardar en favoritos',
          onPressed: provider.saving
              ? null
              : () => provider.toggleFavorite(video),
          icon: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : SeasonStyle.of(context.watch<SettingsProvider>().season)
                      .animationDuration,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              favorite ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(favorite),
              size: 36,
              color: favorite
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.white,
            ),
          ),
        ),
        Text(
          HumanFormats.humanReadableNumber(provider.likes(video).toDouble()),
        ),
        const SizedBox(height: 22),
        IconButton(
          tooltip: playback.muted ? 'Activar sonido' : 'Silenciar',
          onPressed: playback.toggleSound,
          icon: Icon(
            playback.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            size: 30,
          ),
        ),
        const SizedBox(height: 18),
        const Icon(Icons.visibility_outlined, size: 26),
        const SizedBox(height: 6),
        Text(HumanFormats.humanReadableNumber(video.views.toDouble())),
      ],
    );
  }
}
