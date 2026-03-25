import 'package:equatable/equatable.dart';
import 'package:vida_ativa/core/models/user_model.dart';

enum ViewMode { admin, client }

sealed class AuthState extends Equatable {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();

  @override
  List<Object?> get props => [];
}

class AuthLoading extends AuthState {
  const AuthLoading();

  @override
  List<Object?> get props => [];
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  final ViewMode viewMode;

  const AuthAuthenticated(this.user, {this.viewMode = ViewMode.admin});

  @override
  List<Object?> get props => [user, viewMode];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();

  @override
  List<Object?> get props => [];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
