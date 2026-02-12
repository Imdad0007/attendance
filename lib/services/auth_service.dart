import 'dart:io';
import 'package:attendance/models/surveillant.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

enum AuthStatus { onlineSuccess, invalidCredentials, noInternet, unknownError }

class AuthResult {
  final AuthStatus status;
  final Surveillant? user;

  AuthResult({required this.status, this.user});
}

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResult> signIn(String username, String password) async {
    try {
      final response = await _supabase
          .from('surveillant')
          .select()
          .eq('username', username)
          .eq('mdp', password)
          .single();

      final user = Surveillant.fromMap(response);

      return AuthResult(status: AuthStatus.onlineSuccess, user: user);
    } catch (e) {
      debugPrint("AuthService sign-in caught exception: ${e.runtimeType} - $e");
      if (e is PostgrestException) {
        if (e.message.contains('rows returned') || e.code == 'PGRST116') {
          return AuthResult(status: AuthStatus.invalidCredentials);
        }
      } else if (e is SocketException || e is http.ClientException) {
        return AuthResult(status: AuthStatus.noInternet);
      }
      return AuthResult(status: AuthStatus.unknownError);
    }
  }
}
