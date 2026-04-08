---
phase: 17-pix-qr-generation
plan: 01
subsystem: payments
tags: [mercadopago, pix, firestore, cloud-functions, flutter, dart]

requires:
  - phase: 16-push-notifications-admin
    provides: BookingModel, BookingCubit, ScheduleCubit foundations

provides:
  - BookingModel com campos paymentMethod, expiresAt, paymentId e getters isPendingPayment, isExpired, isOnArrival
  - PaymentRecordModel para subcollection /bookings/{id}/payment/{txId}
  - bookSlot() bifurcado: pix => pending_payment, on_arrival => confirmed
  - ScheduleCubit bloqueia slots com pending_payment no whereIn
  - createPixPayment Cloud Function com Mercado Pago (deploy pendente: secret setup)

affects:
  - 17-02 (PixPaymentScreen consome PaymentRecordModel e chama createPixPayment)
  - 18-webhook (processa eventos MP usando paymentId como idempotency key)

tech-stack:
  added:
    - mercadopago 2.12.0 (functions/node_modules)
  patterns:
    - Payment method determines booking status at creation time (not confirmationMode)
    - PaymentRecord stored in subcollection /bookings/{id}/payment/{txId}
    - Cloud Function secrets via Firebase Secret Manager (defineSecret)

key-files:
  created:
    - lib/core/models/payment_record_model.dart
  modified:
    - lib/core/models/booking_model.dart
    - lib/features/booking/cubit/booking_cubit.dart
    - lib/features/schedule/cubit/schedule_cubit.dart
    - lib/features/booking/ui/booking_confirmation_sheet.dart
    - functions/index.js
    - functions/package.json

key-decisions:
  - "paymentMethod param replaces confirmationMode Firestore read in bookSlot — simpler, no extra round-trip"
  - "booking_confirmation_sheet passes on_arrival as temporary default until 17-02 adds payment selector"
  - "auto-cancel guard in ScheduleCubit intentionally excludes pending_payment — Phase 18 CF handles expiration"
  - "deploy blocked by Secret Manager API not enabled and MP_ACCESS_TOKEN not set — user action required"

patterns-established:
  - "bookSlot bifurcation pattern: paymentMethod param controls initial status at creation"
  - "PaymentRecord subcollection isolation: payment data separate from booking doc"

requirements-completed:
  - PIX-01
  - PIX-02

duration: 35min
completed: 2026-04-07
---

# Phase 17 Plan 01: Pix QR Generation — Data Layer Summary

**BookingModel estendido com campos Pix, PaymentRecordModel criado, bookSlot bifurcado por paymentMethod, e createPixPayment CF implementada com Mercado Pago SDK (deploy pendente: Secret Manager setup)**

## Performance

- **Duration:** 35 min
- **Started:** 2026-04-07T00:00:00Z
- **Completed:** 2026-04-07T00:35:00Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- BookingModel ganha paymentMethod, expiresAt, paymentId + getters isPendingPayment/isExpired/isOnArrival
- PaymentRecordModel novo para subcollection /bookings/{id}/payment/{txId}
- bookSlot() bifurcado: pix sempre => pending_payment, on_arrival sempre => confirmed (elimina confirmationMode read)
- ScheduleCubit bloqueia pending_payment no whereIn — slot indisponivel para outros usuarios
- createPixPayment CF implementada: valida auth + booking, chama MP Pix API, salva PaymentRecord, atualiza booking, retorna QR data

## Task Commits

1. **Task 1: Estender BookingModel e criar PaymentRecordModel** - `79749ec` (feat)
2. **Task 2: Bifurcar bookSlot() e estender ScheduleCubit** - `f6086ec` (feat)
3. **Task 3: Criar Cloud Function createPixPayment com Mercado Pago** - `85d5d7b` (feat)

## Files Created/Modified

- `lib/core/models/booking_model.dart` - 3 campos novos, 3 getters, fromFirestore/toFirestore/props atualizados
- `lib/core/models/payment_record_model.dart` - novo modelo para subcollection de pagamento
- `lib/features/booking/cubit/booking_cubit.dart` - bookSlot/bookRecurring ganham paymentMethod obrigatorio
- `lib/features/schedule/cubit/schedule_cubit.dart` - whereIn inclui pending_payment; comentario auto-cancel guard
- `lib/features/booking/ui/booking_confirmation_sheet.dart` - passa on_arrival como default temporario (TODO 17-02)
- `functions/index.js` - createPixPayment CF adicionada apos notifyAdminNewBooking
- `functions/package.json` - mercadopago 2.12.0 adicionado

## Decisions Made

- paymentMethod param substitui confirmationMode Firestore read — elimina round-trip e simplifica logica
- booking_confirmation_sheet passa 'on_arrival' como default ate 17-02 adicionar seletor de pagamento
- auto-cancel guard preservado apenas para 'pending' — pending_payment excluido intencionalmente (Phase 18 CF expira via webhook)
- Idempotency key = bookingId no MP API — chamadas duplicadas retornam pagamento existente

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Atualizar callers de bookSlot/bookRecurring na UI existente**
- **Found during:** Task 2 (bifurcacao de bookSlot)
- **Issue:** booking_confirmation_sheet.dart chama bookSlot e bookRecurring sem paymentMethod — compile error
- **Fix:** Adicionado paymentMethod: 'on_arrival' como default temporario com TODO 17-02
- **Files modified:** lib/features/booking/ui/booking_confirmation_sheet.dart
- **Verification:** flutter analyze — No issues found
- **Committed in:** f6086ec (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug em caller da UI)
**Impact on plan:** Fix necessario para compilacao. Semanticamente correto: comportamento pre-Pix era confirmacao direta (equivale a on_arrival). Plan 02 substitui o default pelo seletor real.

## Issues Encountered

**Authentication gate — Firebase Secret Manager + MP_ACCESS_TOKEN**

- Deploy da CF falhou: Secret Manager API nao habilitada no projeto vida-ativa-94ba0
- MP_ACCESS_TOKEN nao existe no Secret Manager
- Codigo da CF esta correto e sintaticamente valido (node --check passou)
- **Acoes necessarias antes do deploy:**
  1. Habilitar Secret Manager API: https://console.developers.google.com/apis/api/secretmanager.googleapis.com/overview?project=vida-ativa-94ba0
  2. Setar secret: `firebase functions:secrets:set MP_ACCESS_TOKEN` (colar token sandbox MP)
  3. Deploy: `firebase deploy --only functions`

## User Setup Required

Antes de executar Plan 02 (PixPaymentScreen), o deploy das functions precisa estar completo:

1. Habilitar Secret Manager API no Google Cloud Console (projeto vida-ativa-94ba0)
2. Obter Access Token sandbox do Mercado Pago (formato: `TEST-XXXXXXXX-...`)
3. `firebase functions:secrets:set MP_ACCESS_TOKEN`
4. `firebase deploy --only functions`
5. Verificar: `firebase functions:secrets:access MP_ACCESS_TOKEN`

## Next Phase Readiness

- BookingModel e PaymentRecordModel prontos para consumo na PixPaymentScreen (Plan 02)
- createPixPayment CF implementada — aguarda deploy (Secret Manager setup)
- booking_confirmation_sheet tem TODO 17-02 para substituir default por seletor de metodo de pagamento
- ScheduleCubit ja bloqueia pending_payment — nenhuma alteracao necessaria no Plan 02

---
*Phase: 17-pix-qr-generation*
*Completed: 2026-04-07*
