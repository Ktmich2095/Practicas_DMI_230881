import 'package:flutter/material.dart';

import '../../../domain/entities/season.dart';
import '../../providers/playback_coordinator.dart';
import '../../providers/intro_audio_provider.dart';
import '../../widgets/branding/season_intro.dart';

class IntroPreviewScreen extends StatefulWidget {
  final Season season;
  const IntroPreviewScreen({super.key, required this.season});

  /// Pause first, stop intro sound before restoring video, including back gestures.
  static Future<void> open(
    BuildContext context,
    Season season,
    PlaybackCoordinator? playback,
    IntroAudioProvider? audio,
  ) async {
    await playback?.setIntroActive(true);
    await audio?.start(season);
    if (!context.mounted) {
      await audio?.stop();
      await playback?.setIntroActive(false);
      return;
    }
    try {
      await Navigator.of(context).push<void>(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => IntroPreviewScreen(season: season),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } finally {
      await audio?.stop();
      await playback?.setIntroActive(false);
    }
  }

  @override
  State<IntroPreviewScreen> createState() => _IntroPreviewScreenState();
}

class _IntroPreviewScreenState extends State<IntroPreviewScreen> {
  bool closing = false;
  void close() {
    if (!closing && mounted && ModalRoute.of(context)?.isCurrent == true) {
      closing = true;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SeasonIntro(
      season: widget.season,
      onComplete: () {
        close();
      },
      footer: TextButton(
        onPressed: close,
        child: const Text('Cerrar vista previa'),
      ),
    ),
  );
}
