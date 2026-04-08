# Roadmap: Vida Ativa

## Milestones

- ✅ **v1.0 MVP** — Phases 1–6 (shipped 2026-03-23)
- ✅ **v2.0 Funcionalidades Sociais & Admin** — Phases 7–11 (shipped 2026-03-31)
- ✅ **v3.0 Aprimoramentos de Reserva & Notificações** — Phases 12–16 (shipped 2026-04-06)
- 🚧 **v4.0 Pagamento Pix** — Phases 17–18 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1–6) — SHIPPED 2026-03-23</summary>

- [x] **Phase 1: Foundation** - Data models, Firebase wiring, PWA manifest, Firestore security rules bootstrap, go_router + BLoC structural setup (completed 2026-03-19)
- [x] **Phase 2: Auth** - Google Sign-In and email/password auth, route scaffold with role-based guards, persistent session (completed 2026-03-20)
- [x] **Phase 3: Schedule** - Read-only weekly slot display with available/booked/blocked states and price display (completed 2026-03-20)
- [x] **Phase 4: Booking** - Reserve a slot (atomic transaction), cancel own booking, view my bookings (completed 2026-03-20)
- [x] **Phase 5: Admin** - Slot CRUD, blocked dates, booking list with confirm/reject, configurable approval mode (completed 2026-03-23)
- [x] **Phase 6: PWA Hardening** - Final security rules deploy, service worker update strategy, iOS install banner, production deployment (completed 2026-03-23)

Full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

<details>
<summary>✅ v2.0 Funcionalidades Sociais & Admin (Phases 7–11) — SHIPPED 2026-03-31</summary>

- [x] **Phase 7: Visibilidade Social** - Reservas visíveis na agenda para todos os usuários; campo de participantes; admin vê participantes na listagem (completed 2026-03-25)
- [x] **Phase 8: Compartilhamento & Perfil** - Compartilhar reserva via WhatsApp; campo de telefone no cadastro e edição de perfil (completed 2026-03-25)
- [x] **Phase 9: Gestão de Usuários Admin** - Toggle admin/cliente sem troca de conta; promoção de usuários a admin pelo painel (completed 2026-03-26)
- [x] **Phase 10: Monitoramento de Erros** - Captura e registro de erros em produção via Sentry (completed 2026-03-26)
- [x] **Phase 11: Melhorias Visuais** - Agenda com layout Google Calendar; ajustes gerais de UI (espaçamentos, tipografia, consistência) (completed 2026-03-26)

Full details: `.planning/milestones/v2.0-ROADMAP.md`

</details>

<details>
<summary>✅ v3.0 Aprimoramentos de Reserva & Notificações (Phases 12–16) — SHIPPED 2026-04-06</summary>

- [x] **Phase 12: Rebrand Visual** - Logo e paleta de cores do cliente aplicados em todas as telas (completed 2026-03-31)
- [x] **Phase 13: Admin Semana Contextualizada** - Admin vê label da semana atual, navega entre semanas, acessa detalhe de qualquer reserva via bottomsheet (completed 2026-04-01)
- [x] **Phase 14: Detalhe de Reserva (Cliente) + Aviso de Pagamento** - Cliente abre bottomsheet com detalhe completo; aviso de pagamento na confirmação (completed 2026-04-01)
- [x] **Phase 15: Agendamento Recorrente** - Cliente cria múltiplas reservas semanais de uma vez, com gestão de conflitos (completed 2026-04-04)
- [x] **Phase 16: Push Notifications Admin** - Admin recebe web push (FCM) quando nova reserva é criada (completed 2026-04-05)

Full details: `.planning/milestones/v3.0-ROADMAP.md`

</details>

### 🚧 v4.0 Pagamento Pix (In Progress)

**Milestone Goal:** Cliente paga a reserva via Pix no app; pagamento confirmado automaticamente via webhook; slot liberado se pagamento expirar.

- [ ] **Phase 17: Pix QR Generation** - BookingModel estendido com status de pagamento; Cloud Function gera QR code Mercado Pago; Flutter exibe QR + copia-e-cola após reserva
- [ ] **Phase 18: Webhook + Confirmação em Tempo Real** - Cloud Function processa webhook idempotente; Flutter atualiza status em tempo real; timer de expiração + regeneração de QR; Cloud Function expira reservas após 45 min; admin vê status de pagamento e pode confirmar manualmente

## Phase Details

### Phase 17: Pix QR Generation
**Goal**: Cliente cria uma reserva e imediatamente recebe um QR code Pix para pagar, com o slot bloqueado durante a janela de pagamento
**Depends on**: Phase 16 (v3.0 complete)
**Requirements**: PIX-01, PIX-02
**Success Criteria** (what must be TRUE):
  1. Após criar reserva, cliente vê tela com QR code Pix e código copia-e-cola gerados pelo Mercado Pago
  2. Reserva criada fica com status `pending_payment` no Firestore; slot não aparece como disponível para outros clientes
  3. QR code tem validade de 30 min; campo `expiresAt` visível na reserva
  4. Cloud Function `createPixPayment` aceita bookingId, chama Mercado Pago, salva PaymentRecord em `/bookings/{id}/payment/{txId}` e retorna QR data
**Plans**: 2 plans
Plans:
- [ ] 17-01-PLAN.md — Camada de dados + CF (BookingModel, PaymentRecordModel, bookSlot bifurcado, ScheduleCubit, createPixPayment)
- [ ] 17-02-PLAN.md — Flutter UI (PixPaymentScreen, BookingConfirmationSheet dois botoes, BookingCard badges, MyBookingsScreen tap)

### Phase 18: Webhook + Confirmação em Tempo Real
**Goal**: Pagamento confirmado via webhook atualiza reserva para `confirmed`; reservas não pagas expiram automaticamente; admin e cliente veem status atualizado sem recarregar
**Depends on**: Phase 17
**Requirements**: PIX-03, PIX-04, PIX-05, PIX-06, PIX-07
**Success Criteria** (what must be TRUE):
  1. Cliente vê timer de contagem regressiva na tela de pagamento; após expirar, exibe botão "Gerar novo QR" sem precisar refazer a reserva
  2. Quando Mercado Pago confirma pagamento, status da reserva em "Minhas Reservas" atualiza para `confirmed` automaticamente (sem refresh)
  3. Cloud Function `handlePixWebhook` verifica assinatura do Mercado Pago, processa de forma idempotente usando transaction ID como chave, retorna 202 imediatamente; pagamento confirmado move reserva para `confirmed` ignorando modo de aprovação manual do admin
  4. Admin vê coluna/badge de status de pagamento na listagem de reservas e no bottomsheet de detalhe; botão "Confirmar manualmente" disponível para fallback
  5. Reservas em `pending_payment` sem pagamento são marcadas como `expired` e o slot é liberado automaticamente após 45 min pela Cloud Function `expireUnpaidBookings`
**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | 2/2 | Complete | 2026-03-19 |
| 2. Auth | v1.0 | 3/3 | Complete | 2026-03-20 |
| 3. Schedule | v1.0 | 2/2 | Complete | 2026-03-20 |
| 4. Booking | v1.0 | 2/2 | Complete | 2026-03-20 |
| 5. Admin | v1.0 | 2/2 | Complete | 2026-03-23 |
| 6. PWA Hardening | v1.0 | 2/2 | Complete | 2026-03-23 |
| 7. Visibilidade Social | v2.0 | 2/2 | Complete | 2026-03-25 |
| 8. Compartilhamento & Perfil | v2.0 | 2/2 | Complete | 2026-03-25 |
| 9. Gestão de Usuários Admin | v2.0 | 2/2 | Complete | 2026-03-26 |
| 10. Monitoramento de Erros | v2.0 | 2/2 | Complete | 2026-03-26 |
| 11. Melhorias Visuais | v2.0 | 2/2 | Complete | 2026-03-26 |
| 12. Rebrand Visual | v3.0 | 2/2 | Complete | 2026-03-31 |
| 13. Admin Semana Contextualizada | v3.0 | 2/2 | Complete | 2026-04-01 |
| 14. Detalhe de Reserva (Cliente) + Aviso | v3.0 | 2/2 | Complete | 2026-04-01 |
| 15. Agendamento Recorrente | v3.0 | 3/3 | Complete | 2026-04-04 |
| 16. Push Notifications Admin | v3.0 | 3/3 | Complete | 2026-04-05 |
| 17. Pix QR Generation | 1/2 | In Progress|  | - |
| 18. Webhook + Confirmação em Tempo Real | v4.0 | 0/? | Not started | - |
