import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendance/models/surveillant_model.dart';

// Le provider qui contient l'utilisateur connecté (null par défaut)
final userProvider = StateProvider<Surveillant?>((ref) => null);


