import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/video_post.dart';
import '../providers/playback_coordinator.dart';
import '../widgets/video/fullscreen_player.dart';

class VideoScrollableView extends StatefulWidget {
  final List<VideoPost> videos;
  final bool continuous;
  final VoidCallback? onNearEnd;
  final int initialPage;
  final ValueChanged<int>? onPositionChanged;
  const VideoScrollableView({
    super.key,
    required this.videos,
    this.continuous = false,
    this.onNearEnd,
    this.initialPage = 0,
    this.onPositionChanged,
  });
  @override
  State<VideoScrollableView> createState() => _VideoScrollableViewState();
}

class _VideoScrollableViewState extends State<VideoScrollableView>
    with WidgetsBindingObserver {
  late PlaybackCoordinator playback;
  late final PageController pages;
  late final Object owner;
  int page = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    playback = context.read<PlaybackCoordinator>();
    owner = playback.claimFeed();
    page = widget.initialPage.clamp(0, widget.videos.length - 1);
    pages = PageController(initialPage: page);
    playback.select(widget.videos, page);
  }

  @override
  void didUpdateWidget(VideoScrollableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (listEquals(
      oldWidget.videos.map((v) => '${v.id}:${v.videoUrl}').toList(),
      widget.videos.map((v) => '${v.id}:${v.videoUrl}').toList(),
    )) {
      return;
    }
    final previous = oldWidget.videos[page % oldWidget.videos.length].id;
    final next = widget.videos.indexWhere((v) => v.id == previous);
    if (widget.videos.length < oldWidget.videos.length ||
        next < 0 ||
        next != page % widget.videos.length) {
      page = next < 0 ? 0 : next;
      widget.onPositionChanged?.call(page);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && pages.hasClients) pages.jumpToPage(page);
      });
    }
    if (playback.ownsFeed(owner)) {
      playback.updateVideos(widget.videos, page % widget.videos.length);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      playback.lifecycle(state == AppLifecycleState.resumed);
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    playback.releaseFeed(owner);
    pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: playback,
    builder: (context, _) => PageView.builder(
      controller: pages,
      scrollDirection: Axis.vertical,
      itemCount: widget.continuous ? null : widget.videos.length,
      onPageChanged: (index) {
        page = index;
        final logical = index % widget.videos.length;
        widget.onPositionChanged?.call(logical);
        if (playback.ownsFeed(owner)) playback.select(widget.videos, logical);
        if (logical >= widget.videos.length - 3) widget.onNearEnd?.call();
      },
      itemBuilder: (context, index) => FullscreenPlayer(
        video: widget.videos[index % widget.videos.length],
        playback: playback,
      ),
    ),
  );
}
