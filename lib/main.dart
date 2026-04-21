import 'package:attendance/config/app_config.dart';
import 'package:attendance/config/router.dart';
import 'package:attendance/services/auth_service.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:attendance/composants/notification_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // --- CHARGEMENT DES CONFIGURATIONS DYNAMIQUES ---
  try {
    final response = await Supabase.instance.client
        .from('app_settings')
        .select('cle, valeur');

    final Map<String, String> configMap = {};
    for (var item in response) {
      configMap[item['cle']] = item['valeur'];
    }
    AppConfig.updateFromMap(configMap);
  } catch (e) {
    debugPrint("Erreur lors du chargement des app_settings: $e");
  }

  usePathUrlStrategy();

  await initializeDateFormatting('fr_FR', null);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final AuthService _authService = AuthService();
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    // Écouter les changements d'auth globalement
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.tokenRefreshed) {
        final profile = await _authService.getCurrentUserProfile();
        ref.read(userProvider.notifier).state = profile;
      } else if (data.event == AuthChangeEvent.signedOut) {
        ref.read(userProvider.notifier).state = null;
      }
    });

    // Chargement initial
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final profile = await _authService.getCurrentUserProfile();
      ref.read(userProvider.notifier).state = profile;
    }

    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      scaffoldMessengerKey: AppNotification.messengerKey,
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
    );
  }
}
