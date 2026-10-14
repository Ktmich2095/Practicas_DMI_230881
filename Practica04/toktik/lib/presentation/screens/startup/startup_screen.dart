import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/startup_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/intro_audio_provider.dart';
import '../../widgets/branding/season_intro.dart';
import '../discover/discover_screen.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});
  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  IntroAudioProvider? _audio;
  bool introDone = false,
      soundStarted = false,
      soundStopped = false,
      enterAllowed = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<StartupProvider>().initialize();
    });
  }

  void finishIntro() {
    if (!mounted) return;
    setState(() => introDone = true);
  }

  @override
  void dispose() {
    unawaited(_audio?.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startup = context.watch<StartupProvider>();
    final season = context.watch<SettingsProvider>().season;
    final audio = context.read<IntroAudioProvider>();
    _audio = audio;
    if (startup.settingsReady && !soundStarted) {
      soundStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(audio.startWelcome(season));
      });
    }
    if (startup.ready && introDone && !soundStopped) {
      soundStopped = true;
      Future.microtask(() async {
        await audio.stop();
        if (mounted) setState(() => enterAllowed = true);
      });
    }
    final enter = enterAllowed;
    return Material(
      color: Colors.black,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        child: enter
            ? const DiscoverScreen(key: ValueKey('feed-ready'))
            : !startup.settingsReady
            ? const ColoredBox(
                key: ValueKey('preferences-loading'),
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF5DE2D2),
                  ),
                ),
              )
            : SeasonIntro(
                key: const ValueKey('startup-intro'),
                season: season,
                onComplete: finishIntro,
                footer: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (startup.loading) ...[
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        startup.status,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    if (startup.error.isNotEmpty) ...[
                      Text(startup.error, textAlign: TextAlign.center),
                      TextButton(
                        onPressed: startup.initialize,
                        child: const Text('Reintentar'),
                      ),
                      TextButton(
                        onPressed: startup.continueToFeed,
                        child: const Text('Entrar al feed'),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
