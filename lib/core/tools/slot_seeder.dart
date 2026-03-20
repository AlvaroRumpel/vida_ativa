// DEV TOOL — Remove or keep behind kDebugMode after seeding.
//
// Usage: call SlotSeeder.seed() once from main() or a debug button.
// Creates hourly slots from 08:00 to 23:00 for every day of the week.
//
// To run:
//   1. Add `await SlotSeeder.seed();` to main() before runApp(), OR
//   2. Call from a temporary debug button in the app.
//   3. Check Firestore console — 112 documents created in /slots.
//   4. Remove the call (keep this file or delete it).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SlotSeeder {
  // Horários das 08:00 às 23:00 (16 slots por dia)
  static const _hours = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
    '22:00',
    '23:00',
  ];

  // Preço padrão — altere conforme necessário
  static const double _defaultPrice = 60.0;

  /// Seeds /slots with hourly slots Mon–Sun, 08:00–23:00.
  /// Safe to call multiple times — uses set() with merge:false on fixed IDs.
  static Future<void> seed() async {
    assert(kDebugMode, 'SlotSeeder must only run in debug mode');

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    int count = 0;

    // dayOfWeek: 1=Seg, 2=Ter, 3=Qua, 4=Qui, 5=Sex, 6=Sáb, 7=Dom
    for (int day = 1; day <= 7; day++) {
      for (final time in _hours) {
        final id = 'slot_d${day}_${time.replaceAll(':', '')}';
        final ref = firestore.collection('slots').doc(id);
        batch.set(ref, {
          'dayOfWeek': day,
          'startTime': time,
          'price': _defaultPrice,
          'isActive': true,
        });
        count++;
      }
    }

    await batch.commit();
    debugPrint('SlotSeeder: $count slots criados em /slots');
  }

  /// Deletes all seeded slots (cleanup).
  static Future<void> clear() async {
    assert(kDebugMode, 'SlotSeeder must only run in debug mode');

    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('slots').get();
    final batch = firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    debugPrint('SlotSeeder: ${snapshot.docs.length} slots removidos');
  }
}
