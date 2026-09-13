import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/state/feed_provider.dart';
import 'core/theme/geist_theme.dart';
import 'screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CuriosityApp());
}

class CuriosityApp extends StatelessWidget {
  const CuriosityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FeedProvider()),
      ],
      child: MaterialApp(
        title: 'Curiosity',
        debugShowCheckedModeBanner: false,
        theme: GeistTheme.lightTheme,
        darkTheme: GeistTheme.darkTheme,
        themeMode: ThemeMode.dark, // Default to pure dark mode
        home: const MainShellScreen(),
      ),
    );
  }
}
