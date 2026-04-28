import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTab {
  dashboard,
  home,
  seance,
  presence,
  historique,
  utilisateurs,
  profil,
}

enum AdaptivePage {
  none,
  creerSeance,
  consulterSeance,
  detailHistorique,
  classList,
  successRegistration,
  creerUtilisateur,
  listerUtilisateurs,
  retirerUtilisateur,
}

class AdaptiveNavigationState {
  final AdaptivePage page;
  final Object? extra;

  const AdaptiveNavigationState({this.page = AdaptivePage.none, this.extra});

  const AdaptiveNavigationState.none() : this();
}

final navigationTabProvider = StateProvider<AppTab>((ref) {
  return AppTab.home;
});

final adaptiveNavigationProvider = StateProvider<AdaptiveNavigationState>((
  ref,
) {
  return const AdaptiveNavigationState.none();
});

final railExtendedProvider = StateProvider<bool>((ref) => true);
