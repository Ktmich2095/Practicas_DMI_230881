export 'home/home_screen.dart';
export 'buttons/buttos_screen.dart';
export 'cards/cards_screen.dart';

import 'package:flutter/material.dart';

class ButtonsScreen extends StatelessWidget {
  static const String name = 'buttons_screen';

  const ButtonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buttons Screen'),
      ),
      body: const Center(
        child: Text('Buttons'),
      ),
    );
  }
}