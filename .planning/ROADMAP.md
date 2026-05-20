# Roadmap: Vida Ativa

## Milestones

- ✅ **v1.0 MVP** — Phases 1–6 (shipped 2026-03-23)
- ✅ **v2.0 Funcionalidades Sociais & Admin** — Phases 7–11 (shipped 2026-03-31)
- ✅ **v3.0 Aprimoramentos de Reserva & Notificações** — Phases 12–16 (shipped 2026-04-06)
- ✅ **v4.0 Pagamento Pix** — Phases 17–19 (shipped 2026-05-08)
- 🔄 **v5.0 Dashboard & Esportes** — Phases 20–22 (in progress)

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

### v5.0 Dashboard & Esportes (Phases 20–22)

- [ ] **Phase 20: Infraestrutura de Esporte** - BookingModel estendido com campo sport opcional; coleção /config/sports; SportConfigCubit; dropdown de esporte no formulário de reserva
- [ ] **Phase 21: Backend do Dashboard** - Cloud Functions de agregação write-time (onBookingStateChange + scheduledDailyAggregation); schema /config/dashboard; DashboardCubit; regras Firestore
- [ ] **Phase 22: UI do Dashboard** - DashboardScreen com toggle semana/mês/ano; gráficos fl_chart (linha, barra, pizza, donut); heatmap hora×dia; métricas de clientes

## Phase Details

### Phase 20: Infraestrutura de Esporte
**Goal**: Clientes podem selecionar esporte ao reservar e admin pode gerenciar a lista de esportes
**Depends on**: Phase 19 (BookingModel já estendido com payment fields — padrão de extensão nullable)
**Requirements**: SPORT-01, SPORT-02, SPORT-03, SPORT-04
**Success Criteria** (what must be TRUE):
  1. Cliente vê dropdown "Esporte (opcional)" no formulário de reserva e pode selecionar Vôlei, Beach Tênis ou Futevôlei
  2. Admin vê seção "Esportes" nas configurações e pode adicionar, remover e reordenar esportes da lista
  3. Sistema popula automaticamente a lista padrão (Vôlei, Beach Tênis, Futevôlei) se /config/sports não existir
  4. Reservas antigas sem campo de esporte abrem normalmente sem erro ou dado ausente visível inesperado
**Plans**: 3 plans
- [x] 20-01-PLAN.md — BookingModel sport field + SportConfigCubit + AdminScreen provider (foundation, Wave 1)
- [x] 20-02-PLAN.md — Cliente UX: dropdown no BookingConfirmationSheet + propagação em bookSlot/bookRecurring (Wave 2)
- [ ] 20-03-PLAN.md — Admin UX: seção Esportes no SettingsTab + chip em AdminBookingCard/DetailSheet (Wave 2)
**UI hint**: yes

### Phase 21: Backend do Dashboard
**Goal**: Dados agregados de ocupação, receita e clientes estão disponíveis e atualizados no Firestore para consumo pela UI
**Depends on**: Phase 20 (campo sport em BookingModel necessário para agregação por esporte)
**Requirements**: DASH-01, DASH-02, DASH-03, DASH-04, DASH-09, DASH-10, DASH-11, DASH-12
**Success Criteria** (what must be TRUE):
  1. Ao confirmar ou cancelar uma reserva, os contadores em /config/dashboard atualizam automaticamente via Cloud Function sem intervenção manual
  2. Documentos de agregação diária existem para semana, mês e ano correntes com campos de receita, ocupação, contagem de clientes e distribuição por esporte
  3. DashboardCubit carrega dados de /config/dashboard e expõe estados de loading, dados e erro corretamente
  4. Regras Firestore permitem admin ler /config/dashboard mas bloqueiam escrita direta do cliente Flutter (somente Cloud Functions escrevem)
**Plans**: TBD

### Phase 22: UI do Dashboard
**Goal**: Admin vê painel completo com gráficos e métricas interativas de ocupação, receita e clientes
**Depends on**: Phase 21 (DashboardCubit com dados disponíveis)
**Requirements**: DASH-05, DASH-06, DASH-07, DASH-08
**Success Criteria** (what must be TRUE):
  1. Admin alterna entre períodos semana/mês/ano e todos os cards de métrica (ocupação, receita, ticket médio, taxa de conversão, no-show) atualizam na mesma tela
  2. Admin vê gráfico de linha ou barra com evolução de receita ao longo do período selecionado
  3. Admin vê heatmap hora×dia indicando os horários mais reservados da semana
  4. Admin vê gráfico pizza com distribuição de reservas por status e, quando há dados de esporte, gráfico donut de distribuição por esporte
**Plans**: TBD
**UI hint**: yes

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
| 20. Infraestrutura de Esporte | v5.0 | 2/3 | In Progress|  |
| 21. Backend do Dashboard | v5.0 | 0/? | Not started | - |
| 22. UI do Dashboard | v5.0 | 0/? | Not started | - |
