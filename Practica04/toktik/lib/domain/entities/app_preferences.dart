import 'season.dart';
import 'video_source.dart';

class AppPreferences {
  final VideoSource source;
  final Season? manualSeason;
  final bool muted, themeAudio, introSound;
  const AppPreferences({
    this.source = VideoSource.random,
    this.manualSeason,
    this.muted = true,
    this.themeAudio = false,
    this.introSound = true,
  });
  AppPreferences copyWith({
    VideoSource? source,
    Season? manualSeason,
    bool automaticSeason = false,
    bool? muted,
    bool? themeAudio,
    bool? introSound,
  }) => AppPreferences(
    source: source ?? this.source,
    manualSeason: automaticSeason ? null : manualSeason ?? this.manualSeason,
    muted: muted ?? this.muted,
    themeAudio: themeAudio ?? this.themeAudio,
    introSound: introSound ?? this.introSound,
  );
}
