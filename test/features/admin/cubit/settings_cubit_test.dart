import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vida_ativa/features/admin/cubit/settings_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/settings_state.dart';

// Firestore returns sealed generics — use Fake, not Mock
class FakeDocSnap extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? _data;
  FakeDocSnap(this._data);

  @override
  Map<String, dynamic>? data() => _data;
}

class _FakeDocRef extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final Map<String, dynamic>? snapData;
  final List<Map<String, dynamic>> writes;

  _FakeDocRef({this.snapData, required this.writes});

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async =>
      FakeDocSnap(snapData);

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async =>
      writes.add(data);
}

class _FakeCollRef extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final Map<String, _FakeDocRef> docs;
  _FakeCollRef(this.docs);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => docs[path]!;
}

class _FakeFirestore extends Fake implements FirebaseFirestore {
  final Map<String, _FakeCollRef> collections;
  _FakeFirestore(this.collections);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      collections[path]!;
}

/// Builds a FakeFirestore pre-wired with MP and booking config data.
_FakeFirestore _buildFirestore({
  Map<String, dynamic>? mpData,
  Map<String, dynamic>? bookingData,
  List<Map<String, dynamic>>? mpWrites,
}) {
  final writes = mpWrites ?? [];
  return _FakeFirestore({
    'config': _FakeCollRef({
      'mercadopago': _FakeDocRef(snapData: mpData, writes: writes),
      'booking': _FakeDocRef(snapData: bookingData, writes: []),
    }),
  });
}

void main() {
  group('SettingsCubit._loadSettings', () {
    blocTest<SettingsCubit, SettingsState>(
      'isAccessTokenConfigured true when accessToken non-empty',
      build: () => SettingsCubit(
        firestore: _buildFirestore(
          mpData: {'accessToken': 'tok_abc', 'webhookSecret': 'sec_xyz'},
          bookingData: {'pixEnabled': true},
        ),
      ),
      expect: () => [
        isA<SettingsLoaded>()
            .having((s) => s.isAccessTokenConfigured, 'isAccessTokenConfigured', isTrue)
            .having((s) => s.isWebhookSecretConfigured, 'isWebhookSecretConfigured', isTrue)
            .having((s) => s.pixEnabled, 'pixEnabled', isTrue),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'isAccessTokenConfigured false when accessToken empty string',
      build: () => SettingsCubit(
        firestore: _buildFirestore(
          mpData: {'accessToken': '', 'webhookSecret': ''},
          bookingData: {'pixEnabled': false},
        ),
      ),
      expect: () => [
        isA<SettingsLoaded>()
            .having((s) => s.isAccessTokenConfigured, 'isAccessTokenConfigured', isFalse)
            .having((s) => s.isWebhookSecretConfigured, 'isWebhookSecretConfigured', isFalse)
            .having((s) => s.pixEnabled, 'pixEnabled', isFalse),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'isAccessTokenConfigured false when MP doc is null (not configured)',
      build: () => SettingsCubit(
        firestore: _buildFirestore(
          mpData: null, // doc exists but empty
          bookingData: {'pixEnabled': true},
        ),
      ),
      expect: () => [
        isA<SettingsLoaded>()
            .having((s) => s.isAccessTokenConfigured, 'isAccessTokenConfigured', isFalse),
      ],
    );

    // Security invariant: SettingsLoaded only contains bool fields — token
    // value can never leak into Flutter state by design.
    blocTest<SettingsCubit, SettingsState>(
      'SettingsLoaded contains only bool fields — token value never in state',
      build: () => SettingsCubit(
        firestore: _buildFirestore(
          mpData: {'accessToken': 'SUPER_SECRET_TOKEN'},
          bookingData: {'pixEnabled': true},
        ),
      ),
      expect: () => [
        isA<SettingsLoaded>().having(
          (s) => [s.isAccessTokenConfigured, s.isWebhookSecretConfigured, s.pixEnabled]
              .every((v) => v is bool),
          'all fields are bools',
          isTrue,
        ),
      ],
    );
  });

  group('SettingsCubit.saveCredentials', () {
    test('writes only non-empty fields (empty webhookSecret is skipped)', () async {
      final writes = <Map<String, dynamic>>[];
      final cubit = SettingsCubit(
        firestore: _buildFirestore(
          mpData: {'accessToken': 'existing'},
          bookingData: {'pixEnabled': true},
          mpWrites: writes,
        ),
      );
      await Future.delayed(Duration.zero); // let constructor async settle

      await cubit.saveCredentials(accessToken: 'newtoken', webhookSecret: '');

      expect(writes.length, 1);
      expect(writes.first.containsKey('accessToken'), isTrue);
      expect(writes.first.containsKey('webhookSecret'), isFalse);
    });

    test('noop — no Firestore write when both fields are empty', () async {
      final writes = <Map<String, dynamic>>[];
      final cubit = SettingsCubit(
        firestore: _buildFirestore(
          mpData: null,
          bookingData: {'pixEnabled': true},
          mpWrites: writes,
        ),
      );
      await Future.delayed(Duration.zero);

      await cubit.saveCredentials(accessToken: '', webhookSecret: '');

      expect(writes, isEmpty);
    });
  });
}
