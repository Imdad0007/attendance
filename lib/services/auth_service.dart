import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance/models/surveillant_model.dart';
import 'package:flutter/foundation.dart';

// --- CES ENUMS DOIVENT ÊTRE ICI POUR ÊTRE VUES PAR LOGIN.DART ---
enum AuthStatus { onlineSuccess, invalidCredentials, noInternet, unknownError }

class AuthResult {
  final AuthStatus status;
  final Surveillant? user;
  AuthResult({required this.status, this.user});
}

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // FONCTION DE CONNEXION
  Future<AuthResult> signIn(String username, String password) async {
    try {
      final response = await _supabase
          .from('surveillant')
          .select()
          .eq('username', username)
          .eq('mdp', password).filter('delete_at', 'is', null) // Vérifie bien que ta colonne s'appelle 'mdp'
          .maybeSingle(); // Retourne null si pas trouvé au lieu de crash

      if (response == null) {
        return AuthResult(status: AuthStatus.invalidCredentials);
      }

      final user = Surveillant.fromMap(response);
      return AuthResult(status: AuthStatus.onlineSuccess, user: user);
    } catch (e) {
      debugPrint("Erreur Login: $e");
      // On détecte si c'est un problème de réseau
      if (e.toString().contains("SocketException") ||
          e.toString().contains("connection error")) {
        return AuthResult(status: AuthStatus.noInternet);
      }
      return AuthResult(status: AuthStatus.unknownError);
    }
  }

  // FONCTION DE MISE À JOUR (Celle qui posait problème)
  Future<bool> updateUserField(int userId, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('surveillant')
          .update(data)
          .eq(
            'id_surveillant',
            userId,
          ); // NOM EXACT SELON TA CAPTURE (minuscules)
      return true;
    } catch (e) {
      debugPrint("Erreur Update: $e");
      return false;
    }
  }
}
