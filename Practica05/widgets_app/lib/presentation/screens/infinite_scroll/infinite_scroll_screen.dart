import 'package:flutter/material.dart';
import '../../widgets/remote_image.dart';

class InfiniteScrollScreen extends StatefulWidget {
  static const name = 'infinite_screen';
  const InfiniteScrollScreen({super.key});
  @override
  State<InfiniteScrollScreen> createState() => _InfiniteScrollScreenState();
}

class _InfiniteScrollScreenState extends State<InfiniteScrollScreen> {
  final scrollController = ScrollController();
  List<int> imagesIds = [1, 2, 3, 4, 5];
  bool isLoading = false;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (scrollController.position.extentAfter < 500) loadNextPage();
    });
  }

  Future<void> loadNextPage() async {
    if (isLoading) return;
    final request = generation;
    setState(() => isLoading = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted || request != generation) return;
    setState(() {
      final last = imagesIds.last;
      imagesIds.addAll(List.generate(5, (i) => last + i + 1));
      isLoading = false;
    });
  }

  Future<void> onRefresh() async {
    final request = ++generation;
    setState(() => isLoading = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted || request != generation) return;
    setState(() {
      final next = imagesIds.last + 1;
      imagesIds = List.generate(5, (i) => next + i);
      isLoading = false;
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Galería infinita')),
    body: RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: scrollController,
        itemCount: imagesIds.length + 1,
        itemBuilder: (context, index) {
          if (index == imagesIds.length) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Desliza para explorar más'),
              ),
            );
          }
          final id = imagesIds[index];
          return Column(
            children: [
              RemoteImage(
                key: ValueKey(id),
                url: 'https://picsum.photos/seed/widgets-$id/600/350',
              ),
              ListTile(
                title: Text('Fotografía $id'),
                subtitle: const Text(
                  'Desliza hacia abajo para renovar la galería',
                ),
              ),
            ],
          );
        },
      ),
    ),
    floatingActionButton: FloatingActionButton(
      tooltip: 'Volver al inicio de la lista',
      onPressed: () => scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      ),
      child: const Icon(Icons.vertical_align_top),
    ),
  );
}
