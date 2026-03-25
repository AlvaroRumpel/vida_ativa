import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:vida_ativa/core/models/user_model.dart';
import 'package:vida_ativa/features/auth/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  late final StreamSubscription<User?> _authSubscription;

  AuthCubit({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(const AuthInitial()) {
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      emit(const AuthUnauthenticated());
      return;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists) {
        emit(AuthAuthenticated(UserModel.fromFirestore(doc)));
      } else {
        // Fallback: create doc if missing (race condition guard)
        final user = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? '',
          role: 'client',
        );
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(user.toFirestore());
        emit(AuthAuthenticated(user));
      }
    } catch (e) {
      emit(AuthError('Erro ao carregar dados do usuário.'));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    try {
      final credential = await _auth.signInWithPopup(GoogleAuthProvider());
      final firebaseUser = credential.user!;

      final docRef = _firestore.collection('users').doc(firebaseUser.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        final user = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? '',
          role: 'client',
        );
        await docRef.set(user.toFirestore());
      }
      // authStateChanges will fire and emit AuthAuthenticated
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapEmailError(e.code)));
    } catch (e) {
      emit(AuthError('Erro de autenticação. Tente novamente.'));
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    emit(const AuthLoading());
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // authStateChanges will fire and emit AuthAuthenticated
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapEmailError(e.code)));
    } catch (e) {
      emit(AuthError('Erro de autenticação. Tente novamente.'));
    }
  }

  Future<void> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    emit(const AuthLoading());
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user!;
      await firebaseUser.updateDisplayName(name);

      final user = UserModel(
        uid: firebaseUser.uid,
        email: email,
        displayName: name,
        role: 'client',
        phone: phone,
      );
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toFirestore());
      // authStateChanges will fire and emit AuthAuthenticated
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapEmailError(e.code)));
    } catch (e) {
      emit(AuthError('Erro ao criar conta. Tente novamente.'));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updatePhone(String? phone) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    final uid = currentState.user.uid;
    await _firestore.collection('users').doc(uid).update({
      'phone': phone ?? FieldValue.delete(),
    });

    // Re-read user doc to update state, preserving viewMode
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      emit(AuthAuthenticated(
        UserModel.fromFirestore(doc),
        viewMode: currentState.viewMode,
      ));
    }
  }

  void toggleViewMode() {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;
    if (!currentState.user.isAdmin) return;

    final newMode = currentState.viewMode == ViewMode.admin
        ? ViewMode.client
        : ViewMode.admin;
    emit(AuthAuthenticated(currentState.user, viewMode: newMode));
  }

  Future<void> promoteUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'role': 'admin',
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // authStateChanges will fire null and emit AuthUnauthenticated
  }

  String _mapEmailError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Email já cadastrado.';
      case 'weak-password':
        return 'Senha muito fraca (mínimo 6 caracteres).';
      case 'invalid-email':
        return 'Email inválido.';
      case 'invalid-credential':
        return 'Email ou senha incorretos.';
      default:
        return 'Erro de autenticação. Tente novamente.';
    }
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
