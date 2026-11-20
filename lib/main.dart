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

class ArmarioApp extends StatefulWidget {
  const ArmarioApp({super.key});

  @override
  State<ArmarioApp> createState() => _ArmarioAppState();
}

class _ArmarioAppState extends State<ArmarioApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    themeMode.addListener(_onTheme);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    themeMode.removeListener(_onTheme);
    super.dispose();
  }

  void _onTheme() => setState(() {});

  @override
  void didChangePlatformBrightness() => setState(() {});

  bool get _dark {
    switch (themeMode.value) {
      case 'escuro':
        return true;
      case 'claro':
        return false;
      default:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = _dark;
    appDark = dark;
    // A chave força remontar tudo ao trocar o tema, para as cores AppColor
    // (inclusive em widgets const) serem lidas de novo.
    return MaterialApp(
      key: ValueKey(dark),
      title: 'Armário Virtual',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(dark),
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
    (Icons.settings_outlined, Icons.settings_rounded, 'Configurações'),
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
                backgroundColor: C.navBar,
                indicatorColor: C.navActive,
                indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                selectedIndex: index,
                onDestinationSelected: (i) => tabIndex.value = i,
                destinations: [
                  for (final d in _icons)
                    NavigationDestination(
                      icon: Icon(d.$1, color: C.navIcon),
                      selectedIcon: Icon(d.$2, color: C.onPrimary),
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
