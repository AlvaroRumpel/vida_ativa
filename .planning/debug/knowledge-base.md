# GSD Debug Knowledge Base

Resolved debug sessions. Used by `gsd-debugger` to surface known-pattern hypotheses at the start of new investigations.

---

## pix-qr-retry-error — PaymentRecordModel.fromFirestore() hard cast throws on null Firestore field
- **Date:** 2026-06-04
- **Error patterns:** Erro ao carregar QR, Tente novamente, qrCode, qrCodeBase64, CastError, TypeError, fromFirestore, _loadFromSubcollection, PixPaymentScreen, second open, pending_payment
- **Root cause:** PaymentRecordModel.fromFirestore() used hard Dart casts (`data['qrCode'] as String`) which throw CastError when the Firestore field is null/absent. The Cloud Function writes qrCode/qrCodeBase64 via deep optional chaining — if MP Orders API response nests fields differently, both resolve to undefined and Firestore stores them as absent. First open uses _generateQr() (reads CF HTTP response directly, no model parsing). Second open uses _loadFromSubcollection() → fromFirestore() → throws → error screen.
- **Fix:** (1) payment_record_model.dart: null-safe cast + explicit StateError with diagnostic message. (2) functions/index.js createPixPayment: validate qrCode/qrCodeBase64 before writing subcollection doc; throw HttpsError('internal') if missing.
- **Files changed:** lib/core/models/payment_record_model.dart, functions/index.js
---

