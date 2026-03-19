import 'package:flutter_test/flutter_test.dart';

import 'package:vida_ativa/core/theme/app_theme.dart';

void main() {
  testWidgets('App theme uses green primary color', (tester) async {
    // Verify AppTheme configures correctly
    final theme = AppTheme.lightTheme;
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, equals(AppTheme.primaryGreen));
  });
}
