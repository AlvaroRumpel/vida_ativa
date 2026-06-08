import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vida_ativa/core/models/payment_record_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';

/// Dedicated screen to display Pix QR code after booking.
///
/// Used in two flows:
///   1. Post-booking (from BookingConfirmationSheet): receives bookingId,
///      calls createPixPayment CF, displays QR immediately.
///   2. Card tap (from MyBookingsScreen): receives bookingId + paymentId,
///      reads existing PaymentRecord from subcollection.
///
/// On exit, navigates to MyBookingsScreen ('/bookings').
class PixPaymentScreen extends StatefulWidget {
  final String bookingId;

  /// If provided, screen loads PaymentRecord from subcollection using this txId.
  /// If null, screen calls createPixPayment CF to generate a new QR.
  final String? paymentId;

  const PixPaymentScreen({
    super.key,
    required this.bookingId,
    this.paymentId,
  });

  @override
  State<PixPaymentScreen> createState() => _PixPaymentScreenState();
}

class _PixPaymentScreenState extends State<PixPaymentScreen> {
  bool _isLoading = true;
  String? _error;
  String? _qrCode;
  String? _qrCodeBase64;
  DateTime? _expiresAt;
  bool _copied = false;
  bool _qrExpired = false;

  // Real-time booking listener
  StreamSubscription<DocumentSnapshot>? _bookingSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.paymentId != null) {
      _loadFromSubcollection();
    } else {
      _generateQr();
    }
    _startBookingListener();
  }

  @override
  void dispose() {
    _bookingSubscription?.cancel();
    super.dispose();
  }

  void _startBookingListener() {
    _bookingSubscription?.cancel();
    _bookingSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final data = snap.data();
      if (data == null) return;
      final status = data['status'] as String?;
      if (status == 'confirmed') {
        _bookingSubscription?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pagamento confirmado! Reserva garantida.'),
            duration: Duration(seconds: 2),
          ),
        );
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        context.go('/bookings');
      } else if (status == 'expired') {
        if (!_qrExpired) {
          setState(() => _qrExpired = true);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pagamento expirado. Gere novo QR.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  /// Called on initial flow: invokes createPixPayment CF.
  Future<void> _generateQr() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _qrExpired = false;
    });
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('createPixPayment');
      final result = await callable.call({'bookingId': widget.bookingId});
      final data = result.data as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _qrCode = data['qrCode'] as String;
        _qrCodeBase64 = data['qrCodeBase64'] as String;
        _expiresAt = DateTime.parse(data['expiresAt'] as String);
        _isLoading = false;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message ?? 'Erro ao gerar QR. Tente novamente.';
        _isLoading = false;
      });
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      if (!mounted) return;
      setState(() {
        _error = 'Erro inesperado. Tente novamente.';
        _isLoading = false;
      });
    }
  }

  /// Called when tapping pending_payment card: reads existing PaymentRecord.
  Future<void> _loadFromSubcollection() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .collection('payment')
          .doc(widget.paymentId)
          .withConverter<PaymentRecordModel>(
            fromFirestore: (s, _) => PaymentRecordModel.fromFirestore(s),
            toFirestore: (value, options) => {},
          )
          .get();

      if (!snap.exists || snap.data() == null) {
        if (!mounted) return;
        setState(() {
          _error = 'QR code nao encontrado. Contate o suporte.';
          _isLoading = false;
        });
        return;
      }

      final record = snap.data()!;
      if (!mounted) return;
      setState(() {
        _qrCode = record.qrCode;
        _qrCodeBase64 = record.qrCodeBase64;
        _expiresAt = record.expiresAt;
        _isLoading = false;
      });
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao carregar QR. Tente novamente.';
        _isLoading = false;
      });
    }
  }

  Future<void> _copyCode() async {
    if (_qrCode == null) return;
    await Clipboard.setData(ClipboardData(text: _qrCode!));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento Pix'),
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : _buildQrContent(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Gerando QR...',
            style: AppTheme.ui(size: 16, color: AppTheme.concrete),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.orangeDk),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTheme.ui(size: 16),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: widget.paymentId != null
                  ? _loadFromSubcollection
                  : _generateQr,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Text(
            'Escaneie o QR code com seu app de banco',
            textAlign: TextAlign.center,
            style: AppTheme.ui(size: 16, weight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          // QR image — never rebuilds on countdown ticks (countdown is isolated)
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.paper,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.memory(
                  base64Decode(_qrCodeBase64!),
                  width: 240,
                  height: 240,
                  fit: BoxFit.contain,
                ),
              ),
              if (_qrExpired)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.ink.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Countdown isolated in its own StatefulWidget — no parent rebuild on tick
          _PixCountdown(
            key: ValueKey(_expiresAt),
            expiresAt: _expiresAt!,
            onExpired: () {
              if (!_qrExpired && mounted) {
                setState(() => _qrExpired = true);
              }
            },
            onRegenerate: _generateQr,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ou use o codigo',
                  style: AppTheme.ui(size: 13, color: AppTheme.concrete),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.paper,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _qrCode!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.mono(size: 12, color: AppTheme.ink),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _copyCode,
              icon: Icon(
                _copied ? Icons.check : Icons.copy,
                size: 18,
              ),
              label: Text(_copied ? 'Copiado' : 'Copiar codigo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.orange,
                side: BorderSide(
                  color: _copied
                      ? AppTheme.orange
                      : AppTheme.orange.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.sand,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.orange, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppTheme.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Apos pagar, sua reserva sera confirmada automaticamente.',
                    style: AppTheme.ui(size: 12, color: AppTheme.orange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Countdown widget isolated so only it rebuilds every second, not the QR image.
class _PixCountdown extends StatefulWidget {
  const _PixCountdown({
    super.key,
    required this.expiresAt,
    required this.onExpired,
    required this.onRegenerate,
  });

  final DateTime expiresAt;
  final VoidCallback onExpired;
  final VoidCallback onRegenerate;

  @override
  State<_PixCountdown> createState() => _PixCountdownState();
}

class _PixCountdownState extends State<_PixCountdown> {
  late Duration _remaining;
  bool _expired = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final remaining = widget.expiresAt.difference(DateTime.now());
    _remaining = remaining <= Duration.zero ? Duration.zero : remaining;
    _expired = remaining <= Duration.zero;
    if (!_expired) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    if (!mounted) return;
    final remaining = widget.expiresAt.difference(DateTime.now());
    final expired = remaining <= Duration.zero;
    setState(() {
      _remaining = expired ? Duration.zero : remaining;
      _expired = expired;
    });
    if (expired) {
      _timer?.cancel();
      _timer = null;
      widget.onExpired();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_expired) {
      return Column(
        children: [
          Text(
            'QR expirado. Gere um novo acima.',
            style: AppTheme.ui(size: 14, color: AppTheme.orangeDk)
                .copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: widget.onRegenerate,
              icon: const Icon(Icons.refresh),
              label: const Text('Gerar novo QR'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.orange,
                foregroundColor: AppTheme.paper,
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      );
    }

    final minutes =
        _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final isUrgent = _remaining.inSeconds < 120;

    return Text(
      '$minutes:$seconds restantes',
      style: AppTheme.display(
        size: 24,
        color: isUrgent ? AppTheme.orangeDk : AppTheme.court,
      ),
    );
  }
}
