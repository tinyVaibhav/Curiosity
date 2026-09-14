import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/state/feed_provider.dart';
import 'core/state/settings_provider.dart';
import 'core/theme/geist_theme.dart';
import 'screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CuriosityApp());
}

class CuriosityApp extends StatelessWidget {
  final SettingsProvider? settingsProvider;

  const CuriosityApp({
    super.key,
    this.settingsProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        if (settingsProvider != null)
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider!)
        else
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Selector<SettingsProvider, ThemeMode>(
        selector: (_, settings) => settings.themeMode,
        builder: (context, themeMode, _) {
          return MaterialApp(
            title: 'Curiosity',
            debugShowCheckedModeBanner: false,
            theme: GeistTheme.lightTheme,
            darkTheme: GeistTheme.darkTheme,
            themeMode: themeMode,
            home: const MainShellScreen(),
          );
        },
      ),
    );
  }
}
