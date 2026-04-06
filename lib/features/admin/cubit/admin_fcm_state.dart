part of 'admin_fcm_cubit.dart';

sealed class AdminFcmState {}

/// Initial state — permission status not yet checked.
final class AdminFcmInitial extends AdminFcmState {}

/// Browser has not yet been asked for permission (notDetermined).
/// Admin screen should show a banner prompting the admin to enable notifications.
final class AdminFcmPermissionRequired extends AdminFcmState {}

/// Permission granted and FCM token stored in Firestore.
final class AdminFcmActive extends AdminFcmState {
  final String token;
  AdminFcmActive(this.token);
}

/// Permission denied by the browser. Cannot request again programmatically.
final class AdminFcmDenied extends AdminFcmState {}

/// An error occurred during permission request or token fetch.
final class AdminFcmError extends AdminFcmState {
  final String message;
  AdminFcmError(this.message);
}
