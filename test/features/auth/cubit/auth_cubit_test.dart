import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vida_ativa/features/auth/cubit/auth_cubit.dart';
import 'package:vida_ativa/features/auth/cubit/auth_state.dart';

// Manual mock classes for Firebase dependencies
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

// DocumentReference, DocumentSnapshot, CollectionReference are sealed in
// cloud_firestore — use Fake subclasses instead of Mock implements
class FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {}

class FakeDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {}

class FakeCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {}

void main() {
  group('signInWithGoogle', () {
    test('emits [AuthLoading] then AuthAuthenticated on success', () {
      // TODO: implement
    });

    test('creates Firestore doc on first login', () {
      // TODO: implement
    });

    test('does not overwrite existing Firestore doc', () {
      // TODO: implement
    });
  });

  group('signInWithEmailPassword', () {
    test('emits AuthAuthenticated on valid credentials', () {
      // TODO: implement
    });

    test('emits AuthError with Portuguese message on wrong-password', () {
      // TODO: implement
    });

    test('emits AuthError on user-not-found', () {
      // TODO: implement
    });
  });

  group('registerWithEmailPassword', () {
    test('creates Firebase Auth user + Firestore doc', () {
      // TODO: implement
    });

    test('emits AuthError on email-already-in-use', () {
      // TODO: implement
    });
  });

  group('sendPasswordReset', () {
    test('calls sendPasswordResetEmail on FirebaseAuth', () {
      // TODO: implement
    });
  });

  group('authStateChanges', () {
    test('emits AuthAuthenticated when stream fires with cached user', () {
      // TODO: implement
    });

    test('emits AuthUnauthenticated when stream fires null', () {
      // TODO: implement
    });
  });

  group('signOut', () {
    test('calls FirebaseAuth.signOut', () {
      // TODO: implement
    });
  });
}
