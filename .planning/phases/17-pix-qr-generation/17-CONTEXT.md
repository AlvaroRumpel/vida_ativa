# Phase 17: Pix QR Generation - Context

**Gathered:** 2026-04-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Cliente finaliza reserva → BookingConfirmationSheet chama Cloud Function `createPixPayment` → booking criado com status `pending_payment` → PixPaymentScreen exibe QR Pix + copia-e-cola gerados pelo Mercado Pago → slot bloqueado por 30 min.

Escopo: PIX-01 (QR na confirmação) e PIX-02 (pending_payment + slot bloqueado).

Fora do escopo desta fase:
- Timer de contagem regressiva animado (Phase 18 — PIX-03)
- Botão regenerar QR (Phase 18 — PIX-03)
- Webhook / confirmação automática (Phase 18 — PIX-04)
- Status em tempo real em Minhas Reservas (Phase 18 — PIX-05)
- Cloud Function de expiração automática (Phase 18 — PIX-07)

</domain>

<decisions>
## Implementation Decisions

### QR Display UX
- Após confirmar reserva: Navigator.push para **PixPaymentScreen** dedicada (não sheet)
- BookingConfirmationSheet fecha, PixPaymentScreen abre imediatamente
- PixPaymentScreen abre com **loading state** (spinner + "Gerando QR...") enquanto CF processa (1-3s)
- QR e copia-e-cola aparecem quando httpsCallable retorna
- Ao fechar/sair da PixPaymentScreen: navega diretamente para **MyBookingsScreen**
- Exibe **expiresAt estático**: "Válido até HH:mm" (não countdown animado — esse é Phase 18)

### Invoke da Cloud Function
- Flutter chama `createPixPayment` via **httpsCallable** (FirebaseFunctions.instance.httpsCallable)
- Payload: `{ bookingId: String }`
- CF valida: `booking.userId == context.auth.uid` — rejeita se não bater
- CF salva PaymentRecord em `/bookings/{id}/payment/{txId}` **E** retorna QR data diretamente para Flutter
- Se CF falha (Mercado Pago indisponível): reserva **permanece pending_payment** (não cancela), PixPaymentScreen exibe mensagem de erro + botão "Tentar novamente" que relança a callable

### Cloud Function — createPixPayment (Node.js)
- Tipo: Callable Function (onCall v2)
- Credenciais MP: **Firebase Secret Manager** — acessadas via `defineSecret('MP_ACCESS_TOKEN')`
- Phase 17 usa **credenciais sandbox** do Mercado Pago
- Fluxo interno:
  1. Validar auth + bookingId
  2. Ler booking do Firestore — verificar status == 'pending_payment' e userId == caller
  3. Chamar Mercado Pago Pix API com `@mercadopago/sdk-node v2.0.0`
  4. Calcular `expiresAt = now + 30min`
  5. Salvar PaymentRecord em `/bookings/{bookingId}/payment/{txId}`
  6. Atualizar booking: `expiresAt`, `paymentId = txId`
  7. Retornar `{ qrCode, qrCodeBase64, expiresAt }` para Flutter

### BookingModel — novos campos
- `status` novos valores: `'pending_payment'` e `'expired'` (além de pending, confirmed, cancelled)
- `expiresAt: DateTime?` — Timestamp Firestore; Quando o QR/slot expira (30 min)
- `paymentId: String?` — txId do Mercado Pago (preenchido após createPixPayment)
- Getters a adicionar: `isPendingPayment`, `isExpired`

### PaymentRecord schema — /bookings/{id}/payment/{txId}
- `qrCode: String` — string copia-e-cola do Pix
- `qrCodeBase64: String` — imagem base64 do QR (retornada diretamente pelo Mercado Pago)
- `expiresAt: Timestamp` — quando o QR expira
- `status: String` — 'pending' | 'paid' | 'expired' (Phase 18 webhook atualiza)
- Documento ID = txId do Mercado Pago (idempotência no webhook Phase 18)

### QR Rendering no Flutter
- Usar `qrCodeBase64` com `Image.memory(base64Decode(qrCodeBase64))` — sem package extra necessário
- Mercado Pago retorna base64 diretamente da API Pix

### pending_payment na Agenda
- Slot com `pending_payment` aparece como **bloqueado/ocupado** na ScheduleScreen (igual a confirmed)
- Outros clientes não conseguem reservar enquanto slot está pending_payment
- ScheduleScreen deve tratar pending_payment como status "ocupado" no filtro de disponibilidade

### BookingCard em Minhas Reservas
- Status `pending_payment`: badge **"Aguardando pagamento"** + cor âmbar/laranja
- Status `expired`: badge **"Expirada"** + cor cinza (igual a cancelled visualmente)
- Tap no card com status `pending_payment`: abre **PixPaymentScreen** lendo PaymentRecord da subcollection
- PixPaymentScreen reutilizada tanto no fluxo inicial (pós-booking) quanto via tap no card

### Copia-e-cola UX
- Exibição: texto truncado do qrCode + botão **"Copiar código"**
- Feedback de cópia: botão muda temporariamente para **"✓ Copiado"** por 2 segundos
- Sem botão "Já paguei" — confirmação só via webhook (Phase 18)

### Claude's Discretion
- Layout exato da PixPaymentScreen (espaçamentos, card container, instrução de uso)
- QR image size/padding na tela
- Animação de loading → QR reveal
- Estratégia exata de retry ao clicar "Tentar novamente"
- Usar Image.memory vs package qr — prefira Image.memory(base64Decode()) por simplicidade

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requisitos desta fase
- `.planning/REQUIREMENTS.md` §PIX-01, §PIX-02 — Requisitos base de QR Pix e pending_payment

### Padrões de booking existentes
- `lib/features/booking/cubit/booking_cubit.dart` — `bookSlot()`, `bookRecurring()` — padrões de callable, transaction e stream reativo
- `lib/features/booking/ui/booking_confirmation_sheet.dart` — Sheet que lança a PixPaymentScreen (ponto de entrada do fluxo Pix)
- `lib/features/booking/ui/client_booking_detail_sheet.dart` — Sheet de detalhe; tap em card pending_payment deve abrir PixPaymentScreen no lugar
- `lib/features/booking/ui/booking_card.dart` — Card que receberá badges "Aguardando pagamento" e "Expirada"
- `lib/features/booking/ui/my_bookings_screen.dart` — Destino de navegação ao sair da PixPaymentScreen

### Modelo de dados
- `lib/core/models/booking_model.dart` — Receberá `expiresAt`, `paymentId`, status `pending_payment`/`expired`

### Cloud Function existente (referência de padrão)
- `functions/index.js` — Padrão onDocumentWritten v2; `@mercadopago/sdk-node` precisa ser adicionado ao `functions/package.json`

### Schedule — filtragem de disponibilidade
- `lib/features/schedule/` — Verificar onde slots são filtrados por status de booking; `pending_payment` deve ser tratado como ocupado

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BookingCubit.bookSlot()` — Cria o booking com status inicial; vai precisar chamar CF após criar
- `SnackHelper.success()` — Feedback de sucesso (não usado no flow Pix, mas referência de padrão)
- `RecurrenceResultSheet` — Exemplo de sheet empilhado pós-booking (padrão de navegação)
- Padrão `_isSubmitting` + `_errorMessage` em StatefulWidget — reutilizar na PixPaymentScreen

### Established Patterns
- Sheets usam `StatefulWidget` com `_isSubmitting` + `_errorMessage` gerenciados localmente
- `BookingCubit` capturado fora do builder (context não disponível em subtrees de sheet)
- `isScrollControlled: true` em todos os `showModalBottomSheet`
- Stream reativo do BookingCubit — MyBookingsScreen atualiza automaticamente via stream
- Sentry: `Sentry.captureException(e, stackTrace: s)` apenas para erros não esperados

### Integration Points
- `BookingConfirmationSheet._handleConfirm()` — Após `bookSlot()` com sucesso, fazer `Navigator.push(PixPaymentScreen(bookingId: docId))`
- `BookingCard` — Condicional em `booking.status == 'pending_payment'` para badge âmbar e tap para PixPaymentScreen
- `functions/package.json` — Adicionar `@mercadopago/sdk-node: "^2.0.0"` e `firebase-functions/params` para Secret Manager
- ScheduleScreen/ViewModel — Adicionar `pending_payment` ao set de statuses que bloqueiam slot

</code_context>

<specifics>
## Specific Ideas

- PixPaymentScreen deve ser imersiva: QR grande, instrução "Abra seu app de banco e escaneie", depois copia-e-cola com botão
- "Válido até HH:mm" como texto simples abaixo do QR
- Ao navegar para MyBookingsScreen, reserva pending_payment deve aparecer no topo de "Próximas reservas"

</specifics>

<deferred>
## Deferred Ideas

- Timer de contagem regressiva animado ("28:42 restantes") — Phase 18 (PIX-03)
- Botão "Regenerar QR" — Phase 18 (PIX-03)
- Confirmação automática via webhook — Phase 18 (PIX-04)
- Status em tempo real no card da reserva — Phase 18 (PIX-05)
- Expiração automática de reservas pela CF — Phase 18 (PIX-07)
- Credenciais de produção do Mercado Pago — Phase 18 ou pós-validação sandbox

</deferred>

---

*Phase: 17-pix-qr-generation*
*Context gathered: 2026-04-07*
