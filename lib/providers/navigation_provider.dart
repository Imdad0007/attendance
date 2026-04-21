import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. L'Enum doit être défini ici
enum AppTab {
  dashboard,
  home,
  seance,
  presence,
  historique,
  utilisateurs,
  profil,
}

// 2. Le provider utilise cet Enum
final navigationTabProvider = StateProvider<AppTab>((ref) {
  return AppTab.home;
});
