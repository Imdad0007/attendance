import 'package:attendance/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:attendance/providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fkvybbyrbktpetdyqymt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrdnliYnlyYmt0cGV0ZHlxeW10Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxMTMwMTIsImV4cCI6MjA4NTY4OTAxMn0.W_5TT4lmAGoCck61kP36xJDRJSsLl5HOpITvRGEiwmA',
  );

  usePathUrlStrategy();

  await initializeDateFormatting('fr_FR', null);

  runApp(
    ChangeNotifierProvider(create: (_) => UserProvider(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (child == null) return const SizedBox();

        return ResponsiveBreakpoints.builder(
          child: MaxWidthBox(maxWidth: 1200, child: child),
          breakpoints: const [
            Breakpoint(start: 0, end: 600, name: MOBILE),
            Breakpoint(start: 601, end: 1024, name: TABLET),
            Breakpoint(start: 1025, end: 1920, name: DESKTOP),
            Breakpoint(start: 1921, end: double.infinity, name: '4K'),
          ],
        );
      },
      home: const LoginPage(),
    );
  }
}
