# Roadmap: Vida Ativa

## Milestones

- ✅ **v1.0 MVP** — Phases 1–6 (shipped 2026-03-23)
- ✅ **v2.0 Funcionalidades Sociais & Admin** — Phases 7–11 (shipped 2026-03-31)
- ✅ **v3.0 Aprimoramentos de Reserva & Notificações** — Phases 12–16 (shipped 2026-04-06)
- ✅ **v4.0 Pagamento Pix** — Phases 17–19 (shipped 2026-05-08)
- ✅ **v5.0 Dashboard & Esportes** — Phases 20–22 (shipped 2026-05-23)
- 🚧 **v6.0 Arena Esportivo — Redesign Visual** — Phases 23–29 (in progress)

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

### 🚧 v6.0 Arena Esportivo — Redesign Visual (In Progress)

**Milestone Goal:** Implementar a nova identidade visual esportiva em todas as telas do app, eliminando o "ar de IA" atual e aplicando o design system Arena Esportivo (sand/ink/laranja, Anton + Manrope + JetBrains Mono). Trabalho 100% widget-level — zero mudanças em BLoC, modelos ou Cloud Functions.

- [x] **Phase 23: Design System + NavigationBar** - Font bundling em assets/google_fonts/, verificação do AppTheme já construído, e aplicação dos tokens Arena na bottom navigation bar (completed 2026-05-25)
- [ ] **Phase 24: Agenda (Cliente)** - SportDayStrip (day selector underline), SlotHairlineRow (rows sem Card com faixa laranja), e wordmark "VIDA ATIVA" no cabeçalho
- [x] **Phase 25: Estrutura Admin** - AppBar wordmark, TabBar underline laranja, e notification banner com faixa lateral laranja no painel admin (completed 2026-05-27)
- [x] **Phase 26: Fluxo de Reserva (Cliente)** - Hora Anton 88px na confirmação, SportBtn para ações Pix, e HairlineBookingRow com hero Anton 72px em Minhas Reservas
 (completed 2026-05-28)
- [x] **Phase 27: Admin Slots + Reservas + Usuários** - Três abas admin com rows hairline usando padrões estabelecidos nas fases anteriores (completed 2026-06-05)
- [ ] **Phase 28: Admin Preços + Ajustes** - Faixas de preço hairline com Anton 44px, Switch sport, e underline fields para credenciais MP
- [ ] **Phase 29: Admin Dashboard** - KPI grid hairline, barras simples sem bordas, heatmap escala laranja, e receita por esporte com barra de progresso hairline

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
**Plans**: TBD
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
**Plans**: 3 plans
Plans:
- [x] 22-01-PLAN.md — Setup de dependências (fl_chart, flutter_heatmap_calendar) + test scaffold
- [x] 22-02-PLAN.md — DashboardTab widget base (toggle, KPI cards, estados) + integração AdminScreen
- [x] 22-03-PLAN.md — 4 gráficos fl_chart (BarChart, Heatmap, PieChart, Donut)
**UI hint**: yes

### Phase 23: Design System + NavigationBar
**Goal**: AppTheme Arena está verificado e publicado, fontes bundled offline, e bottom navigation bar exibe identidade Arena em todas as telas
**Depends on**: Phase 22 (v5.0 concluído)
**Requirements**: DS-01, DS-02, DS-03, DS-04, NAV-01, NAV-02
**Success Criteria** (what must be TRUE):
  1. App carrega Anton/Manrope/JetBrains Mono mesmo sem conexão de rede (fontes bundled em assets/google_fonts/)
  2. Bottom navigation bar exibe ícone laranja e label mono uppercase para aba selecionada, e cor concrete para abas inativas
  3. Bottom navigation bar tem fundo sand com borda superior hairline e sem elevação ou sombra visível
  4. Helpers AppTheme.display(), AppTheme.ui() e AppTheme.mono() produzem texto nas fontes corretas em qualquer widget que os chame
**Plans**: 3 plans
Plans:
- [x] 23-01-PLAN.md — Font bundling (assets/google_fonts/) + pubspec.yaml update + NavigationBar hairline border fix
- [x] 23-02-PLAN.md — Hardcoded color audit: admin_booking_card.dart + booking_confirmation_sheet.dart
- [x] 23-03-PLAN.md — Full build verification (flutter analyze + flutter build web --release)
**UI hint**: yes

### Phase 24: Agenda (Cliente)
**Goal**: A tela de agenda exibe identidade Arena completa — day selector underline, slot rows hairline com faixa laranja, e wordmark no cabeçalho
**Depends on**: Phase 23 (fontes bundled; AppTheme verificado)
**Requirements**: SCHED-04, SCHED-05, SCHED-06
**Success Criteria** (what must be TRUE):
  1. Day selector exibe colunas com abreviação mono + número Anton; a coluna do dia ativo tem underline laranja 2px (sem chip colorido)
  2. Slot rows não usam Card — cada row tem hairline divisória, horário em Anton 42px, e faixa lateral laranja 3px visível somente na reserva do próprio usuário
  3. Slot reservado por outro usuário exibe com opacity 0.45 sem faixa laranja
  4. Cabeçalho da agenda exibe wordmark "VIDA ATIVA" em Anton com pílula laranja e eyebrow mono com data do dia selecionado
**Plans**: TBD
**UI hint**: yes

### Phase 25: Estrutura Admin
**Goal**: O frame compartilhado do painel admin (AppBar, TabBar, notification banner) exibe identidade Arena, desbloqueando as fases de aba seguintes
**Depends on**: Phase 23 (AppTheme verificado; fontes bundled)
**Requirements**: ADMN-13, ADMN-14, ADMN-15
**Success Criteria** (what must be TRUE):
  1. TabBar do painel admin exibe labels em JetBrains Mono uppercase com indicador underline laranja 2px e fundo sand (sem fundo colorido ou Tab sólido)
  2. Header do painel admin exibe wordmark Arena + eyebrow "Painel admin" + link "cliente →" em mono laranja
  3. Notification banner de nova reserva exibe faixa lateral laranja 2px à esquerda sem container colorido de fundo
**Plans**: 1 plan
Plans:
- [x] 25-01-PLAN.md — Arena frame rewrite: inline header + TabBar body Column + orange-stripe notification banners
**UI hint**: yes

### Phase 26: Fluxo de Reserva (Cliente)
**Goal**: As telas de confirmação de reserva e Minhas Reservas exibem a identidade Arena com tipografia Anton heroica e rows hairline
**Depends on**: Phase 23 (AppTheme verificado; fontes bundled)
**Requirements**: BOOK-07, BOOK-08, BOOK-09, BOOK-10, BOOK-11, BOOK-12
**Success Criteria** (what must be TRUE):
  1. Tela de confirmação exibe horário do slot em Anton 88px como elemento principal visível (sem bloco preto ou hero card sólido)
  2. Aviso de aprovação manual é indicado por faixa lateral laranja 2px à esquerda do texto (sem banner colorido)
  3. Botões "Pagar com Pix" e "Pagar na hora" exibem texto Anton uppercase sem quebra de linha em viewport mobile padrão
  4. Seção "Próximo" em Minhas Reservas exibe horário em Anton 72px com eyebrow laranja "Próximo · hoje" sem bloco preto
  5. Demais reservas em Minhas Reservas exibem como rows hairline com data em Anton 30px e status como pill quiet
**Plans**: 3 plans
Plans:
- [x] 26-01-PLAN.md — SportBtn + HairlineBookingRow (novos widgets reutilizáveis)
- [x] 26-02-PLAN.md — BookingConfirmationSheet rewrite (hero 88px, stripe banner, SportBtn)
- [x] 26-03-PLAN.md — MyBookingsScreen rewrite (header inline, hero 72px, hairline rows)
**UI hint**: yes

### Phase 27: Admin Slots + Reservas + Usuários
**Goal**: As três abas operacionais do painel admin (Slots, Reservas, Usuários) exibem rows hairline com tipografia Arena, usando padrões das fases anteriores
**Depends on**: Phase 25 (frame admin Arena entregue); Phase 26 (HairlineBookingRow disponível para reuso)
**Requirements**: ADMN-16, ADMN-17, ADMN-18, ADMN-19, ADMN-20, ADMN-21
**Success Criteria** (what must be TRUE):
  1. Aba Slots exibe horários em Anton 32px (laranja se slot reservado), nome do reservante em Manrope, e switch sport para toggle ativo/inativo — sem Card com fundo colorido
  2. Day selector da aba Slots usa o mesmo padrão underline laranja com botões de navegação ← →
  3. Aba Reservas exibe horário em Anton 36px, nome e participantes em Manrope, status em mono uppercase colorido, e ações "Confirmar/Recusar" como pills sem fundo colorido
  4. Aba Usuários exibe avatar circular laranja para admin e ink para usuário comum, com nome em Manrope bold, email em mono, e contador de reservas em mono — sem gradiente
**Plans**: 3 plans
Plans:
- [x] 27-01-PLAN.md — Redesenho slot_management_tab.dart (ADMN-16, ADMN-17): hairline rows + AdminDaySelector underline laranja
- [x] 27-02-PLAN.md — AdminBookingRow + booking_management_tab.dart (ADMN-18, ADMN-19): novo widget, deletar AdminBookingCard
- [x] 27-03-PLAN.md — UserDetailSheet + users_management_tab.dart (ADMN-20, ADMN-21): hairline rows + bottom sheet Arena
**UI hint**: yes

### Phase 28: Admin Preços + Ajustes
**Goal**: As abas Preços e Ajustes do painel admin exibem layout hairline com SportBtn, Switch sport e underline fields, completando a identidade Arena no painel
**Depends on**: Phase 25 (frame admin Arena entregue)
**Requirements**: ADMN-22, ADMN-23, ADMN-24, ADMN-25
**Success Criteria** (what must be TRUE):
  1. Faixas de preço na aba Preços exibem horário em Anton 30px, barra de timeline laranja 3px sobre fundo lineHair, e preço em Anton 44px — sem card com sombra
  2. Botão "Salvar tabela" é um SportBtn ink fixado no rodapé da aba Preços
  3. Toggle Pix na aba Ajustes usa Switch sport (laranja quando ativo, cinza quando inativo) com labels em mono uppercase
  4. Campos de credencial Mercado Pago são underline fields em mono com ícone de olho para revelar valor
**Plans**: TBD
**UI hint**: yes

### Phase 29: Admin Dashboard
**Goal**: A aba Dashboard exibe métricas com a identidade Arena completa — KPI grid hairline, barras simples, heatmap laranja e receita por esporte
**Depends on**: Phase 25 (frame admin Arena entregue)
**Requirements**: ADMN-26, ADMN-27, ADMN-28, ADMN-29
**Success Criteria** (what must be TRUE):
  1. KPI cards exibem valor em Anton 32px e delta em mono colorido organizados em grid 2×N com hairlines divisórias — sem sombra ou Card elevado
  2. Gráfico de barras de receita exibe barras sem bordas arredondadas com labels em mono
  3. Heatmap de ocupação exibe células com escala de intensidade laranja (de transparente a laranja sólido) em vez de cores do calendário padrão
  4. Seção de receita por esporte exibe barra de progresso hairline 3px laranja com valor em Anton e label em mono
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
| 20. Infraestrutura de Esporte | v5.0 | 3/3 | Complete | 2026-05-20 |
| 21. Backend do Dashboard | v5.0 | 3/3 | Complete | 2026-05-21 |
| 22. UI do Dashboard | v5.0 | 3/3 | Complete | 2026-05-23 |
| 23. Design System + NavigationBar | v6.0 | 3/3 | Complete   | 2026-05-25 |
| 24. Agenda (Cliente) | v6.0 | 0/? | Not started | - |
| 25. Estrutura Admin | v6.0 | 1/1 | Complete    | 2026-05-27 |
| 26. Fluxo de Reserva (Cliente) | v6.0 | 3/3 | Complete    | 2026-05-28 |
| 27. Admin Slots + Reservas + Usuários | v6.0 | 3/0 | Complete    | 2026-06-05 |
| 28. Admin Preços + Ajustes | v6.0 | 0/? | Not started | - |
| 29. Admin Dashboard | v6.0 | 0/? | Not started | - |
