import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/fcm/fcm_service.dart';

class LoginState {
  final bool isLoading;
  final String? error;

  const LoginState({this.isLoading = false, this.error});

  LoginState copyWith({bool? isLoading, String? error, bool clearError = false}) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LoginNotifier extends StateNotifier<LoginState> {
  LoginNotifier() : super(const LoginState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      // Guarda el FCM token del dispositivo para recibir push notifications
      await FcmService.saveToken();
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _traducirError(e.message));
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error inesperado. Intenta de nuevo.',
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _traducirError(String mensaje) {
    if (mensaje.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (mensaje.contains('Email not confirmed')) {
      return 'Confirma tu correo antes de ingresar.';
    }
    if (mensaje.contains('Too many requests')) {
      return 'Demasiados intentos. Espera un momento.';
    }
    if (mensaje.contains('User not found')) {
      return 'No existe una cuenta con este correo.';
    }
    return 'Error al iniciar sesión. Intenta de nuevo.';
  }
}

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>(
  (ref) => LoginNotifier(),
);
