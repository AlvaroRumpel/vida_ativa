import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vida_ativa/core/models/user_model.dart';
import 'package:vida_ativa/features/auth/cubit/auth_cubit.dart';
import 'package:vida_ativa/features/auth/cubit/auth_state.dart';

// ─── Firebase Auth mocks ──────────────────────────────────────────────────────
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

// ─── Firestore fakes (sealed types → Fake, not Mock) ─────────────────────────
class _FakeSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic>? _data;
  _FakeSnapshot(this._id, [this._data]);
  @override
  String get id => _id;
  @override
  Map<String, dynamic>? data() => _data;
  @override
  bool get exists => _data != null;
}

class _FakeDocRef extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _FakeSnapshot _snap;
  _FakeDocRef(this._snap);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async => _snap;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _snap = _FakeSnapshot(_snap.id, data);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {}
}

class _FakeCollRef extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final Map<String, _FakeDocRef> _docs;
  _FakeCollRef(this._docs);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _docs[path] ?? _FakeDocRef(_FakeSnapshot(path ?? ''));
}

class _FakeFirestore extends Fake implements FirebaseFirestore {
  final Map<String, _FakeCollRef> _collections;
  _FakeFirestore(this._collections);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _collections[path] ?? _FakeCollRef({});
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
MockUser _makeUser({String uid = 'uid1'}) {
  final user = MockUser();
  when(() => user.uid).thenReturn(uid);
  when(() => user.email).thenReturn('test@example.com');
  when(() => user.displayName).thenReturn('Test User');
  return user;
}

_FakeFirestore _firestoreWithUser(String uid) {
  final docData = {
    'email': 'test@example.com',
    'displayName': 'Test User',
    'role': 'client',
  };
  return _FakeFirestore({
    'users': _FakeCollRef({uid: _FakeDocRef(_FakeSnapshot(uid, docData))}),
  });
}

_FakeFirestore _firestoreEmpty() =>
    _FakeFirestore({'users': _FakeCollRef({})});

// ─── Tests ────────────────────────────────────────────────────────────────────
void main() {
  late MockFirebaseAuth mockAuth;
  late StreamController<User?> authStream;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    authStream = StreamController<User?>.broadcast();
    when(() => mockAuth.authStateChanges())
        .thenAnswer((_) => authStream.stream);
  });

  tearDown(() => authStream.close());

  // ─── authStateChanges stream ───────────────────────────────────────────────
  group('authStateChanges', () {
    test('null → AuthUnauthenticated', () async {
      final cubit = AuthCubit(auth: mockAuth, firestore: _firestoreEmpty());
      authStream.add(null);
      await pumpEventQueue();
      expect(cubit.state, isA<AuthUnauthenticated>());
      await cubit.close();
    });

    test('user with existing Firestore doc → AuthAuthenticated', () async {
      final user = _makeUser();
      final cubit = AuthCubit(
        auth: mockAuth,
        firestore: _firestoreWithUser(user.uid),
      );
      authStream.add(user);
      await pumpEventQueue();
      final state = cubit.state as AuthAuthenticated;
      expect(state.user.uid, user.uid);
      expect(state.user.role, 'client');
      await cubit.close();
    });

    test('user with missing doc → creates doc + AuthAuthenticated', () async {
      final user = _makeUser(uid: 'new_uid');
      final cubit = AuthCubit(auth: mockAuth, firestore: _firestoreEmpty());
      authStream.add(user);
      await pumpEventQueue();
      expect(cubit.state, isA<AuthAuthenticated>());
      final state = cubit.state as AuthAuthenticated;
      expect(state.user.uid, 'new_uid');
      await cubit.close();
    });
  });

  // ─── signInWithEmailPassword ───────────────────────────────────────────────
  group('signInWithEmailPassword', () {
    blocTest<AuthCubit, AuthState>(
      'wrong-password → [AuthLoading, AuthError]',
      build: () {
        when(() => mockAuth.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(FirebaseAuthException(code: 'wrong-password'));
        return AuthCubit(auth: mockAuth, firestore: _firestoreEmpty());
      },
      act: (c) => c.signInWithEmailPassword('e@e.com', 'wrong'),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>()
            .having((s) => s.message, 'message', 'Senha incorreta.'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'user-not-found → [AuthLoading, AuthError]',
      build: () {
        when(() => mockAuth.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(FirebaseAuthException(code: 'user-not-found'));
        return AuthCubit(auth: mockAuth, firestore: _firestoreEmpty());
      },
      act: (c) => c.signInWithEmailPassword('e@e.com', 'pass'),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>()
            .having((s) => s.message, 'message', 'Email não encontrado.'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'invalid-credential → [AuthLoading, AuthError]',
      build: () {
        when(() => mockAuth.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(FirebaseAuthException(code: 'invalid-credential'));
        return AuthCubit(auth: mockAuth, firestore: _firestoreEmpty());
      },
      act: (c) => c.signInWithEmailPassword('e@e.com', 'pass'),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
            (s) => s.message, 'message', 'Email ou senha incorretos.'),
      ],
    );
  });

  // ─── registerWithEmailPassword ─────────────────────────────────────────────
  group('registerWithEmailPassword', () {
    blocTest<AuthCubit, AuthState>(
      'email-already-in-use → [AuthLoading, AuthError]',
      build: () {
        when(() => mockAuth.createUserWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
        return AuthCubit(auth: mockAuth, firestore: _firestoreEmpty());
      },
      act: (c) => c.registerWithEmailPassword(
        name: 'Ana',
        email: 'ana@example.com',
        password: '123456',
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>()
            .having((s) => s.message, 'message', 'Email já cadastrado.'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'weak-password → [AuthLoading, AuthError]',
      build: () {
        when(() => mockAuth.createUserWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(FirebaseAuthException(code: 'weak-password'));
        return AuthCubit(auth: mockAuth, firestore: _firestoreEmpty());
      },
      act: (c) => c.registerWithEmailPassword(
        name: 'Ana',
        email: 'ana@example.com',
        password: '123',
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having((s) => s.message, 'message',
            'Senha muito fraca (mínimo 6 caracteres).'),
      ],
    );
  });

  // ─── sendPasswordReset ─────────────────────────────────────────────────────
  group('sendPasswordReset', () {
    test('calls sendPasswordResetEmail on FirebaseAuth', () async {
      when(() => mockAuth.sendPasswordResetEmail(email: any(named: 'email')))
          .thenAnswer((_) async {});
      final cubit = AuthCubit(auth: mockAuth, firestore: _firestoreEmpty());
      await cubit.sendPasswordReset('user@example.com');
      verify(() =>
              mockAuth.sendPasswordResetEmail(email: 'user@example.com'))
          .called(1);
      await cubit.close();
    });
  });

  // ─── signOut ───────────────────────────────────────────────────────────────
  group('signOut', () {
    test('calls FirebaseAuth.signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
      final cubit = AuthCubit(auth: mockAuth, firestore: _firestoreEmpty());
      await cubit.signOut();
      verify(() => mockAuth.signOut()).called(1);
      await cubit.close();
    });
  });

  // ─── toggleViewMode ────────────────────────────────────────────────────────
  group('toggleViewMode', () {
    blocTest<AuthCubit, AuthState>(
      'admin user: admin → client',
      build: () => AuthCubit(auth: mockAuth, firestore: _firestoreEmpty()),
      seed: () => const AuthAuthenticated(
        UserModel(uid: 'u', email: 'e', displayName: 'd', role: 'admin'),
        viewMode: ViewMode.admin,
      ),
      act: (c) => c.toggleViewMode(),
      expect: () => [
        isA<AuthAuthenticated>()
            .having((s) => s.viewMode, 'viewMode', ViewMode.client),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'admin user: client → admin',
      build: () => AuthCubit(auth: mockAuth, firestore: _firestoreEmpty()),
      seed: () => const AuthAuthenticated(
        UserModel(uid: 'u', email: 'e', displayName: 'd', role: 'admin'),
        viewMode: ViewMode.client,
      ),
      act: (c) => c.toggleViewMode(),
      expect: () => [
        isA<AuthAuthenticated>()
            .having((s) => s.viewMode, 'viewMode', ViewMode.admin),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'non-admin user → no-op',
      build: () => AuthCubit(auth: mockAuth, firestore: _firestoreEmpty()),
      seed: () => const AuthAuthenticated(
        UserModel(uid: 'u', email: 'e', displayName: 'd', role: 'client'),
      ),
      act: (c) => c.toggleViewMode(),
      expect: () => [],
    );
  });
}
