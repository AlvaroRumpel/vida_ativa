import 'package:flutter/foundation.dart';

/// Set to true when an FCM notification is tapped (background→foreground).
/// AdminScreen reads and resets this on mount and on change.
final navigateToReservasNotifier = ValueNotifier<bool>(false);
