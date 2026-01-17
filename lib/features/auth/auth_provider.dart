import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_controller.dart';

// Auth controller provider
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController();
});

// Current user provider
final authStateProvider = StreamProvider<User?>((ref) {
  final controller = ref.read(authControllerProvider);
  return controller.authStateChanges();
});
