import 'package:attendance/config/app_config.dart';
import 'package:attendance/config/router.dart';
import 'package:attendance/services/auth_service.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:attendance/providers/navigation_provider.dart';
import 'package:attendance/pages/pages_historique/onglet_historique.dart';
import 'package:attendance/providers/inactivity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint("Erreur critique Supabase.initialize: $e");
  }

  // Utilisation conditionnelle de l'URL strategy pour le Web
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  try {
    await initializeDateFormatting('fr_FR', null);
  } catch (e) {
    debugPrint("Erreur intl: $e");
  }

  // On attend le chargement des réglages avant de lancer l'app
  // avec un timeout de 5 secondes pour ne pas bloquer l'utilisateur
  await _loadAppSettings().timeout(
    const Duration(seconds: 5),
    onTimeout: () => debugPrint("Timeout lors du chargement des réglages"),
  );

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _loadAppSettings() async {
  try {
    final client = Supabase.instance.client;
    final response =
        await client.from('app_settings').select('cle, valeur') as List;

    final Map<String, String> configMap = {};
    for (var item in response) {
      if (item is Map && item.containsKey('cle')) {
        configMap[item['cle'].toString()] = item['valeur']?.toString() ?? '';
      }
    }
    debugPrint(
      "Configuration chargée depuis Supabase: ${configMap.keys.join(', ')}",
    );
    AppConfig.updateFromMap(configMap);
  } catch (e) {
    debugPrint(
      "Info: app_settings non chargés (normal si première install): $e",
    );
  }
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
    try {
      // Écouter les changements d'auth globalement
      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        if (data.event == AuthChangeEvent.signedIn ||
            data.event == AuthChangeEvent.tokenRefreshed) {
          try {
            final profile = await _authService.getCurrentUserProfile();
            ref.read(userProvider.notifier).state = profile;
          } catch (e) {
            debugPrint("Erreur rafraîchissement profil: $e");
          }
        } else if (data.event == AuthChangeEvent.signedOut) {
          // Reset de tous les états lors de la déconnexion
          ref.invalidate(userProvider);
          ref.invalidate(navigationTabProvider);
          ref.invalidate(historiqueProvider);
        }
      });

      // Chargement initial
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        try {
          final profile = await _authService.getCurrentUserProfile();
          ref.read(userProvider.notifier).state = profile;
        } catch (e) {
          debugPrint("Erreur chargement profil initial: $e");
        }
      }
    } catch (e) {
      debugPrint("Erreur initAuth: $e");
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
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
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (child == null) return const SizedBox();

        return Listener(
          onPointerDown: (_) =>
              ref.read(inactivityProvider.notifier).resetTimer(),
          onPointerMove: (_) =>
              ref.read(inactivityProvider.notifier).resetTimer(),
          onPointerHover: (_) =>
              ref.read(inactivityProvider.notifier).resetTimer(),
          child: ResponsiveBreakpoints.builder(
            child: ResponsiveScaledBox(
              width: MediaQuery.of(context).size.width,
              child: child,
            ),
            breakpoints: const [
              Breakpoint(start: 0, end: 600, name: MOBILE),
              Breakpoint(start: 601, end: 1024, name: TABLET),
              Breakpoint(start: 1025, end: 1920, name: DESKTOP),
              Breakpoint(start: 1921, end: double.infinity, name: '4K'),
            ],
          ),
        );
      },
    );
  }
}
