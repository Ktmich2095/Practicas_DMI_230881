

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:widgets_app/config/menu/menu_items.dart';

class HomeScreen extends StatelessWidget{
  static const String name = 'home_screen';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter + Material 3'),
      ),
      body: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget{
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: appMenuItems.length,
      itemBuilder: (context, index) {
        final menuItem = appMenuItems[index];
        return _CustomListTile(menuItem: menuItem);
      },
    );
  }
}

class _CustomListTitle extends StatelessWidget{
  const _CustomListTitle({
    required this.menuItem
  });

  final MenuItem menuItem;

  @override
  Widget build(BuildContext context){
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(menuItem.icon,color)
  }
}