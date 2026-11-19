import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'home.dart';
import 'menu.dart';
import 'store.dart';
import 'theme.dart';
import 'tracking.dart';
import 'wardrobe.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  store.load();
  runApp(const ArmarioApp());
}

class ArmarioApp extends StatelessWidget {
  const ArmarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Armário Virtual',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Shell(),
    );
  }
}

class Shell extends StatelessWidget {
  const Shell({super.key});

  static const _icons = [
    (Icons.checkroom_outlined, Icons.checkroom, 'Guarda-Roupas'),
    (Icons.home_outlined, Icons.home_rounded, 'Início'),
    (Icons.bar_chart_rounded, Icons.bar_chart_rounded, 'Rastreio'),
    (Icons.menu_rounded, Icons.menu_rounded, 'Menu'),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: tabIndex,
      builder: (context, index, _) {
        return ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            if (!store.loaded) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            return Scaffold(
              body: SafeArea(
                bottom: false,
                child: IndexedStack(
                  index: index,
                  children: const [WardrobePage(), HomePage(), TrackingPage(), MenuPage()],
                ),
              ),
              bottomNavigationBar: NavigationBar(
                height: 72,
                backgroundColor: C.primaryDark,
                indicatorColor: C.navActive,
                indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                selectedIndex: index,
                onDestinationSelected: (i) => tabIndex.value = i,
                destinations: [
                  for (final d in _icons)
                    NavigationDestination(
                      icon: Icon(d.$1, color: C.navIcon),
                      selectedIcon: Icon(d.$2, color: Colors.white),
                      label: d.$3,
                      tooltip: d.$3,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
