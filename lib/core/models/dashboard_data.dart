import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class TopClientEntry extends Equatable {
  final String userId;
  final String displayName;
  final int bookingCount;

  const TopClientEntry({
    required this.userId,
    required this.displayName,
    required this.bookingCount,
  });

  factory TopClientEntry.fromMap(Map<String, dynamic> m) => TopClientEntry(
        userId: (m['userId'] as String?) ?? '',
        displayName: (m['displayName'] as String?) ?? '',
        bookingCount: (m['bookingCount'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [userId, displayName, bookingCount];
}

class RevenueBySportEntry extends Equatable {
  final String? sport; // null = "Não informado" (DASH-12)
  final double revenue;

  const RevenueBySportEntry({required this.sport, required this.revenue});

  factory RevenueBySportEntry.fromMap(Map<String, dynamic> m) =>
      RevenueBySportEntry(
        sport: m['sport'] as String?,
        revenue: (m['revenue'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  List<Object?> get props => [sport, revenue];
}

class DashboardData extends Equatable {
  // Identificação
  final String period;
  final String startDate;
  final String endDate;
  final DateTime? updatedAt;

  // Contadores simples (mantidos por onBookingStateChange)
  final int totalBookings;
  final int confirmedBookings;
  final int cancelledBookings;
  final int pendingBookings;
  final int totalSlotsBooked;
  final double totalRevenue;
  final double pixRevenue;
  final double onArrivalRevenue;

  // Calculados pelo scheduledDailyAggregation — NULLABLE
  final int? totalSlotsAvailable;
  final double? occupancyRate;
  final double? avgTicket;
  final double? conversionRate;
  final double? noShowRate;
  final int? uniqueClients;
  final int? newClients;
  final double? returnRate;
  final List<TopClientEntry>? topClients;
  final List<RevenueBySportEntry>? revenueBySport;

  // Trend arrays para sparklines (7 pontos diários) — ADMN-30
  final List<double>? occupancyTrend;
  final List<double>? revenueTrend;
  final List<double>? avgTicketTrend;
  final List<double>? conversionTrend;
  final List<double>? noShowTrend;

  const DashboardData({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.updatedAt,
    required this.totalBookings,
    required this.confirmedBookings,
    required this.cancelledBookings,
    required this.pendingBookings,
    required this.totalSlotsBooked,
    required this.totalRevenue,
    required this.pixRevenue,
    required this.onArrivalRevenue,
    required this.totalSlotsAvailable,
    required this.occupancyRate,
    required this.avgTicket,
    required this.conversionRate,
    required this.noShowRate,
    required this.uniqueClients,
    required this.newClients,
    required this.returnRate,
    required this.topClients,
    required this.revenueBySport,
    this.occupancyTrend,
    this.revenueTrend,
    this.avgTicketTrend,
    this.conversionTrend,
    this.noShowTrend,
  });

  factory DashboardData.empty(String period) => DashboardData(
        period: period,
        startDate: '',
        endDate: '',
        updatedAt: null,
        totalBookings: 0,
        confirmedBookings: 0,
        cancelledBookings: 0,
        pendingBookings: 0,
        totalSlotsBooked: 0,
        totalRevenue: 0.0,
        pixRevenue: 0.0,
        onArrivalRevenue: 0.0,
        totalSlotsAvailable: null,
        occupancyRate: null,
        avgTicket: null,
        conversionRate: null,
        noShowRate: null,
        uniqueClients: null,
        newClients: null,
        returnRate: null,
        topClients: null,
        revenueBySport: null,
      );

  factory DashboardData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return DashboardData.empty('');
    final updatedAtRaw = map['updatedAt'];
    final topClientsRaw = map['topClients'] as List<dynamic>?;
    final revenueBySportRaw = map['revenueBySport'] as List<dynamic>?;
    return DashboardData(
      period: (map['period'] as String?) ?? '',
      startDate: (map['startDate'] as String?) ?? '',
      endDate: (map['endDate'] as String?) ?? '',
      updatedAt: updatedAtRaw is Timestamp ? updatedAtRaw.toDate() : null,
      totalBookings: (map['totalBookings'] as num?)?.toInt() ?? 0,
      confirmedBookings: (map['confirmedBookings'] as num?)?.toInt() ?? 0,
      cancelledBookings: (map['cancelledBookings'] as num?)?.toInt() ?? 0,
      pendingBookings: (map['pendingBookings'] as num?)?.toInt() ?? 0,
      totalSlotsBooked: (map['totalSlotsBooked'] as num?)?.toInt() ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      pixRevenue: (map['pixRevenue'] as num?)?.toDouble() ?? 0.0,
      onArrivalRevenue: (map['onArrivalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalSlotsAvailable: (map['totalSlotsAvailable'] as num?)?.toInt(),
      occupancyRate: (map['occupancyRate'] as num?)?.toDouble(),
      avgTicket: (map['avgTicket'] as num?)?.toDouble(),
      conversionRate: (map['conversionRate'] as num?)?.toDouble(),
      noShowRate: (map['noShowRate'] as num?)?.toDouble(),
      uniqueClients: (map['uniqueClients'] as num?)?.toInt(),
      newClients: (map['newClients'] as num?)?.toInt(),
      returnRate: (map['returnRate'] as num?)?.toDouble(),
      topClients: topClientsRaw
          ?.map((e) => TopClientEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
      revenueBySport: revenueBySportRaw
          ?.map((e) => RevenueBySportEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
      occupancyTrend: (map['occupancyTrend'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble()).toList(),
      revenueTrend: (map['revenueTrend'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble()).toList(),
      avgTicketTrend: (map['avgTicketTrend'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble()).toList(),
      conversionTrend: (map['conversionTrend'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble()).toList(),
      noShowTrend: (map['noShowTrend'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble()).toList(),
    );
  }

  @override
  List<Object?> get props => [
        period,
        startDate,
        endDate,
        updatedAt,
        totalBookings,
        confirmedBookings,
        cancelledBookings,
        pendingBookings,
        totalSlotsBooked,
        totalRevenue,
        pixRevenue,
        onArrivalRevenue,
        totalSlotsAvailable,
        occupancyRate,
        avgTicket,
        conversionRate,
        noShowRate,
        uniqueClients,
        newClients,
        returnRate,
        topClients,
        revenueBySport,
        occupancyTrend,
        revenueTrend,
        avgTicketTrend,
        conversionTrend,
        noShowTrend,
      ];
}
