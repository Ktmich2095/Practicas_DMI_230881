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
    final compact = MediaQuery.orientationOf(context) == Orientation.landscape;
    final buttons = <Widget>[
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
      Tooltip(
        message:
            '${provider.likes(video)} likes${provider.statistics(video).simulatedLikes ? ' · demostración' : ''}',
        child: Text(
          HumanFormats.humanReadableNumber(provider.likes(video).toDouble()),
        ),
      ),
      SizedBox(height: compact ? 0 : 22, width: compact ? 12 : 0),
      IconButton(
        tooltip: playback.muted ? 'Activar sonido' : 'Silenciar',
        onPressed: playback.toggleSound,
        icon: Icon(
          playback.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          size: 30,
        ),
      ),
      SizedBox(height: compact ? 0 : 18, width: compact ? 12 : 0),
      const Icon(Icons.visibility_outlined, size: 26),
      SizedBox(height: compact ? 0 : 6, width: compact ? 6 : 0),
      Tooltip(
        message:
            '${provider.views(video)} vistas${provider.statistics(video).simulatedViews ? ' · demostración' : ''}',
        child: Text(
          HumanFormats.humanReadableNumber(provider.views(video).toDouble()),
        ),
      ),
    ];
    return compact
        ? Row(mainAxisSize: MainAxisSize.min, children: buttons)
        : Column(mainAxisSize: MainAxisSize.min, children: buttons);
  }
}
