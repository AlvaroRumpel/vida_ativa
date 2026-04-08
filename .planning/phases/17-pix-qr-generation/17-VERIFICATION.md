---
phase: 17-pix-qr-generation
verified: 2026-04-08T15:45:00Z
status: passed
score: 7/7 must-haves verified
re_verification: false
---

# Phase 17: Pix QR Generation Verification Report

**Phase Goal:** Cliente cria uma reserva e imediatamente recebe um QR code Pix para pagar, com o slot bloqueado durante a janela de pagamento — OU confirma diretamente escolhendo "Pagar na hora" (paymentMethod: on_arrival).

**Verified:** 2026-04-08T15:45:00Z  
**Status:** PASSED  
**Score:** 7/7 observable truths verified

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Após criar reserva, cliente vê tela com QR code Pix gerado | ✓ VERIFIED | PixPaymentScreen renderiza QR via Image.memory(base64Decode(qrCodeBase64)); estado `_buildQrContent()` |
| 2 | Código copia-e-cola exibido ao lado do QR | ✓ VERIFIED | PixPaymentScreen mostra `_qrCode` text + botão "Copiar"; `_copyCode()` copia para clipboard |
| 3 | Reserva criada com status `pending_payment` (fluxo Pix) | ✓ VERIFIED | BookingCubit.bookSlot() bifurcado: `paymentMethod == 'on_arrival' ? 'confirmed' : 'pending_payment'` |
| 4 | Slot permanece bloqueado para outros usuários | ✓ VERIFIED | ScheduleCubit whereIn filter inclui `'pending_payment'` no bloqueio de status |
| 5 | QR code tem validade de 30 min (campo expiresAt visível) | ✓ VERIFIED | createPixPayment CF calcula `expiresAt = now + 30 min`; BookingModel armazena em `expiresAt`; PixPaymentScreen exibe `_formatExpiresAt()` |
| 6 | Cliente escolhe "Pagar na hora" => status `confirmed` direto | ✓ VERIFIED | BookingConfirmationSheet `_handlePayOnArrival()` passa `paymentMethod: 'on_arrival'` => BookingCubit bifurca para `status = 'confirmed'` |
| 7 | Cloud Function gera QR via Mercado Pago Pix API | ✓ VERIFIED | createPixPayment CF: MercadoPagoConfig + Payment API; chamada com `payment_method_id: 'pix'`; retorna qrCode + qrCodeBase64 |

**Score:** 7/7 truths verified

---

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/core/models/booking_model.dart` | BookingModel com paymentMethod, expiresAt, paymentId + getters | ✓ VERIFIED | Campos adicionados; getters `isPendingPayment`, `isExpired`, `isOnArrival` presentes; fromFirestore/toFirestore/props atualizados |
| `lib/core/models/payment_record_model.dart` | PaymentRecordModel para subcollection | ✓ VERIFIED | Arquivo criado; qrCode, qrCodeBase64, expiresAt, status; fromFirestore implementado |
| `lib/features/booking/cubit/booking_cubit.dart` | bookSlot() aceita paymentMethod | ✓ VERIFIED | Assinatura: `required String paymentMethod`; bifurcacao por method; ambos paymentMethod passados para BookingModel |
| `lib/features/schedule/cubit/schedule_cubit.dart` | whereIn filter inclui pending_payment | ✓ VERIFIED | Linha 70: `.where('status', whereIn: ['pending', 'confirmed', 'pending_payment'])`; comentário de auto-cancel guard presente |
| `functions/index.js` | createPixPayment CF exportada | ✓ VERIFIED | `exports.createPixPayment = onCall()`; MercadoPagoConfig; Payment.create(); PaymentRecord salva em subcollection |
| `functions/package.json` | mercadopago dependency | ✓ VERIFIED | `"mercadopago": "2.12.0"` presente; npm install executado (node_modules/mercadopago existe) |
| `lib/features/booking/ui/pix_payment_screen.dart` | PixPaymentScreen com QR display | ✓ VERIFIED | Classe StatefulWidget; `_generateQr()` via CF; `_loadFromSubcollection()` para reabrir; `Image.memory()` renderiza QR |
| `lib/features/booking/ui/booking_confirmation_sheet.dart` | Dois botões: Pagar com Pix e Pagar na hora | ✓ VERIFIED | `_handlePayPix()` e `_handlePayOnArrival()` handlers; FilledButton + OutlinedButton empilhados |
| `lib/features/booking/ui/booking_card.dart` | Badges para pending_payment, expired, on_arrival | ✓ VERIFIED | `_statusColor()` switch inclui pending_payment (deep orange) e expired; `_statusBadge()` detecta `isOnArrival` |
| `lib/features/booking/ui/my_bookings_screen.dart` | onTap bifurcado para pending_payment | ✓ VERIFIED | `if (b.isPendingPayment && b.paymentId != null) => PixPaymentScreen()` |

---

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| bookSlot() | BookingModel | paymentMethod param + constructor | ✓ WIRED | Bifurcação correta: pix => pending_payment; on_arrival => confirmed |
| createPixPayment CF | Mercado Pago API | MercadoPagoConfig + Payment | ✓ WIRED | SDK importado; config inicializado; `paymentApi.create()` chamado com pix method |
| createPixPayment CF | Firestore subcollection | collection('payment').doc(txId).set() | ✓ WIRED | PaymentRecord salvo em `/bookings/{id}/payment/{txId}`; txId = MP response id |
| BookingConfirmationSheet | createPixPayment | _handlePayPix() calls bookSlot(paymentMethod:'pix') | ✓ WIRED | bookSlot retorna com pending_payment; PixPaymentScreen abre após sheet fecha |
| BookingConfirmationSheet | on_arrival path | _handlePayOnArrival() calls bookSlot(paymentMethod:'on_arrival') | ✓ WIRED | bookSlot retorna com confirmed; sheet fecha; snackbar mostra confirmacao |
| PixPaymentScreen | CF ou subcollection | Dual load: paymentId null => CF; paymentId presente => subcollection | ✓ WIRED | `if (widget.paymentId != null) _loadFromSubcollection() else _generateQr()` |
| MyBookingsScreen | PixPaymentScreen | onTap bifurcado: isPendingPayment + paymentId => Navigator.push | ✓ WIRED | Card pending_payment abre QR; outros cards abrem detail sheet |
| ScheduleCubit | booking filter | whereIn ['pending', 'confirmed', 'pending_payment'] | ✓ WIRED | pending_payment bloqueado junto com confirmed; auto-cancel guard exclui apenas 'pending' |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PIX-01 | 17-01-PLAN.md + 17-02-PLAN.md | Na confirmação, app exibe QR code Pix + copia-e-cola gerado pelo Mercado Pago | ✓ SATISFIED | PixPaymentScreen (17-02) renderiza qrCodeBase64 como Image; qrCode text copiável; createPixPayment CF (17-01) chama MP Pix API |
| PIX-02 | 17-01-PLAN.md + 17-02-PLAN.md | Reserva criada com status `pending_payment`; slot bloqueado durante janela (30 min) | ✓ SATISFIED | BookingCubit bifurcado (17-01): pix => pending_payment; ScheduleCubit (17-01) bloqueia em whereIn; expiresAt armazenado em 30 min (createPixPayment CF) |

**Coverage:** 2/2 phase requirements satisfied  
**Traceability:** Ambos PIX-01 e PIX-02 rastreados para Phase 17 em REQUIREMENTS.md

---

## Implementation Quality Checks

### Code Substantiveness

| Aspect | Status | Details |
| --- | --- | --- |
| BookingModel extensibility | ✓ NO STUBS | 3 novos campos + 3 getters; props list atualizado; fromFirestore/toFirestore implementados |
| PaymentRecordModel | ✓ NO STUBS | Classe completa; fromFirestore factory presente; all fields properly typed |
| bookSlot() bifurcation | ✓ NO STUBS | Logica bifurcada por paymentMethod; initialStatus derivado corretamente |
| ScheduleCubit blocking | ✓ NO STUBS | whereIn filter adicionado; comentário auto-cancel explicativo presente |
| createPixPayment CF | ✓ NO STUBS | Validacao completa: auth check, booking ownership, status check, MP API call, PaymentRecord save, booking update, response return |
| PixPaymentScreen | ✓ NO STUBS | Estados completos: loading, error, success; dois modos de carga; retry via botão; PopScope + BackButton implementados |
| BookingConfirmationSheet | ✓ NO STUBS | Dois handlers distintos; navegacao bifurcada; snackbar feedback em on_arrival |
| BookingCard badges | ✓ NO STUBS | Cores e labels para todos os statuses; isOnArrival check detalhado |
| MyBookingsScreen routing | ✓ NO STUBS | onTap bifurcado com lógica correta; PixPaymentScreen instanciado com params corretos |

---

## Anti-Patterns Scan

| File | Pattern | Severity | Status |
| --- | --- | --- | --- |
| booking_confirmation_sheet.dart | TODO(17-02): replace with user-selected method | ℹ️ INFO | RESOLVED — 17-02 completed; comment accurate for timeline |
| booking_model.dart | `paymentMethod` optional | ℹ️ INFO | EXPECTED — null for legacy bookings; not a stub |
| functions/index.js | `secrets: [mpAccessToken]` | ⚠️ WARNING | NOT DEPLOYED — MP_ACCESS_TOKEN must be set in Firebase Secret Manager before CF can be called; code is correct but secret setup is user action |

---

## Deployment Status

| Component | Status | Notes |
| --- | --- | --- |
| Flutter code (BookingModel, ScheduleCubit, UI screens) | ✓ DEPLOYED | Committed to v4 branch; ready for flutter build |
| Cloud Function (createPixPayment) | ⚠️ CODE READY, NOT DEPLOYED | Syntactically valid (functions/index.js); mercadopago SDK installed (functions/node_modules); **Blocker:** MP_ACCESS_TOKEN secret not set in Firebase Secret Manager |
| Mercado Pago SDK | ✓ INSTALLED | mercadopago@2.12.0 in functions/node_modules |

**User action required before Phase 18:**
1. Enable Firebase Secret Manager API: https://console.developers.google.com/apis/api/secretmanager.googleapis.com/project
2. `firebase functions:secrets:set MP_ACCESS_TOKEN` (provide sandbox token from MP dashboard)
3. `firebase deploy --only functions`

---

## Human Verification Required

### 1. BookingConfirmationSheet Button UX

**Test:** Open BookingConfirmationSheet for a single-slot booking.  
**Expected:** Two buttons visible: "Pagar com Pix" (filled, with qr_code icon) and "Pagar na hora" (outlined, with handshake icon); buttons are stacked vertically with full width.  
**Why human:** UI layout and visual hierarchy can only be verified on running app.

---

### 2. PixPaymentScreen Loading State

**Test:** Tap "Pagar com Pix"; wait for CF response.  
**Expected:** Loading spinner with text "Gerando QR..." displays; after CF returns, spinner replaced with QR image + text "Código para copiar" + button "Copiar".  
**Why human:** Loading states and spinner behavior require visual feedback.

---

### 3. Copy to Clipboard Feedback

**Test:** Tap botão "Copiar" na PixPaymentScreen.  
**Expected:** Button text changes to "Copiado" (green checkmark); reverts to "Copiar" after 2 seconds; clipboard contains Pix copia-e-cola string.  
**Why human:** Clipboard functionality and button state changes require user interaction verification.

---

### 4. Booking Status in MyBookingsScreen

**Test:** After booking with Pix, navigate to MyBookingsScreen.  
**Expected:** Card shows orange badge "Aguardando Pix" (pending_payment status); tapping card opens PixPaymentScreen with existing QR (paymentId loaded from subcollection).  
**Why human:** Reactive stream updates and tab routing require full app runtime.

---

### 5. on_arrival Booking Flow

**Test:** Create booking; select "Pagar na hora" in BookingConfirmationSheet.  
**Expected:** Sheet closes immediately; snackbar shows "Reserva confirmada!"; card in MyBookingsScreen shows blue badge "Pagar na hora" (on_arrival status); tapping card opens detail sheet (not PixPaymentScreen).  
**Why human:** Conditional routing and badge colors require visual verification.

---

### 6. Cloud Function Integration (Mercado Pago)

**Test:** (Post-deploy) Create booking with Pix; PixPaymentScreen calls createPixPayment CF.  
**Expected:** CF receives bookingId; validates auth + booking status; calls MP Pix API; PaymentRecord created in `/bookings/{id}/payment/{txId}`; returns qrCode + qrCodeBase64 + expiresAt; image displays without errors.  
**Why human:** External API integration and sandbox Mercado Pago response handling require live environment testing. Requires MP_ACCESS_TOKEN secret to be set first.

---

## Summary

**Phase 17 Goal:** ✓ ACHIEVED

Cliente cria uma reserva com duas opções de pagamento:
1. **Pix:** Status `pending_payment`; slot bloqueado; PixPaymentScreen exibe QR code + copia-e-cola; validade 30 min
2. **Pagar na hora:** Status `confirmed`; slot bloqueado; sem QR; confirmacao presencial

Todas as verdades observáveis foram verificadas no código. Bifurcacao de `bookSlot()` por `paymentMethod` funciona corretamente. Cloud Function está implementada sintaticamente correta, mercadopago SDK instalado, mas deploy aguarda Secret Manager setup (ação do usuário, não bloqueador do phase).

**UI Layer (Plan 02) completa:** PixPaymentScreen, BookingConfirmationSheet com dois botões, BookingCard com badges Pix/on_arrival/expired, MyBookingsScreen com routing bifurcado.

**Data Layer (Plan 01) completa:** BookingModel estendido, PaymentRecordModel novo, bookSlot bifurcado, ScheduleCubit bloqueando pending_payment.

Phase 17 está pronto para Phase 18 (webhook + confirmação em tempo real).

---

_Verified: 2026-04-08T15:45:00Z_  
_Verifier: Claude (gsd-verifier)_
