import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/season_style.dart';
import '../../../domain/entities/season.dart';
import '../../providers/discover_provider.dart';
import '../../providers/settings_provider.dart';
import '../../shared/video_scrollable_view.dart';
import '../../widgets/settings_sheet.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int section = 1;
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiscoverProvider>();
    final settings = context.watch<SettingsProvider>();
    final colors = Theme.of(context).colorScheme;
    final style = SeasonStyle.of(settings.season);
    final videos = section == 2
        ? provider.favorites
        : section == 0
        ? (provider.videos.toList()..sort((a, b) => b.views.compareTo(a.views)))
        : provider.videos;
    void openSettings() => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) =>
          const FractionallySizedBox(heightFactor: .85, child: SettingsSheet()),
    );
    return Scaffold(
      body: Stack(
        children: [
          if (section != 2 && provider.initialLoading)
            const Center(child: CircularProgressIndicator())
          else if (section != 2 && provider.error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 52),
                    const SizedBox(height: 16),
                    Text(provider.error!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: provider.loadNextPage,
                      child: const Text('Reintentar'),
                    ),
                    TextButton(
                      onPressed: openSettings,
                      child: const Text('Cambiar fuente'),
                    ),
                  ],
                ),
              ),
            )
          else if (videos.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 64,
                      color: colors.secondary,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Tus historias favoritas, aquí',
                      style: TextStyle(fontSize: 22),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Toca el corazón de un video para guardarlo.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            VideoScrollableView(
              key: ValueKey('$section:${provider.selectedSource.name}'),
              videos: videos,
              continuous: section == 1 && !provider.hasMore,
              onNearEnd: section == 1 ? provider.loadMore : null,
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
              child: Row(
                children: [
                  Text(
                    'tok',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'tik',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.primary,
                    ),
                  ),
                  if (settings.season != Season.normal)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 350),
                        child: Icon(
                          style.icon,
                          key: ValueKey(settings.season),
                          color: colors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      section == 2 ? 'GUARDADOS' : provider.actualSource.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fuentes y temas',
                    onPressed: openSettings,
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
            ),
          ),
          if (provider.loadingMore)
            const Positioned(
              top: 70,
              right: 20,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (provider.persistenceError != null || settings.error != null)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 64,
              left: 20,
              right: 20,
              child: Material(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(provider.persistenceError ?? settings.error!),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: style.background,
        indicatorColor: colors.primary.withValues(alpha: .2),
        selectedIndex: section,
        onDestinationSelected: (value) => setState(() => section = value),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          const NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle),
            label: 'For You',
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: colors.secondary),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }
}
