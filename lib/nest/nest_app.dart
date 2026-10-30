import 'package:flutter/material.dart';

import 'core/nest_theme.dart';
import 'screens/nest_shell.dart';

class NestApp extends StatelessWidget {
  const NestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEST',
      debugShowCheckedModeBanner: false,
      theme: buildNestTheme(),
      darkTheme: buildNestTheme(),
      themeMode: ThemeMode.light,
      color: NestColors.cream,
      builder: (context, child) => ColoredBox(
        color: NestColors.cream,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const NestShell(),
    );
  }
}
