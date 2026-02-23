import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_provider.dart';

final roleProvider = Provider<String>((ref) {
  final user = ref.watch(userProvider);
  return user?.role ?? 'adjoint';
});

final isAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(roleProvider);
  return role.toLowerCase() == 'general';
});

final isAdjointProvider = Provider<bool>((ref) {
  final role = ref.watch(roleProvider);
  return role.toLowerCase() == 'adjoint';
});
