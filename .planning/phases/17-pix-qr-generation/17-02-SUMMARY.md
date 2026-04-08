---
phase: 17-pix-qr-generation
plan: 02
subsystem: payments-ui
tags: [flutter, pix, qr-code, booking-ui, mercadopago]

requires:
  - phase: 17-pix-qr-generation
    plan: 01
    provides: BookingModel com isPendingPayment/isOnArrival/isExpired, PaymentRecordModel, createPixPayment CF

provides:
  - PixPaymentScreen: tela dedicada com QR code, copia-e-cola, loading/error/retry
  - BookingConfirmationSheet bifurcada: "Pagar com Pix" e "Pagar na hora"
  - BookingCard: badges pending_payment/on_arrival/expired
  - MyBookingsScreen: tap em pending_payment reabre PixPaymentScreen

affects:
  - 18-webhook (fluxo confirmado visualmente; webhook confirma booking no back-end)

tech-stack:
  added: []
  patterns:
    - PopScope(canPop:false) + BackButton para forcar navegacao para /bookings ao sair de PixPaymentScreen
    - WidgetsBinding.instance.addPostFrameCallback para Navigator.push apos Navigator.pop de sheet
    - _statusBadge com booking opcional para isOnArrival check (status + paymentMethod combinados)

key-files:
  created:
    - lib/features/booking/ui/pix_payment_screen.dart
  modified:
    - lib/features/booking/ui/booking_confirmation_sheet.dart
    - lib/features/booking/ui/booking_card.dart
    - lib/features/booking/ui/my_bookings_screen.dart

key-decisions:
  - "PixPaymentScreen usa paymentId opcional: null => chama CF, nao-nulo => le subcollection"
  - "BackButton override + PopScope garante que sair de PixPaymentScreen sempre vai para /bookings"
  - "isOnArrival badge exige booking object no _statusBadge porque depende de status+paymentMethod"
  - "recorrente mantem 'on_arrival' como default — Pix em recorrentes e escopo futuro"

requirements-completed:
  - PIX-01
  - PIX-02

duration: 25min
completed: 2026-04-08
---

# Phase 17 Plan 02: Pix QR Generation — UI Layer Summary

**PixPaymentScreen completa com QR code e copia-e-cola, BookingConfirmationSheet bifurcada em Pix/na hora, BookingCard com badges de status Pix, e MyBookingsScreen reabrindo QR ao tocar pending_payment**

## Performance

- **Duration:** 25 min
- **Started:** 2026-04-08T18:00:00Z
- **Completed:** 2026-04-08T18:32:12Z
- **Tasks:** 2 (Task 1 executada por agente anterior; Task 2 executada agora)
- **Files modified:** 4

## Accomplishments

- PixPaymentScreen: loading state ("Gerando QR..."), QR via Image.memory(base64Decode()), texto "Valido ate HH:mm", botao Copiar com feedback "Copiado" por 2s, estado de erro com "Tentar novamente"
- PixPaymentScreen: dois modos — sem paymentId chama createPixPayment CF; com paymentId le subcollection
- PixPaymentScreen: BackButton + PopScope forca navegacao para /bookings ao sair (stream reativa mostra pending_payment)
- BookingConfirmationSheet: _handleConfirm() substituido por _handlePayPix() e _handlePayOnArrival(); dois botoes empilhados para reservas avulsas
- BookingCard: _statusColor/Label com pending_payment (deep orange) e expired (cinza)
- BookingCard: _statusBadge(booking:) detecta isOnArrival e exibe badge azul "Pagar na hora"
- MyBookingsScreen: tap em pending_payment com paymentId abre PixPaymentScreen; demais cards abrem detail sheet

## Task Commits

1. **Task 1: Criar PixPaymentScreen** - `a56e006` (feat) — agente anterior
2. **Task 2: BookingCard badges + MyBookingsScreen bifurcacao** - `5735b9f` (feat)

## Files Created/Modified

- `lib/features/booking/ui/pix_payment_screen.dart` — novo; StatefulWidget com dois modos de carga, QR display, copia-e-cola
- `lib/features/booking/ui/booking_confirmation_sheet.dart` — _handlePayPix + _handlePayOnArrival; dois botoes de pagamento
- `lib/features/booking/ui/booking_card.dart` — pending_payment/expired nos switches; _statusBadge com isOnArrival
- `lib/features/booking/ui/my_bookings_screen.dart` — import PixPaymentScreen; onTap bifurcado para isPendingPayment

## Decisions Made

- PixPaymentScreen usa paymentId opcional: null significa fluxo inicial (chama CF), nao-nulo significa reabrir QR existente da subcollection
- BackButton override + PopScope(canPop:false) garante que usuario vai para /bookings ao sair, nao para a agenda — stream reativa atualiza o card automaticamente
- isOnArrival badge exige booking object porque combina status 'confirmed' + paymentMethod 'on_arrival' — switch de status sozinho nao e suficiente
- Recorrente mantem on_arrival como default; Pix em reservas recorrentes e escopo de versao futura

## Deviations from Plan

None - plan executed exactly as written. Task 1 foi completada por agente anterior; Task 2 aplicada nesta sessao.

## Checkpoint: human-verify

A verificacao humana (Task 3 — checkpoint:human-verify) requer dispositivo/emulador com app rodando.

**O que verificar:**
1. BookingConfirmationSheet: dois botoes aparecem ("Pagar com Pix" e "Pagar na hora")
2. "Pagar na hora": sheet fecha, snackbar "Reserva confirmada!", badge azul "Pagar na hora" em Minhas Reservas
3. "Pagar com Pix": PixPaymentScreen abre com spinner "Gerando QR..." (requer sandbox MP configurado para ver QR)
4. Card pending_payment em Minhas Reservas: tap reabre PixPaymentScreen com QR existente

**Pre-requisito para fluxo Pix completo:** Secret Manager + MP_ACCESS_TOKEN configurados (ver 17-01-SUMMARY.md "User Setup Required")

---
*Phase: 17-pix-qr-generation*
*Completed: 2026-04-08*
