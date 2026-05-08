import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();
}

@immutable
final class SettingsInitial extends SettingsState {
  const SettingsInitial();

  @override
  List<Object?> get props => [];
}

@immutable
final class SettingsLoaded extends SettingsState {
  final bool isAccessTokenConfigured;
  final bool isWebhookSecretConfigured;
  final bool pixEnabled;

  const SettingsLoaded({
    required this.isAccessTokenConfigured,
    required this.isWebhookSecretConfigured,
    required this.pixEnabled,
  });

  @override
  List<Object?> get props => [
        isAccessTokenConfigured,
        isWebhookSecretConfigured,
        pixEnabled,
      ];
}

@immutable
final class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
