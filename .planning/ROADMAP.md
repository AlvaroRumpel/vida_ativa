# Roadmap: Vida Ativa

## Milestones

- ✅ **v1.0 MVP** — Phases 1–6 (shipped 2026-03-23)
- ✅ **v2.0 Funcionalidades Sociais & Admin** — Phases 7–11 (shipped 2026-03-31)
- ✅ **v3.0 Aprimoramentos de Reserva & Notificações** — Phases 12–16 (shipped 2026-04-06)
- ✅ **v4.0 Pagamento Pix** — Phases 17–19 (shipped 2026-05-08)
- ✅ **v5.0 Dashboard & Esportes** — Phases 20–22 (shipped 2026-05-23)
- ✅ **v6.0 Arena Esportivo — Redesign Visual** — Phases 23–30 (shipped 2026-06-08)

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

<details>
<summary>✅ v4.0 Pagamento Pix (Phases 17–19) — SHIPPED 2026-05-08</summary>

- [x] **Phase 17: Pix QR Generation** - BookingModel estendido com status de pagamento; Cloud Function gera QR code Mercado Pago; Flutter exibe QR + copia-e-cola após reserva (completed 2026-04-08)
- [x] **Phase 18: Webhook + Confirmação em Tempo Real** - Cloud Function processa webhook idempotente; Flutter atualiza status em tempo real; timer de expiração + regeneração de QR; Cloud Function expira reservas após 45 min; admin vê status de pagamento e pode confirmar manualmente (completed 2026-04-09)
- [x] **Phase 19: Admin Settings + Credenciais Pix** - Admin configura credenciais Mercado Pago pelo painel sem redeploy; kill switch Pix centralizado na aba Config; regras Firestore isolam credenciais (completed 2026-05-08)

Full details: `.planning/milestones/v4.0-ROADMAP.md`

</details>

<details>
<summary>✅ v5.0 Dashboard & Esportes (Phases 20–22) — SHIPPED 2026-05-23</summary>

- [x] **Phase 20: Infraestrutura de Esporte** - BookingModel estendido com campo sport opcional; coleção /config/sports; SportConfigCubit; dropdown de esporte no formulário de reserva (completed 2026-05-20)
- [x] **Phase 21: Backend do Dashboard** - Cloud Functions de agregação write-time (onBookingStateChange + scheduledDailyAggregation); schema /config/dashboard; DashboardCubit; regras Firestore (completed 2026-05-21)
- [x] **Phase 22: UI do Dashboard** - DashboardScreen com toggle semana/mês/ano; gráficos fl_chart (barra, pizza, donut); heatmap hora×dia; métricas de clientes (completed 2026-05-22)

Full details: `.planning/milestones/v5.0-ROADMAP.md`

</details>

<details>
<summary>✅ v6.0 Arena Esportivo — Redesign Visual (Phases 23–30) — SHIPPED 2026-06-08</summary>

- [x] **Phase 23: Design System + NavigationBar** - Font bundling em assets/google_fonts/, AppTheme Arena verificado, bottom navigation bar com tokens Arena (completed 2026-05-25)
- [x] **Phase 24: Agenda (Cliente)** - SportDayStrip underline laranja animado, SlotHairlineRow sem Card, wordmark "VIDA ATIVA" no cabeçalho (completed 2026-05-26)
- [x] **Phase 25: Estrutura Admin** - AppBar wordmark, TabBar underline laranja, notification banner faixa lateral laranja (completed 2026-05-27)
- [x] **Phase 26: Fluxo de Reserva (Cliente)** - Hora Anton 88px na confirmação, SportBtn, HairlineBookingRow com hero Anton 72px em Minhas Reservas (completed 2026-05-28)
- [x] **Phase 27: Admin Slots + Reservas + Usuários** - Três abas admin com rows hairline, tipografia Arena completa (completed 2026-06-05)
- [x] **Phase 28: Admin Preços + Ajustes** - Faixas de preço hairline Anton 44px, Switch sport, underline fields MP (completed 2026-06-05)
- [x] **Phase 29: Admin Dashboard** - KPI grid hairline, barras simples, heatmap escala laranja, receita por esporte (completed 2026-06-05)
- [x] **Phase 30: Validação Visual Arena** - Token audit (28 fixes), 48/48 widget tests, conformidade visual 28/28, UAT checklist 110 itens aprovado (completed 2026-06-08)

Full details: `.planning/milestones/v6.0-ROADMAP.md`

</details>

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
| 17. Pix QR Generation | v4.0 | 2/2 | Complete | 2026-04-08 |
| 18. Webhook + Confirmação em Tempo Real | v4.0 | 3/3 | Complete | 2026-04-09 |
| 19. Admin Settings + Credenciais Pix | v4.0 | 2/2 | Complete | 2026-05-08 |
| 20. Infraestrutura de Esporte | v5.0 | 3/3 | Complete | 2026-05-20 |
| 21. Backend do Dashboard | v5.0 | 3/3 | Complete | 2026-05-21 |
| 22. UI do Dashboard | v5.0 | 3/3 | Complete | 2026-05-23 |
| 23. Design System + NavigationBar | v6.0 | 3/3 | Complete   | 2026-05-25 |
| 24. Agenda (Cliente) | v6.0 | 1/1 | Complete | 2026-05-26 |
| 25. Estrutura Admin | v6.0 | 1/1 | Complete    | 2026-05-27 |
| 26. Fluxo de Reserva (Cliente) | v6.0 | 3/3 | Complete    | 2026-05-28 |
| 27. Admin Slots + Reservas + Usuários | v6.0 | 3/0 | Complete    | 2026-06-05 |
| 28. Admin Preços + Ajustes | v6.0 | 3/3 | Complete    | 2026-06-05 |
| 29. Admin Dashboard | v6.0 | 3/3 | Complete    | 2026-06-05 |
| 30. Validação Visual Arena | v6.0 | 4/4 | Complete   | 2026-06-08 |
