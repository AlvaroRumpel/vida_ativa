import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vida_ativa/core/models/dashboard_data.dart';

void main() {
  group('DashboardData.fromMap', () {
    test('fromMap(null) returns zeroed instance with nullable calculated fields null', () {
      final d = DashboardData.fromMap(null);
      expect(d.period, '');
      expect(d.startDate, '');
      expect(d.endDate, '');
      expect(d.updatedAt, isNull);
      expect(d.totalBookings, 0);
      expect(d.confirmedBookings, 0);
      expect(d.cancelledBookings, 0);
      expect(d.pendingBookings, 0);
      expect(d.totalSlotsBooked, 0);
      expect(d.totalRevenue, 0.0);
      expect(d.pixRevenue, 0.0);
      expect(d.onArrivalRevenue, 0.0);
      expect(d.totalSlotsAvailable, isNull);
      expect(d.occupancyRate, isNull);
      expect(d.avgTicket, isNull);
      expect(d.conversionRate, isNull);
      expect(d.noShowRate, isNull);
      expect(d.uniqueClients, isNull);
      expect(d.newClients, isNull);
      expect(d.returnRate, isNull);
      expect(d.topClients, isNull);
      expect(d.revenueBySport, isNull);
    });

    test('fromMap({}) empty map has same zeroed behavior as null', () {
      final d = DashboardData.fromMap({});
      expect(d.period, '');
      expect(d.startDate, '');
      expect(d.endDate, '');
      expect(d.updatedAt, isNull);
      expect(d.totalBookings, 0);
      expect(d.totalRevenue, 0.0);
      expect(d.totalSlotsAvailable, isNull);
      expect(d.occupancyRate, isNull);
      expect(d.topClients, isNull);
      expect(d.revenueBySport, isNull);
    });

    test('fromMap parses all fields when present', () {
      final ts = Timestamp.fromDate(DateTime.utc(2026, 5, 20, 6, 0));
      final d = DashboardData.fromMap({
        'period': 'week',
        'startDate': '2026-05-19',
        'endDate': '2026-05-25',
        'updatedAt': ts,
        'totalBookings': 10,
        'confirmedBookings': 8,
        'cancelledBookings': 2,
        'pendingBookings': 0,
        'totalSlotsBooked': 8,
        'totalRevenue': 800.0,
        'pixRevenue': 500.0,
        'onArrivalRevenue': 300.0,
        'totalSlotsAvailable': 20,
        'occupancyRate': 0.4,
        'avgTicket': 100.0,
        'conversionRate': 0.8,
        'noShowRate': 0.1,
        'uniqueClients': 5,
        'newClients': 2,
        'returnRate': 0.6,
        'topClients': [
          {'userId': 'u1', 'displayName': 'João', 'bookingCount': 5},
        ],
        'revenueBySport': [
          {'sport': 'Vôlei', 'revenue': 200.0},
          {'sport': null, 'revenue': 100.0},
        ],
      });
      expect(d.period, 'week');
      expect(d.startDate, '2026-05-19');
      expect(d.endDate, '2026-05-25');
      expect(d.updatedAt, ts.toDate());
      expect(d.totalBookings, 10);
      expect(d.confirmedBookings, 8);
      expect(d.cancelledBookings, 2);
      expect(d.pendingBookings, 0);
      expect(d.totalSlotsBooked, 8);
      expect(d.totalRevenue, 800.0);
      expect(d.pixRevenue, 500.0);
      expect(d.onArrivalRevenue, 300.0);
      expect(d.totalSlotsAvailable, 20);
      expect(d.occupancyRate, 0.4);
      expect(d.avgTicket, 100.0);
      expect(d.conversionRate, 0.8);
      expect(d.noShowRate, 0.1);
      expect(d.uniqueClients, 5);
      expect(d.newClients, 2);
      expect(d.returnRate, 0.6);
      expect(d.topClients, hasLength(1));
      expect(d.topClients!.first.userId, 'u1');
      expect(d.topClients!.first.displayName, 'João');
      expect(d.topClients!.first.bookingCount, 5);
      expect(d.revenueBySport, hasLength(2));
      expect(d.revenueBySport![0].sport, 'Vôlei');
      expect(d.revenueBySport![0].revenue, 200.0);
      expect(d.revenueBySport![1].sport, isNull);
      expect(d.revenueBySport![1].revenue, 100.0);
    });

    test('topClients parses list and handles empty list', () {
      final d1 = DashboardData.fromMap({
        'topClients': [
          {'userId': 'u1', 'displayName': 'João', 'bookingCount': 5},
        ],
      });
      expect(d1.topClients, hasLength(1));
      expect(d1.topClients!.first.userId, 'u1');
      expect(d1.topClients!.first.displayName, 'João');
      expect(d1.topClients!.first.bookingCount, 5);

      final d2 = DashboardData.fromMap({'topClients': []});
      expect(d2.topClients, isEmpty);
    });

    test('revenueBySport handles null sport entry (DASH-12)', () {
      final d = DashboardData.fromMap({
        'revenueBySport': [
          {'sport': 'Vôlei', 'revenue': 200.0},
          {'sport': null, 'revenue': 100.0},
        ],
      });
      expect(d.revenueBySport, hasLength(2));
      expect(d.revenueBySport![1].sport, isNull);
      expect(d.revenueBySport![1].revenue, 100.0);
    });

    test('map with only simple counters has calculated fields null', () {
      final d = DashboardData.fromMap({
        'period': 'week',
        'totalBookings': 5,
        'confirmedBookings': 4,
        'totalRevenue': 400.0,
        // no calculated fields — simulates first run before scheduled
      });
      expect(d.totalBookings, 5);
      expect(d.confirmedBookings, 4);
      expect(d.totalRevenue, 400.0);
      expect(d.totalSlotsAvailable, isNull);
      expect(d.occupancyRate, isNull);
      expect(d.avgTicket, isNull);
      expect(d.conversionRate, isNull);
      expect(d.noShowRate, isNull);
      expect(d.uniqueClients, isNull);
      expect(d.newClients, isNull);
      expect(d.returnRate, isNull);
      expect(d.topClients, isNull);
      expect(d.revenueBySport, isNull);
    });

    test('updatedAt parsed from Timestamp when present, null when absent', () {
      final ts = Timestamp.fromDate(DateTime.utc(2026, 5, 20));
      final withTs = DashboardData.fromMap({'updatedAt': ts});
      expect(withTs.updatedAt, ts.toDate());

      final withoutTs = DashboardData.fromMap({'totalBookings': 1});
      expect(withoutTs.updatedAt, isNull);
    });

    test('Equatable — two instances with same fields are equal', () {
      final d1 = DashboardData.fromMap({
        'period': 'week',
        'totalBookings': 10,
        'totalRevenue': 800.0,
      });
      final d2 = DashboardData.fromMap({
        'period': 'week',
        'totalBookings': 10,
        'totalRevenue': 800.0,
      });
      expect(d1, equals(d2));
    });
  });

  group('TopClientEntry', () {
    test('fromMap parses userId, displayName, bookingCount', () {
      final entry = TopClientEntry.fromMap({
        'userId': 'user123',
        'displayName': 'Maria Silva',
        'bookingCount': 7,
      });
      expect(entry.userId, 'user123');
      expect(entry.displayName, 'Maria Silva');
      expect(entry.bookingCount, 7);
    });

    test('fromMap handles missing fields with defaults', () {
      final entry = TopClientEntry.fromMap({});
      expect(entry.userId, '');
      expect(entry.displayName, '');
      expect(entry.bookingCount, 0);
    });
  });

  group('RevenueBySportEntry', () {
    test('fromMap parses sport and revenue', () {
      final entry = RevenueBySportEntry.fromMap({
        'sport': 'Beach Tênis',
        'revenue': 350.0,
      });
      expect(entry.sport, 'Beach Tênis');
      expect(entry.revenue, 350.0);
    });

    test('fromMap preserves null sport for unknown sport (DASH-12)', () {
      final entry = RevenueBySportEntry.fromMap({
        'sport': null,
        'revenue': 150.0,
      });
      expect(entry.sport, isNull);
      expect(entry.revenue, 150.0);
    });
  });
}
