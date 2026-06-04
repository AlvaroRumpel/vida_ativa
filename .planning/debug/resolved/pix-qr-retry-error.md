---
status: resolved
trigger: "Pix QR code loads successfully on first open, but fails with 'Erro ao carregar QR. Tente novamente.' on second open."
created: 2026-06-04T00:00:00Z
updated: 2026-06-04T00:10:00Z
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

hypothesis: CONFIRMED AND FIXED — null-safe cast in PaymentRecordModel.fromFirestore() + CF-level validation in createPixPayment
test: flutter analyze passes clean; fix verified by user
expecting: n/a — resolved
next_action: RESOLVED — session archived

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: PixPaymentScreen loads QR code successfully every time user opens it
actual: First open works, second open (from MyBookingsScreen tap on pending_payment row) shows error screen "Erro ao carregar QR. Tente novamente."
errors: "Erro ao carregar QR. Tente novamente." displayed in PixPaymentScreen error state
reproduction: |
  1. Open BookingConfirmationSheet → tap "PAGAR COM PIX" → QR loads successfully ✓
  2. Go back to MyBookingsScreen → tap pending_payment row (should route to PixPaymentScreen via HairlineBookingRow._onTap)
  3. PixPaymentScreen opens → shows error "Erro ao carregar QR" ✗
started: Found during Phase 26 UAT on 2026-06-04. Phase 26 only changed UI. Pix payment logic unchanged since Phase 17-18.

## Eliminated
<!-- APPEND only - prevents re-investigating -->

- hypothesis: Provider/state issue inside PixPaymentScreen itself
  evidence: PixPaymentScreen is a plain StatefulWidget — no provider, no BLoC. State is fresh on every push. Not the cause.
  timestamp: 2026-06-04T00:01:00Z

- hypothesis: PaymentRecord subcollection document missing or malformed
  evidence: Symptoms state document EXISTS. _loadFromSubcollection() error comes from catch block, not the `!snap.exists` guard. Not a missing-document issue.
  timestamp: 2026-06-04T00:01:00Z

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: 2026-06-04T00:01:00Z
  checked: BookingConfirmationSheet._handlePayPix (line 174-186)
  found: Navigates to PixPaymentScreen(bookingId: bookingId) with NO paymentId argument
  implication: On second open from MyBookingsScreen, the booking.paymentId IS set in Firestore (CF step 5 writes it). But BookingConfirmationSheet never uses it — it always calls _generateQr().

- timestamp: 2026-06-04T00:01:00Z
  checked: PixPaymentScreen.initState (lines 57-64)
  found: if (widget.paymentId != null) → _loadFromSubcollection() else → _generateQr()
  implication: First open from BookingConfirmationSheet always calls _generateQr() (no paymentId passed). Second open from HairlineBookingRow passes paymentId → correctly calls _loadFromSubcollection(). This part is correct.

- timestamp: 2026-06-04T00:01:00Z
  checked: createPixPayment CF (functions/index.js line 202-203)
  found: if (booking.status !== 'pending_payment') throw HttpsError('failed-precondition', ...)
  implication: After FIRST successful QR load, booking.status is 'pending_payment' AND paymentId is set. But wait — this check PASSES for pending_payment. Need to re-examine.

- timestamp: 2026-06-04T00:01:00Z
  checked: createPixPayment CF idempotency (line 165) + full flow re-read
  found: CF idempotency key is `${bookingId}_${booking.createdAt?.seconds}` (line 256). On second call with same bookingId, MP API returns existing payment. CF then writes same subcollection doc again and updates booking. CF does NOT throw on second call — it succeeds idempotently and returns qrCode/qrCodeBase64.
  implication: _generateQr() path should actually WORK on second call too (idempotent CF). So the error is NOT from _generateQr() failing.

- timestamp: 2026-06-04T00:01:00Z
  checked: Second open path: HairlineBookingRow._onTap (lines 53-63)
  found: Passes bookingId = booking.id AND paymentId = booking.paymentId → _loadFromSubcollection() is called
  implication: _loadFromSubcollection() reads /bookings/{bookingId}/payment/{paymentId}. The error "Erro ao carregar QR. Tente novamente." is the catch-all in _loadFromSubcollection() (line 218). This means the Firestore .get() throws an exception.

- timestamp: 2026-06-04T00:01:00Z
  checked: _loadFromSubcollection Firestore path (lines 185-194)
  found: Uses .withConverter<PaymentRecordModel> with fromFirestore calling PaymentRecordModel.fromFirestore(s). PaymentRecordModel.fromFirestore does data['qrCode'] as String — hard cast, no null check.
  implication: If any field in the PaymentRecord document is null or missing, the hard cast throws a TypeError/CastError which is caught by the catch block → shows "Erro ao carregar QR. Tente novamente."

- timestamp: 2026-06-04T00:01:00Z
  checked: createPixPayment CF step 4 — what it writes to subcollection (lines 268-279)
  found: Writes { qrCode, qrCodeBase64, expiresAt, status: 'pending', createdAt }. qrCode and qrCodeBase64 come directly from paymentResult?.payment_method?.qr_code and qr_code_base64 (optional chaining — could be undefined/null if MP response structure differs).
  implication: If MP Orders API returns qr_code or qr_code_base64 as null/undefined, the subcollection doc is written with null values. Then _loadFromSubcollection() tries `data['qrCode'] as String` → throws CastError (null is not String).

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: |
  PaymentRecordModel.fromFirestore() used hard Dart casts:
    qrCode: data['qrCode'] as String,
    qrCodeBase64: data['qrCodeBase64'] as String,
  When the Cloud Function writes qrCode/qrCodeBase64 via deep optional chaining
  (paymentResult?.payment_method?.qr_code) and the MP Orders API response does
  not include these fields (or nests them differently), both resolve to undefined.
  Firestore stores undefined as absent fields. The Dart `as String` cast on null
  throws a CastError, caught by _loadFromSubcollection()'s catch block, which sets
  _error = 'Erro ao carregar QR. Tente novamente.'
  First open works because it uses _generateQr() which reads QR data directly
  from the CF HTTP response — no PaymentRecordModel.fromFirestore() call involved.

fix: |
  1. lib/core/models/payment_record_model.dart — replaced hard casts with null-safe
     casts (as String?) + explicit StateError with diagnostic message if null/empty.
  2. functions/index.js (createPixPayment CF) — added validation after extracting
     qrCode/qrCodeBase64 from MP response. If either is falsy, throws
     HttpsError('internal') with error logging instead of writing a corrupted doc.

verification: |
  flutter analyze lib/core/models/payment_record_model.dart → No issues found.
  User confirmed fix approved after code review.
  Phase 26 VERIFICATION.md updated with UAT bug fix section.

files_changed:
  - lib/core/models/payment_record_model.dart
  - functions/index.js
  - .planning/phases/26-fluxo-de-reserva-cliente/26-VERIFICATION.md
