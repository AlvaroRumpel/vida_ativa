# Roadmap: Vida Ativa

## Milestones

- ✅ **v1.0 MVP** — Phases 1–6 (shipped 2026-03-23)
- ✅ **v2.0 Funcionalidades Sociais & Admin** — Phases 7–11 (shipped 2026-03-31)
- 📋 **v3.0** — Phase 12+ (planned — awaiting client assets)

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

### 🔄 v3.0 Aprimoramentos de Reserva & Notificações

- [x] **Phase 12: Rebrand Visual** - Logo e paleta de cores do cliente aplicados em todas as telas (completed 2026-03-31)
- [x] **Phase 13: Admin Semana Contextualizada** - Admin vê label da semana atual, navega entre semanas, acessa detalhe de qualquer reserva via bottomsheet (ADMN-10, ADMN-11) (completed 2026-04-01)
- [ ] **Phase 14: Detalhe de Reserva (Cliente) + Aviso de Pagamento** - Cliente abre bottomsheet com detalhe completo; aviso de pagamento na confirmação (BOOK-04, BOOK-06)
- [ ] **Phase 15: Agendamento Recorrente** - Cliente cria múltiplas reservas semanais de uma vez, com gestão de conflitos (BOOK-05)
- [ ] **Phase 16: Push Notifications Admin** - Admin recebe web push (FCM) quando nova reserva é criada (NOTF-01)

Full details: `.planning/milestones/v3.0-ROADMAP.md`

## Phase Details

### Phase 13: Admin Semana Contextualizada
**Goal:** Admin vê qual semana está exibida nos slots, navega entre semanas e acessa detalhe de qualquer reserva
**Depends on:** v2.0 complete
**Requirements**: ADMN-10, ADMN-11
**Plans:** 2/2 plans complete

Plans:
- [ ] 13-01-PLAN.md — Week navigation e date chips na aba Slots (ADMN-10)
- [ ] 13-02-PLAN.md — AdminBookingDetailSheet + wire em BookingManagementTab (ADMN-11)

**Success Criteria:**
1. Aba Slots exibe label "31 mar – 6 abr" com botões ← → para navegar entre semanas
2. Day chips mostram dia + data real (ex: "Seg\n01")
3. Admin toca qualquer reserva (em Reservas ou em Slots) → bottomsheet com nome, status, horário, preço, participantes
4. Bottomsheet tem botões confirmar/recusar para reservas pendentes

### Phase 14: Detalhe de Reserva (Cliente) + Aviso de Pagamento
**Goal:** Cliente acessa detalhe de reserva com um toque; aviso de pagamento visível na confirmação
**Depends on:** Phase 13
**Requirements**: BOOK-04, BOOK-06
**Success Criteria:**
1. Toque em qualquer card em "Minhas Reservas" abre bottomsheet com detalhe completo
2. Bottomsheet exibe: data formatada, horário, preço, participantes, status badge, botões cancelar + compartilhar
3. Tela de confirmação de reserva exibe banner com aviso de pagamento antes do botão "Reservar"

### Phase 15: Agendamento Recorrente
**Goal:** Cliente cria múltiplas reservas semanais de uma vez, com gestão de conflitos
**Depends on:** Phase 14
**Requirements**: BOOK-05
**Success Criteria:**
1. Tela de confirmação tem opção "Reserva recorrente" com date picker de término
2. Preview lista todas as datas que serão reservadas
3. Após confirmar, todas as datas são criadas; conflitos listados em dialog de resultado
4. Sem novo modelo Firestore — cada reserva é um doc `bookings/{slotId}_{date}` normal

### Phase 16: Push Notifications Admin
**Goal:** Admin recebe notificação push no browser quando nova reserva é feita
**Depends on:** Phase 13
**Requirements**: NOTF-01
**Success Criteria:**
1. Admin autoriza notificações no browser → token FCM registrado
2. Nova reserva criada por cliente → admin recebe push notification
3. Notificação exibe nome do cliente e horário da reserva
4. Funciona com browser fechado (service worker)

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
| 13. Admin Semana Contextualizada | 2/2 | Complete    | 2026-04-01 | - |
| 14. Detalhe de Reserva (Cliente) + Aviso | v3.0 | 0/? | Pending | - |
| 15. Agendamento Recorrente | v3.0 | 0/? | Pending | - |
| 16. Push Notifications Admin | v3.0 | 0/? | Pending | - |
