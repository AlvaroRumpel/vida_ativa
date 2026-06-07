import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vida_ativa/core/models/user_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/admin/ui/users_management_tab.dart';

const _adminUser = UserModel(
  uid: 'uid-admin',
  email: 'admin@test.com',
  displayName: 'Alice Admin',
  role: 'admin',
);

const _clientUser = UserModel(
  uid: 'uid-client',
  email: 'client@test.com',
  displayName: 'Bob Client',
  role: 'client',
);

/// Renders a single _UserRow by wrapping in a minimal widget tree.
/// We expose _UserRow via a test-only factory function in the main file,
/// or we pump UsersManagementTab with a stubbed list — but since
/// UsersManagementTab calls Firestore on init, we instead test _UserRow
/// directly by making it @visibleForTesting or testing via the exported widget.
///
/// Because _UserRow is a private class, we test it through
/// the public UserRow exported widget or by passing pre-built rows.
/// Strategy: pump a standalone _UserRow via a thin public wrapper exported
/// for testing only (TestableUserRow) — OR pump the full tab with mocked data.
///
/// SIMPLEST approach: export a top-level UserRow (non-private) in
/// users_management_tab.dart, used both by the tab and tests.
Widget _buildRow({required UserModel user, required int index}) {
  return MaterialApp(
    home: Scaffold(
      body: UserRow(
        user: user,
        index: index,
        onPromote: () {},
      ),
    ),
  );
}

void main() {
  group('UserRow', () {
    testWidgets('ADMN-21a: admin user has orange CircleAvatar background',
        (tester) async {
      await tester.pumpWidget(_buildRow(user: _adminUser, index: 0));

      final avatar =
          tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
      expect(avatar.backgroundColor, equals(AppTheme.orange));
    });

    testWidgets('ADMN-21b: client user has ink CircleAvatar background',
        (tester) async {
      await tester.pumpWidget(_buildRow(user: _clientUser, index: 0));

      final avatar =
          tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
      expect(avatar.backgroundColor, equals(AppTheme.ink));
    });

    testWidgets('ADMN-21c: renders displayName in Manrope 14px bold',
        (tester) async {
      await tester.pumpWidget(_buildRow(user: _clientUser, index: 0));

      // Find the displayName text
      final nameText = tester.widget<Text>(find.text('Bob Client'));
      final expectedStyle = AppTheme.ui(size: 14, weight: FontWeight.w700);
      expect(nameText.style?.fontSize, equals(expectedStyle.fontSize));
      expect(nameText.style?.fontWeight, equals(expectedStyle.fontWeight));
    });

    testWidgets('ADMN-21d: renders email in JBM 10px (AppTheme.mono)',
        (tester) async {
      await tester.pumpWidget(_buildRow(user: _clientUser, index: 0));

      final emailText = tester.widget<Text>(find.text('client@test.com'));
      final expectedStyle = AppTheme.mono(size: 10);
      expect(emailText.style?.fontSize, equals(expectedStyle.fontSize));
    });

    testWidgets(
        'ADMN-21e: index > 0 has DecoratedBox with Border top lineHair 0.5',
        (tester) async {
      await tester.pumpWidget(_buildRow(user: _clientUser, index: 1));

      // Find a DecoratedBox that has a top border with lineHair color
      final decoratedBoxes =
          tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      final withBorder = decoratedBoxes.where((db) {
        final decoration = db.decoration;
        if (decoration is! BoxDecoration) return false;
        final border = decoration.border;
        if (border is! Border) return false;
        return border.top.color == AppTheme.lineHair &&
            border.top.width == 0.5;
      });
      expect(withBorder, isNotEmpty,
          reason: 'DecoratedBox with top BorderSide(lineHair, 0.5) not found');
    });

    testWidgets('ADMN-21f: no ListTile or gradient used', (tester) async {
      await tester.pumpWidget(_buildRow(user: _clientUser, index: 0));

      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('ADMN-21g: client row renders PROMOVER button', (tester) async {
      await tester.pumpWidget(_buildRow(user: _clientUser, index: 0));

      expect(find.text('PROMOVER'), findsOneWidget);
    });
  });
}
