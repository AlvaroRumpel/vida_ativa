# Phase 18: Webhook + Confirmação em Tempo Real - Context

**Gathered:** 2026-04-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Fechar o ciclo do Pix: QR exibe countdown animado e regenera quando expira; webhook do Mercado Pago confirma pagamento automaticamente; reservas não pagas expiram e liberam slot; admin vê status de pagamento com opção de confirmação manual.

**Escopo: PIX-03, PIX-04, PIX-05, PIX-06, PIX-07.**

Fora do escopo desta fase:
- Credenciais de produção MP (pós-validação sandbox)
- Cartão de crédito/débito
- Relatório de pagamentos

</domain>

<decisions>
## Implementation Decisions

### Timer de expiração (PIX-03)
- Formato: **countdown "MM:SS restantes"** (ex: "28:42 restantes") contando regressivamente
- Implementação: `Timer.periodic(Duration(seconds: 1), ...)` em `_PixPaymentScreenState`
- Quando countdown chega a zero: timer some, QR fica visível mas acinzentado/overlay, botão verde **"Gerar novo QR"** aparece no lugar do timer
- Countdown inicia com base em `expiresAt` retornado pelo CF (não fixo em 30min)

### Regeneração de QR (PIX-03)
- Usuário toca "Gerar novo QR" → chama `createPixPayment` CF **de novo** (mesmo CF existente)
- Cria novo PaymentRecord com novo txId; booking continua `pending_payment`
- CF já tem idempotência por `bookingId` no MP — nova chamada com mesmo bookingId pode retornar novo payment ID no sandbox
- Após regeneração: PixPaymentScreen reinicia em loading state → exibe novo QR + novo countdown

### Janela de expiração: 30 min QR + 15 min buffer (PIX-03/07)
- QR Pix expira em **30 min** (definido pelo Mercado Pago na CF `createPixPayment`)
- Slot permanece bloqueado em `pending_payment` por até **45 min** — dá tempo de gerar novo QR
- `expireUnpaidBookings` CF processa bookings onde `expiresAt < now` E `status == 'pending_payment'`
  - Usa `expiresAt` do booking (salvo pela CF `createPixPayment`) como referência
  - Marca booking como `expired`, libera slot para nova reserva
- CF scheduled: **a cada 15 minutos** (`every 15 minutes` no onSchedule v2)
- Resultado prático: reserva expira entre 45min e 60min após criação

### handlePixWebhook CF (PIX-04)
- Tipo: `onRequest` (HTTP trigger, não callable) — Mercado Pago envia POST via HTTP
- Retorna **202 Accepted imediatamente** antes de processar (evitar retry do MP)
- Verificação de assinatura MP: header `x-signature` com formato `ts=...,v1=...` (validar HMAC-SHA256)
- Chave de assinatura: **`MP_WEBHOOK_SECRET`** no Firebase Secret Manager (novo secret, separado do access token)
- Idempotência: transactionId do evento como chave — verificar se PaymentRecord já tem `status: 'paid'` antes de processar
- Se pagamento confirmado (`status == 'approved'`): atualizar booking para `confirmed` + PaymentRecord para `paid`
- Bypassa modo de aprovação manual do admin (decisão de arquitetura STATE.md)
- URL do webhook: registrar no painel MP com URL da CF (ex: `https://us-central1-vida-ativa-staging.cloudfunctions.net/handlePixWebhook`)

### Tempo real no cliente (PIX-05)
- BookingCubit já usa stream reativo do Firestore — card atualiza **silenciosamente** quando webhook confirma
- Sem snackbar extra quando MyBookingsScreen está aberta; a mudança de badge é feedback suficiente
- **PixPaymentScreen escuta stream do booking**: quando `status` muda para `confirmed`, navega automaticamente para MyBookingsScreen com snackbar **"Pagamento confirmado! Reserva garantida."**
- Implementação: `StreamSubscription` no `initState` da PixPaymentScreen ouvindo `/bookings/{bookingId}`

### Admin: status de pagamento (PIX-06)
- **AdminBookingCard existente**: adicionar badges de pagamento Pix
  - `pending_payment`: badge âmbar **"Aguardando Pix"**
  - `confirmed + paymentMethod == 'pix'`: badge verde **"Pix pago"**
  - `expired`: badge cinza **"Expirada"**
  - `confirmed + paymentMethod == 'on_arrival'`: badge azul **"Pagar na hora"** (já existe)
- **AdminBookingDetailSheet**: adicionar botão **"Confirmar pagamento manual"** quando `status == 'pending_payment'`
  - Chama `adminBookingCubit.confirmBooking(booking.id)` (método já existe)
  - Também atualiza PaymentRecord `status` para `'paid'` via transação Firestore
- Não criar nova aba ou tela — tudo dentro do fluxo de gerenciamento existente

### Claude's Discretion
- Layout exato do countdown na PixPaymentScreen (posição relativa ao QR, tamanho de fonte)
- Cor do countdown quando falta pouco tempo (vermelho nos últimos 2min?)
- Overlay/efeito visual do QR acinzentado após expirar
- Estratégia de cancelamento do `Timer` quando widget é disposed
- Timeout e retry do `StreamSubscription` na PixPaymentScreen
- Detalhes de implementação do HMAC-SHA256 para verificação do webhook MP

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requisitos desta fase
- `.planning/REQUIREMENTS.md` §PIX-03, §PIX-04, §PIX-05, §PIX-06, §PIX-07 — Requisitos completos

### Decisões de arquitetura relevantes (STATE.md)
- `.planning/STATE.md` — Decisão: webhook retorna 202 antes de processar; confirmação Pix bypassa aprovação admin

### Código existente — Flutter (modificar)
- `lib/features/booking/ui/pix_payment_screen.dart` — Adicionar countdown, botão regenerar QR, StreamSubscription para auto-navegar quando confirmado
- `lib/features/admin/ui/admin_booking_card.dart` — Adicionar badges pending_payment/expired/pix-pago
- `lib/features/admin/ui/admin_booking_detail_sheet.dart` — Adicionar botão "Confirmar pagamento manual"

### Código existente — Cloud Functions (modificar/adicionar)
- `functions/index.js` — Adicionar `handlePixWebhook` (onRequest) e `expireUnpaidBookings` (onSchedule)
- `functions/package.json` — Verificar dependências necessárias (crypto já é nativo no Node.js)

### Referência de padrões existentes
- `lib/features/booking/cubit/booking_cubit.dart` — Stream reativo, padrão de callable CF
- `lib/features/admin/cubit/admin_booking_cubit.dart` — `confirmBooking()` método existente a reutilizar

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BookingCubit` stream reativo — MyBookingsScreen já atualiza automaticamente via Firestore stream; PIX-05 é gratuito
- `adminBookingCubit.confirmBooking(bookingId)` — Método existente para confirmar booking; reutilizar para confirmação manual Pix
- `AdminBookingCard._statusColor()` / `_statusLabel()` — Switches a estender com pending_payment/expired/pix-pago
- `AdminBookingDetailSheet` — StatefulWidget com `_isSubmitting` pattern; adicionar botão "Confirmar manual" seguindo padrão existente

### Established Patterns
- CFs Node.js v2: `onCall`, `onDocumentWritten`, `onSchedule`, `onRequest` — todas no mesmo `functions/index.js`
- Secret Manager: `defineSecret('MP_ACCESS_TOKEN')` pattern — replicar para `MP_WEBHOOK_SECRET`
- `admin.firestore().runTransaction()` disponível para atualizações atômicas booking + PaymentRecord
- Timer/stream em StatefulWidget: sempre cancelar em `dispose()` para evitar memory leak

### Integration Points
- `PixPaymentScreen.initState()` — Adicionar StreamSubscription no booking document; cancelar em `dispose()`
- `functions/index.js` — Dois novos exports: `handlePixWebhook` e `expireUnpaidBookings`
- Firebase Secret Manager — Novo secret `MP_WEBHOOK_SECRET` deve ser configurado antes do deploy

</code_context>

<specifics>
## Specific Ideas

- Countdown deve ser proeminente mas não intrusivo — abaixo do texto "Válido até HH:mm", substituindo-o
- "Gerar novo QR" deve ser botão grande (FilledButton) com ícone de refresh — clara call-to-action
- A transição QR expirado → botão deve ser suave (sem rebuild abrupto)
- PixPaymentScreen auto-navegação ao confirmar: context.go('/bookings') não Navigator.pop (está em rota imperativa)

</specifics>

<deferred>
## Deferred Ideas

- Credenciais de produção Mercado Pago — pós-validação completa no sandbox
- Notificação push quando pagamento confirmado — possível Phase 19 ou v5
- Histórico de tentativas de pagamento — relatório futuro

</deferred>

---

*Phase: 18-webhook-confirmacao-em-tempo-real*
*Context gathered: 2026-04-08*
