import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class AuthState {
  final User? user;
  final bool isPro;
  final int standardUsed;
  final int standardLimit;
  final bool emailReceipts;

  const AuthState({
    this.user,
    this.isPro = false,
    this.standardUsed = 0,
    this.standardLimit = 200,
    this.emailReceipts = true,
  });

  AuthState copyWith({
    User? user,
    bool? isPro,
    int? standardUsed,
    int? standardLimit,
    bool? emailReceipts,
  }) {
    return AuthState(
      user: user ?? this.user,
      isPro: isPro ?? this.isPro,
      standardUsed: standardUsed ?? this.standardUsed,
      standardLimit: standardLimit ?? this.standardLimit,
      emailReceipts: emailReceipts ?? this.emailReceipts,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  void setUser(User user, {bool isPro = false}) {
    state = state.copyWith(user: user, isPro: isPro);
  }

  void signOut() {
    state = const AuthState();
  }

  void setEmailReceipts(bool value) {
    state = state.copyWith(emailReceipts: value);
  }

  void upgradeToPro() {
    state = state.copyWith(isPro: true);
  }

  void setIsPro(bool value) {
    state = state.copyWith(isPro: value);
  }

  void updateUsage({required int used, required int limit}) {
    state = state.copyWith(standardUsed: used, standardLimit: limit);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
