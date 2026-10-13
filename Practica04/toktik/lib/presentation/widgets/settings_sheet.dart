import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/video_source.dart';
import '../../domain/entities/season.dart';
import '../providers/settings_provider.dart';
import '../providers/discover_provider.dart';
import '../providers/theme_audio_provider.dart';
import '../providers/season_identity_provider.dart';
import '../providers/intro_audio_provider.dart';
import '../providers/playback_coordinator.dart';
import '../screens/startup/intro_preview_screen.dart';
import 'branding/toktik_logo.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final audio = context.watch<ThemeAudioProvider>();
    final feed = context.read<DiscoverProvider>();
    final identity = context.watch<SeasonIdentityProvider?>();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tu experiencia TokTik',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<VideoSource>(
              isExpanded: true,
              initialValue: settings.preferences.source,
              decoration: const InputDecoration(
                labelText: 'Fuente de videos',
                border: OutlineInputBorder(),
              ),
              items: VideoSource.values
                  .map(
                    (source) => DropdownMenuItem(
                      value: source,
                      child: Text(
                        source.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: settings.saving
                  ? null
                  : (source) async {
                      if (source != null &&
                          await settings.selectSource(source)) {
                        await feed.changeSource(source);
                      }
                    },
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: settings.saving
                  ? null
                  : () async {
                      if (await settings.selectSource(VideoSource.random)) {
                        await feed.changeSource(VideoSource.random);
                      }
                    },
              icon: const Icon(Icons.shuffle),
              label: const Text('Volver a Aleatoria'),
            ),
            const SizedBox(height: 16),
            Text(
              'Apariencia y temporadas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Center(child: TokTikLogo(season: settings.season, size: 80)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue:
                  settings.preferences.manualSeason?.name ?? 'automatic',
              decoration: const InputDecoration(
                labelText: 'Temporada',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: 'automatic',
                  child: Text('Automático'),
                ),
                ...Season.values.map(
                  (season) => DropdownMenuItem(
                    value: season.name,
                    child: Text(
                      season.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: settings.saving
                  ? null
                  : (value) => settings.selectSeason(Season.parse(value)),
            ),
            const SizedBox(height: 12),
            Text('Tema actual: ${settings.season.label}'),
            TextButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Vista previa de intro'),
              onPressed: () => IntroPreviewScreen.open(
                context,
                settings.season,
                context.read<PlaybackCoordinator?>(),
                context.read<IntroAudioProvider?>(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sonido de las intros'),
              subtitle: const Text(
                'Efecto breve; respeta el silencio general del video.',
              ),
              value: settings.preferences.introSound,
              onChanged: settings.saving ? null : settings.setIntroSound,
            ),
            if (identity?.error != null) ...[
              Text(identity!.error!),
              TextButton(
                onPressed: identity.synchronize,
                child: const Text('Reintentar ícono'),
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Audio temático'),
              subtitle: const Text(
                'Sólo suena si el video está silenciado o pausado. El tema Normal no tiene audio.',
              ),
              value: settings.preferences.themeAudio,
              onChanged: settings.saving ? null : settings.setThemeAudio,
            ),
            if (audio.playing) const Text('Audio temático activo'),
            if (settings.error != null)
              Text(
                settings.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (audio.error != null) Text(audio.error!),
            if (feed.notices.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Estado de las fuentes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...feed.notices.map(
                (notice) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(notice),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Listo'),
            ),
          ],
        ),
      ),
    );
  }
}
