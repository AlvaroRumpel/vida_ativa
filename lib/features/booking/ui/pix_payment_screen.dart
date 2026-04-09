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

  // Countdown timer state
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
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
    _countdownTimer?.cancel();
    _bookingSubscription?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (_expiresAt == null) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = _expiresAt!.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        _countdownTimer?.cancel();
        setState(() {
          _remaining = Duration.zero;
          _qrExpired = true;
        });
      } else {
        setState(() {
          _remaining = remaining;
          _qrExpired = false;
        });
      }
    });
    // Trigger first tick immediately so display appears without 1s delay
    final remaining = _expiresAt!.difference(DateTime.now());
    setState(() {
      _remaining = remaining <= Duration.zero ? Duration.zero : remaining;
      _qrExpired = remaining <= Duration.zero;
    });
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
        _countdownTimer?.cancel();
        _bookingSubscription?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pagamento confirmado! Reserva garantida.'),
            duration: Duration(seconds: 2),
          ),
        );
        context.go('/bookings');
      } else if (status == 'expired') {
        _countdownTimer?.cancel();
        if (!_qrExpired) {
          setState(() {
            _qrExpired = true;
            _remaining = Duration.zero;
          });
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
      _startCountdown();
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
      _startCountdown();
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

  Widget _buildCountdown() {
    if (_qrExpired) {
      return Column(
        children: [
          const Text(
            'QR expirado. Gere um novo acima.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFC62828),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _generateQr,
              icon: const Icon(Icons.refresh),
              label: const Text('Gerar novo QR'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: isUrgent ? const Color(0xFFC62828) : AppTheme.primaryGreen,
      ),
    );
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Gerando QR...',
            style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
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
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFC62828)),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
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
          // Header instruction
          const Text(
            'Escaneie o QR code com seu app de banco',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          // QR image with expired overlay
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                      color: Colors.grey.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Countdown widget (replaces static expiry text)
          _buildCountdown(),
          const SizedBox(height: 32),
          // Divider with "ou"
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ou use o codigo',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          // Copia-e-cola
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _qrCode!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Color(0xFF424242),
              ),
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
                foregroundColor: AppTheme.primaryGreen,
                side: BorderSide(
                  color: _copied
                      ? AppTheme.primaryGreen
                      : AppTheme.primaryGreen.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Info note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFB300), width: 1),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFFE65100)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Apos pagar, sua reserva sera confirmada automaticamente.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
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
