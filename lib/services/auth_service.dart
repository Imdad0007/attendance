import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance/models/surveillant_model.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus {
  onlineSuccess,
  invalidCredentials,
  noInternet,
  unknownError,
  emailNotConfirmed,
  accountDeactivated,
}

class AuthResult {
  final AuthStatus status;
  final Surveillant? user;
  final String? message;
  AuthResult({required this.status, this.user, this.message});
}

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // CONNEXION AVEC EMAIL ET MOT DE PASSE
  Future<AuthResult> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult(
          status: AuthStatus.invalidCredentials,
          message: "Email ou mot de passe incorrect.",
        );
      }

      // 1. Récupérer le profil brut pour vérifier l'état du compte
      final rawProfile = await _supabase
          .from('surveillant')
          .select()
          .eq('auth_id', response.user!.id)
          .maybeSingle();

      if (rawProfile == null) {
        return AuthResult(
          status: AuthStatus.unknownError,
          message: "Profil utilisateur non trouvé.",
        );
      }

      // 2. Vérifier si le compte a été retiré (Soft Delete)
      if (rawProfile['delete_at'] != null) {
        await signOut(); // Déconnexion immédiate
        return AuthResult(
          status: AuthStatus.accountDeactivated,
          message: "Ce compte a été retiré du système.",
        );
      }

      return AuthResult(
        status: AuthStatus.onlineSuccess,
        user: Surveillant.fromMap(rawProfile),
      );
    } on AuthException catch (e) {
      debugPrint("Erreur Auth: ${e.message}");
      // Mapping des erreurs techniques vers des messages utilisateurs
      if (e.message.contains("Invalid login credentials") ||
          e.message.contains("invalid_credentials")) {
        return AuthResult(
          status: AuthStatus.invalidCredentials,
          message: "Email ou mot de passe incorrect.",
        );
      }
      if (e.message.contains("Email not confirmed")) {
        return AuthResult(
          status: AuthStatus.emailNotConfirmed,
          message:
              "Veuillez confirmer votre adresse email avant de vous connecter.",
        );
      }
      if (e.message.contains("too many requests")) {
        return AuthResult(
          status: AuthStatus.unknownError,
          message: "Trop de tentatives. Veuillez réessayer plus tard.",
        );
      }
      return AuthResult(
        status: AuthStatus.unknownError,
        message: "Une erreur est survenue lors de l'authentification.",
      );
    } catch (e) {
      debugPrint("Erreur Inattendue: $e");
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains("socketexception") ||
          errorStr.contains("network_error") ||
          errorStr.contains("connection failed") ||
          errorStr.contains("handshake")) {
        return AuthResult(
          status: AuthStatus.noInternet,
          message:
              "Problème de connexion. Veuillez vérifier votre accès internet.",
        );
      }
      return AuthResult(
        status: AuthStatus.unknownError,
        message: "Impossible de contacter le serveur. Veuillez réessayer.",
      );
    }
  }

  // RÉINITIALISATION DE MOT DE PASSE (ENVOI D'EMAIL)
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      debugPrint("Erreur Reset Password: $e");
      return false;
    }
  }

  // RÉCUPÉRATION DU PROFIL ACTUEL (POUR AUTO-LOGIN)
  Future<Surveillant?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    // On vérifie aussi le delete_at ici pour l'auto-login
    final profile = await _supabase
        .from('surveillant')
        .select()
        .eq('auth_id', user.id)
        .filter('delete_at', 'is', null)
        .maybeSingle();

    return profile != null ? Surveillant.fromMap(profile) : null;
  }

  // DÉCONNEXION
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // MODIFICATION D'UN CHAMP DANS LA TABLE SURVEILLANT
  Future<bool> updateUserField(int userId, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('surveillant')
          .update(data)
          .eq('id_surveillant', userId);
      return true;
    } catch (e) {
      debugPrint("Erreur Update: $e");
      return false;
    }
  }
}


