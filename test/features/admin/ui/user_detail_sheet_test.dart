import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vida_ativa/core/models/user_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/admin/ui/user_detail_sheet.dart';
import 'package:vida_ativa/features/auth/cubit/auth_cubit.dart';
import 'package:vida_ativa/features/auth/cubit/auth_state.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

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

Widget _buildSheet({required UserModel user}) {
  final mockAuthCubit = MockAuthCubit();
  when(() => mockAuthCubit.state).thenReturn(
    AuthAuthenticated(
      const UserModel(
        uid: 'current-admin',
        email: 'me@test.com',
        displayName: 'Me Admin',
        role: 'admin',
      ),
    ),
  );
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<AuthCubit>.value(
        value: mockAuthCubit,
        child: UserDetailSheet(user: user),
      ),
    ),
  );
}

void main() {
  group('UserDetailSheet', () {
    testWidgets('ADMN-20a: admin user has orange CircleAvatar background',
        (tester) async {
      await tester.pumpWidget(_buildSheet(user: _adminUser));

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
      expect(avatar.backgroundColor, equals(AppTheme.orange));
    });

    testWidgets('ADMN-20b: client user has ink CircleAvatar background',
        (tester) async {
      await tester.pumpWidget(_buildSheet(user: _clientUser));

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
      expect(avatar.backgroundColor, equals(AppTheme.ink));
    });

    testWidgets(
        'ADMN-20c: CircleAvatar renders Text with first letter of displayName uppercased',
        (tester) async {
      await tester.pumpWidget(_buildSheet(user: _clientUser));

      // 'Bob Client' -> 'B'
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('ADMN-20d: Avatar text uses AppTheme.display(size: 32, color: paper)',
        (tester) async {
      await tester.pumpWidget(_buildSheet(user: _clientUser));

      final textWidget = tester.widget<Text>(find.text('B'));
      final expectedStyle = AppTheme.display(size: 32, color: AppTheme.paper);
      expect(textWidget.style?.color, equals(expectedStyle.color));
      expect(textWidget.style?.fontSize, equals(expectedStyle.fontSize));
    });

    testWidgets('ADMN-20e: client user renders PROMOVER A ADMIN button',
        (tester) async {
      await tester.pumpWidget(_buildSheet(user: _clientUser));

      expect(find.text('PROMOVER A ADMIN'), findsOneWidget);
    });

    testWidgets('ADMN-20f: admin user renders REMOVER ADMIN button',
        (tester) async {
      await tester.pumpWidget(_buildSheet(user: _adminUser));

      expect(find.text('REMOVER ADMIN'), findsOneWidget);
    });

    testWidgets('ADMN-20g: drag handle container is 32 wide and 4 tall',
        (tester) async {
      await tester.pumpWidget(_buildSheet(user: _clientUser));

      // Find a Container with exact width=32 height=4 (drag handle)
      final containers = tester.widgetList<Container>(find.byType(Container));
      final dragHandle = containers.where((c) {
        final constraints = c.constraints;
        return constraints != null &&
            constraints.minWidth == 32 &&
            constraints.maxWidth == 32 &&
            constraints.minHeight == 4 &&
            constraints.maxHeight == 4;
      });
      expect(dragHandle, isNotEmpty,
          reason: 'Drag handle Container(width:32, height:4) not found');
    });
  });
}
