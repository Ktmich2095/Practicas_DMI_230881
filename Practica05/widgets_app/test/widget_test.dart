import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgets_app/main.dart';
import 'package:widgets_app/config/router/app_router.dart';
import 'package:widgets_app/config/menu/menu_items.dart';
import 'package:widgets_app/presentation/providers/theme_provider.dart';
import 'package:widgets_app/presentation/screens/screens.dart';
import 'package:widgets_app/presentation/widgets/remote_image.dart';

void main() {
  testWidgets('Home, push/pop and reactive counter', (tester) async {
    final router = createAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(child: MainApp(router: router)));
    await tester.pumpAndSettle();
    expect(find.text('Flutter + Material 3'), findsOneWidget);
    await tester.tap(find.text('Riverpod Counter'));
    await tester.pumpAndSettle();
    expect(find.text('Valor: 5'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('Valor: 6'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Flutter + Material 3'), findsOneWidget);
  });

  testWidgets('Drawer navigates to buttons and enabled action responds', (
    tester,
  ) async {
    final router = createAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(child: MainApp(router: router)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationDrawer),
        matching: find.text('Botones'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ButtonsScreen), findsOneWidget);
    await tester.tap(find.text('Elevated'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Elevated Disabled'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'Theme controls change actual MaterialApp and keep selected color',
    (tester) async {
      final router = createAppRouter();
      final container = ProviderContainer();
      addTearDown(router.dispose);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MainApp(router: router),
        ),
      );
      router.push('/theme-changer');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Color 2'));
      await tester.pumpAndSettle();
      expect(container.read(themeNotifierProvider).selectedColor, 1);
      await tester.tap(find.byIcon(Icons.light_mode_outlined));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(ThemeChangerScreen))).brightness,
        Brightness.dark,
      );
      router.pop();
      router.push('/counter-river');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.dark_mode_outlined));
      await tester.pumpAndSettle();
      expect(container.read(themeNotifierProvider).isDarkmode, false);
      expect(container.read(themeNotifierProvider).selectedColor, 1);
    },
  );

  testWidgets('Every menu route opens, renders and returns', (tester) async {
    final router = createAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(child: MainApp(router: router)));
    await tester.pumpAndSettle();
    final screenTypes = <Type>[
      CounterScreen,
      ButtonsScreen,
      CardsScreen,
      ProgressScreen,
      SnackbarScreen,
      AnimatedScreen,
      UiControlsScreen,
      AppTutorialScreen,
      InfiniteScrollScreen,
      ThemeChangerScreen,
    ];
    for (var index = 0; index < appMenuItems.length; index++) {
      final item = appMenuItems[index];
      router.push(item.link);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(screenTypes[index]), findsOneWidget);
      expect(router.canPop(), isTrue);
      expect(find.byType(Scaffold), findsWidgets);
      expect(tester.takeException(), isNull, reason: item.link);
      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(router.routerDelegate.currentConfiguration.uri.path, '/');
  });

  testWidgets('Progress remains in range and completes at 100 percent', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProgressScreen()));
    await tester.pump(const Duration(seconds: 16));
    final progress = tester.widgetList<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(progress.any((p) => p.value == 1), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Tutorial local images, next and finish work at narrow width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = createAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(child: MainApp(router: router)));
    router.push('/tutorial');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Comenzar'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/');
  });

  testWidgets('Controls update switch, radio and checkbox', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: UiControlsScreen()));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      false,
    );
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('boat'));
    await tester.pump();
    expect(find.text('Transportation.boat'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();
    expect(
      tester
          .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
          .value,
      true,
    );
  });

  testWidgets('Photo failure shows retry without uncaught network exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RemoteImage(url: 'https://invalid.example/photo.png'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo cargar la imagen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pagination appends and refresh replaces photo IDs', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: InfiniteScrollScreen()));
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.childrenDelegate.estimatedChildCount, 6);
    final scroll = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    scroll.jumpTo(scroll.maxScrollExtent);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(
      tester
          .widget<ListView>(find.byType(ListView))
          .childrenDelegate
          .estimatedChildCount,
      11,
    );
    final refresh = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    final result = refresh.onRefresh();
    await tester.pump(const Duration(seconds: 2));
    await result;
    await tester.pump();
    expect(
      tester
          .widget<ListView>(find.byType(ListView))
          .childrenDelegate
          .estimatedChildCount,
      6,
    );
    expect(find.byKey(const ValueKey(1)), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dialogs open and dismiss, snackbar is visible', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SnackbarScreen()));
    await tester.tap(find.textContaining('Mostrar di'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Licencias usadas'));
    await tester.pumpAndSettle();
    expect(find.byType(AboutDialog), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mostrar Snackbar'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
