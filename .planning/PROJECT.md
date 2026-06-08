# Vida Ativa

## What This Is

PWA de agendamento de quadra de areia (futevôlei/vôlei de praia) para a Academia Vida Ativa. Substitui o gerenciamento de reservas feito por listas no WhatsApp: clientes veem horários disponíveis, reservam pelo celular e pagam via Pix diretamente no app. Inclui confirmação automática de pagamento via webhook, expiração automática de reservas não pagas, visibilidade social entre jogadores, notificações push para admin, e painel admin completo com configuração de credenciais Mercado Pago.

**Status:** v6.0 live em `vida-ativa-94ba0.web.app`

## Core Value

Clientes conseguem reservar um horário de quadra em segundos, sem depender de mensagens no WhatsApp.

## Requirements

### Validated (v1.0)

- ✓ INFRA-01: Regras de segurança do Firestore com isAdmin() role-based + deployadas — v1.0
- ✓ INFRA-02: Modelos UserModel, SlotModel, BookingModel, BlockedDateModel com serialização Firestore — v1.0
- ✓ PWA-01: App instalável como PWA; iOS install banner; live em vida-ativa-94ba0.web.app — v1.0
- ✓ PWA-02: Interface mobile-first com BottomNavigationBar e roteamento go_router — v1.0
- ✓ AUTH-01: Login com Google (signInWithPopup) — v1.0
- ✓ AUTH-02: Login com email/senha — v1.0
- ✓ AUTH-03: Cadastro com email/senha — v1.0
- ✓ AUTH-04: Recuperação de senha por email — v1.0
- ✓ AUTH-05: Sessão persistente entre sessões do browser — v1.0
- ✓ SCHED-01: Usuário pode visualizar horários disponíveis/ocupados/bloqueados organizados por semana — v1.0
- ✓ SCHED-02: Usuário pode selecionar um dia para ver os slots daquele dia — v1.0
- ✓ SCHED-03: Preço do slot exibido na listagem — v1.0
- ✓ BOOK-01: Reserva atômica via Firestore transaction (anti-double-booking) — v1.0
- ✓ BOOK-02: Usuário pode cancelar sua própria reserva — v1.0
- ✓ BOOK-03: Usuário pode ver reservas futuras e passadas com status — v1.0
- ✓ ADMN-01: Admin pode criar e editar slots recorrentes (dia + horário + preço) — v1.0
- ✓ ADMN-02: Admin pode desativar slot recorrente sem excluí-lo — v1.0
- ✓ ADMN-03: Admin pode bloquear datas específicas — v1.0
- ✓ ADMN-04: Admin pode ver todas as reservas filtradas por data — v1.0
- ✓ ADMN-05: Admin pode confirmar ou recusar reservas pendentes — v1.0
- ✓ ADMN-06: Admin pode configurar modo de confirmação (automático ou manual) — v1.0

### Validated (v2.0)

- ✓ SOCIAL-01: Usuário pode ver o nome do cliente que reservou cada horário na agenda — v2.0
- ✓ SOCIAL-02: Usuário pode adicionar campo de texto com participantes ao fazer reserva — v2.0
- ✓ ADMN-09: Admin pode ver nome do cliente e participantes diretamente na listagem de reservas — v2.0
- ✓ SOCIAL-03: Usuário pode compartilhar reserva confirmada via WhatsApp — v2.0
- ✓ PROF-01: Usuário pode cadastrar número de telefone no fluxo de registro — v2.0
- ✓ PROF-02: Usuário pode editar telefone via BottomSheet no perfil — v2.0
- ✓ ADMN-07: Admin pode alternar para visão de cliente sem sair da conta — v2.0
- ✓ ADMN-08: Admin pode promover usuário cadastrado a administrador via painel admin — v2.0
- ✓ OPS-01: Erros em produção são capturados e registrados via Sentry — v2.0
- ✓ UI-02: Agenda exibe horários com layout inspirado no Google Calendar — v2.0
- ✓ UI-03: Ajustes gerais de UI — consistência visual, espaçamentos, tipografia — v2.0

### Validated (v3.0)

- ✓ ADMN-10: Admin vê label da semana atual e pode navegar entre semanas; day chips exibem data real — v3.0
- ✓ ADMN-11: Admin pode tocar em qualquer reserva e abrir bottomsheet com detalhe + ações — v3.0
- ✓ BOOK-04: Cliente pode tocar em qualquer reserva em "Minhas Reservas" e abrir bottomsheet com detalhe — v3.0
- ✓ BOOK-06: Na tela de confirmação de reserva, exibir aviso de pagamento — v3.0
- ✓ BOOK-05: Cliente pode criar reserva recorrente semanal com gestão de conflitos — v3.0
- ✓ NOTF-01: Admin recebe web push notification (FCM) quando nova reserva é criada — v3.0

### Validated (v4.0)

- ✓ PIX-01: Após reserva, cliente vê PixPaymentScreen com QR code e copia-e-cola gerados pelo Mercado Pago — v4.0
- ✓ PIX-02: Reserva criada com status `pending_payment`; slot bloqueado durante janela de pagamento — v4.0
- ✓ PIX-03: Cliente vê countdown timer; após expirar mostra botão "Gerar novo QR" sem refazer reserva — v4.0
- ✓ PIX-04: Quando MP confirma pagamento, status atualiza para `confirmed` automaticamente sem refresh — v4.0
- ✓ PIX-05: `handlePixWebhook` verifica assinatura MP, processa idempotente (txId como chave), retorna 202 imediatamente — v4.0
- ✓ PIX-06: Admin vê badge de status de pagamento; botão "Confirmar manualmente" disponível — v4.0
- ✓ PIX-07: Reservas `pending_payment` expiram após 45min e slot liberado via `expireUnpaidBookings` — v4.0
- ✓ D-01 a D-13: Admin configura credenciais Mercado Pago sem redeploy; kill switch Pix; regras Firestore isolam credenciais — v4.0

### Validated (v5.0)

- ✓ SPORT-01: Cliente vê dropdown "Esporte (opcional)" no formulário de reserva e pode selecionar esporte da lista configurável — Phase 20
- ✓ SPORT-02: Admin vê seção "Esportes" nas configurações e pode adicionar, remover e reordenar esportes — Phase 20
- ✓ SPORT-03: Lista padrão (Vôlei, Beach Tênis, Futevôlei) populada automaticamente se /config/sports não existir — Phase 20
- ✓ SPORT-04: Reservas antigas sem campo de esporte funcionam sem erro ou dado ausente — Phase 20
- ✓ DASH-01: Ao confirmar/cancelar reserva, contadores em /config/dashboard atualizam via Cloud Function — Phase 21
- ✓ DASH-02: Documentos de agregação existem para semana/mês/ano com receita, ocupação, clientes e distribuição por esporte — Phase 21
- ✓ DASH-03: DashboardCubit carrega dados e expõe estados de loading, dados e erro — Phase 21
- ✓ DASH-04: Regras Firestore permitem admin ler /config/dashboard; cliente não pode escrever — Phase 21
- ✓ DASH-05: Admin vê BarChart de receita por período (semana/mês/ano) — Phase 22
- ✓ DASH-06: Admin vê HeatMapCalendar hora×dia indicando horários mais reservados — Phase 22
- ✓ DASH-07: Admin vê PieChart de reservas por status (pendente/confirmado/cancelado/expirado) — Phase 22
- ✓ DASH-08: Admin vê PieChart donut de receita por esporte — Phase 22
- ✓ DASH-09: Admin alterna entre períodos semana/mês/ano e KPI cards atualizam — Phase 22
- ✓ DASH-10: Dashboard exibe métricas de ocupação (%), receita total, ticket médio, taxa de conversão — Phase 21/22
- ✓ DASH-11: Cloud Functions onBookingStateChange e scheduledDailyAggregation deployed e funcionais — Phase 21
- ✓ DASH-12: Admin vê chip de esporte em AdminBookingCard e info-row em AdminBookingDetailSheet — Phase 20

### Validated (v6.0)

- ✓ DS-01: Fontes Anton, Manrope, JetBrains Mono bundled offline em assets/google_fonts/ — Phase 23
- ✓ DS-02: AppTheme com paleta Arena (sand, paper, ink, concrete, lineHair, orange, orangeDk, court, sun) — Phase 23
- ✓ DS-03: AppTheme.display(), AppTheme.ui(), AppTheme.mono() disponíveis em todos os widgets — Phase 23
- ✓ DS-04: flutter build web --release PASS com design system completo — Phase 23
- ✓ NAV-01: BottomNavigationBar selecionado: ícone laranja + label mono uppercase — Phase 23
- ✓ NAV-02: BottomNavigationBar: fundo sand + borda superior hairline + sem elevação — Phase 23
- ✓ SCHED-04: Day selector SportDayStrip com colunas mono + número Anton; ativa tem underline laranja 2px — Phase 24
- ✓ SCHED-05: SlotHairlineRow sem Card — hairline divisória, Anton 42px, faixa laranja 3px em myBooking — Phase 24
- ✓ SCHED-06: Cabeçalho da agenda: wordmark "VIDA ATIVA" Anton + eyebrow mono com data — Phase 24
- ✓ ADMN-13: TabBar admin: labels JetBrains Mono uppercase, underline laranja 2px, fundo sand — Phase 25
- ✓ ADMN-14: Header admin: wordmark Arena + eyebrow "PAINEL ADMIN" + link "cliente →" laranja — Phase 25
- ✓ ADMN-15: Notification banner faixa laranja 2px à esquerda, sem container colorido — Phase 25
- ✓ BOOK-07: Confirmação: horário em Anton 88px sem bloco sólido — Phase 26
- ✓ BOOK-08: Aviso aprovação manual: faixa laranja 2px à esquerda, sem banner colorido — Phase 26
- ✓ BOOK-09: Botões "Pagar com Pix" / "Pagar na hora": SportBtn uppercase sem quebra — Phase 26
- ✓ BOOK-10: Minhas Reservas: próxima reserva em Anton 72px sem bloco preto — Phase 26
- ✓ BOOK-11: Minhas Reservas: eyebrow laranja "Próximo · hoje" — Phase 26
- ✓ BOOK-12: Demais reservas: HairlineBookingRow hairline com Anton 30px e status pill quiet — Phase 26
- ✓ ADMN-16: Aba Slots: SlotRow com Anton 32px, laranja se reservado, hairline sem Card — Phase 27
- ✓ ADMN-17: Aba Slots: AdminDaySelector com underline laranja + navegação ← → — Phase 27
- ✓ ADMN-18: Aba Reservas: AdminBookingRow com Anton 36px, Manrope nome, JBM status — Phase 27
- ✓ ADMN-19: Aba Reservas: BookingManagementTab integra AdminBookingRow com pills confirmar/recusar — Phase 27
- ✓ ADMN-20: Aba Usuários: UserDetailSheet DraggableScrollableSheet, CircleAvatar role-colors — Phase 27
- ✓ ADMN-21: Aba Usuários: UserRow hairline, CircleAvatar, Manrope/JBM typography — Phase 27
- ✓ ADMN-22: Aba Preços: faixas hairline, Anton 30px horário + Anton 44px preço, timeline laranja 3px — Phase 28
- ✓ ADMN-23: Aba Preços: SportBtn.filledInk no rodapé sticky — Phase 28
- ✓ ADMN-24: Aba Ajustes: Pix section Anton 26px, Switch sport (laranja/cinza) — Phase 28
- ✓ ADMN-25: Aba Ajustes: underline fields mono + eye toggle para credenciais MP — Phase 28
- ✓ ADMN-26: KPI cards em grid 2×N hairlines, Anton 32px, delta mono colorido, sem Card/sombra — Phase 29
- ✓ ADMN-27: Gráfico de receita com barras Container simples sem bordas arredondadas, labels mono — Phase 29
- ✓ ADMN-28: Heatmap 7×7 custom GridView com escala laranja rgba + status donut Arena 4 categorias — Phase 29
- ✓ ADMN-29: Receita por esporte em hairline rows com progress bar 3px laranja, share calculado client-side — Phase 29
- ✓ ADMN-30: KPI cards exibem sparkline de tendência (7 pontos diários) — `*Trend` fields em DashboardData — Phase 29+
- ✓ ADMN-31: Admin pode tocar em "?" ao lado de cada KPI e ver tooltip com descrição do dado — Phase 29+
- ✓ ADMN-32: Delta period-over-period (↑/↓ X.X%) exibido por KPI — campos `*Delta` em DashboardData — Phase 29+
- ✓ ADMN-33: Heatmap hora×dia desbloqueado — campo `heatmap` flat[49], `_heatmapFromFlat` reconstrói 7×7 — Phase 29+
- ✓ DEV-01: Script `scripts/seed_dashboard_staging.js` com dados realistas + trends + heatmap — Phase 29+
- ✓ VAL-01: Token audit PASS — zero cores hardcoded em pix_payment_screen + admin_screen (21 fixes) — Phase 30
- ✓ VAL-02: Token audit PASS — zero cores hardcoded em booking_confirmation_sheet (7 fixes) — Phase 30
- ✓ VAL-03: flutter analyze 0 erros + flutter build web --release PASS — Phase 30
- ✓ VAL-04: 48/48 widget tests passam (phases 26-29 coverage) — Phase 30
- ✓ VAL-05: Conformidade visual ponto-a-ponto 28/28 critérios PASS em 9 telas — Phase 30
- ✓ VAL-06: UAT manual aprovado — checklist 110 itens, aprovação 2026-06-08 — Phase 30

### Active

- [ ] UI-01: App exibe logo e paleta de cores fornecidas pelo cliente em todas as telas *(⚠️ BLOQUEADO — aguardando assets do cliente)*

### Out of Scope

- Login com número de telefone (OTP via SMS) — complexidade web reCAPTCHA; deferido
- Notificação push para cliente quando reserva confirmada/recusada — v5+
- Lembrete automático antes do horário reservado — v5+
- Prazo mínimo de cancelamento configurável pelo admin — v5+
- Domínio customizado — configurável manualmente no console Firebase Hosting
- Múltiplas academias / multi-tenant — v1/v2 exclusivo para Academia Vida Ativa
- Chat / mensagens entre usuário e admin — WhatsApp já cobre isso
- App nativo iOS/Android — PWA suficiente
- Dashboard de métricas/relatórios de ocupação — v5+
- Suporte offline completo — conflita com booking transactions

## Context

- **Stack:** Flutter Web, Firebase Auth (Google + email/password), Cloud Firestore, Firebase Hosting, Cloud Functions (Node.js 20), Mercado Pago SDK, flutter_bloc, go_router, sentry_flutter, url_launcher, calendar_view, fl_chart, flutter_heatmap_calendar, bloc_test, mocktail
- **Modelo de dados:** `/users`, `/slots`, `/bookings`, `/bookings/{id}/payment/{txId}`, `/blockedDates`, `/config/booking`, `/config/mercadopago`, `/config/pricing`, `/config/sports`, `/config/dashboard`, `/config/dashboard/periods/{week|month|year}`
- **BookingModel.status:** `pending` | `confirmed` | `cancelled` | `rejected` | `pending_payment` | `expired` | `refunded`
- **BookingModel.generateId(slotId, date)** → ID determinístico `{slotId}_{date}` — anti-double-booking via Transaction
- **BookingModel.sport:** campo opcional String — ausente em reservas antigas (backward compat)
- **Perfis:** `client` (reserva) e `admin` (gerencia) — `role: String` no Firestore; go_router guard + Firestore rules
- **Cloud Functions:** `notifyAdminNewBooking`, `createPixPayment`, `handlePixWebhook`, `expireUnpaidBookings`, `cancelPixPayment`, `adminConfirmPixPayment`, `updateSlotPricesFromTiers`, `onBookingStateChange`, `scheduledDailyAggregation`
- **Credenciais MP:** admin salva via SettingsCubit → Firestore `config/mercadopago`; CFs leem Firestore-first, Secret Manager fallback; cliente nunca lê (allow read: if false)
- **Codebase:** ~12,300 linhas Dart + ~1,189 linhas JS Cloud Functions (v6.0)
- **Monitoramento:** Sentry com kReleaseMode guard; DSN via --dart-define
- **Testes:** flutter_test + bloc_test + mocktail; 36 testes unitários cobrindo BookingModel, PriceTierModel, SettingsCubit, AppRouter, AuthCubit

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flutter Web como PWA | Academia já usa dispositivos variados; PWA evita app store | ✓ App instalável Android/iOS |
| Firebase Auth Google + email/password | Clientes têm Google; email como fallback | ✓ Implementado |
| Confirmação de reserva configurável | Academia pode querer aprovação manual | ✓ Toggle automático/manual no painel admin |
| Slots recorrentes + bookings por data | Separa configuração do horário da instância | ✓ generateId() previne double-booking |
| isAdmin() via role field no Firestore | Sem custom claims, sem Admin SDK | ✓ Simples e funcional |
| ViewMode como estado in-memory no BLoC | Admin toggle é UX preference, não dado persistido | ✓ Reset no logout é comportamento correto |
| Sentry com kReleaseMode guard | Evitar ruído no dashboard durante dev | ✓ Erros de produção capturados |
| Mercado Pago @mercadopago/sdk-node v2.0.0 | Mature API, exemplos extensos para Pix QR | ✓ createPixPayment funcional |
| PaymentRecord em `/bookings/{id}/payment/{txId}` | Isola dados de pagamento do booking doc | ✓ txId como chave de idempotência no webhook |
| Webhook retorna 202 antes de qualquer async | Previne retry do Mercado Pago em slow processing | ✓ handlePixWebhook implementado |
| Pix confirmado bypassa modo de aprovação manual | Pagamento já é confirmação suficiente | ✓ Admin pode cancelar manualmente depois |
| Credenciais MP em Firestore (primary) + Secret Manager (fallback) | Admin atualiza sem redeploy de CF | ✓ SettingsCubit → Firestore; getMpAccessToken/getMpWebhookSecret helpers |
| config/mercadopago allow read: if false | Token nunca exposto ao Flutter SDK | ✓ Regra Firestore específica tem precedência sobre wildcard |
| SettingsLoaded contém apenas bool flags (não valores dos tokens) | Segurança — token nunca no estado Flutter | ✓ isAccessTokenConfigured: bool |
| expireUnpaidBookings a cada 15min (não 45min) | Margem de segurança maior que expiresAt de 30min | ✓ Bookings expiram no máximo ~15min após vencimento |
| revenueBySport com lag D+1 | scheduledDailyAggregation (03:00 BRT) é o único escritor; onBookingStateChange só escreve deltas de contagem | ✓ Design intencional — aceito e documentado no UAT |
| MultiBlocProvider para SettingsTab | SportConfigCubit adicionado ao mesmo escopo de SettingsCubit em admin_screen.dart | ✓ Sem prop drilling; cubits co-localizados onde são consumidos |
| ValueNotifier para navegação FCM | navigateToReservasNotifier escutado em initState/_onFcmNavigation; _reservasTabIndex corrigido 2→3 após inserção do Dashboard | ✓ FCM "Ver" navega corretamente para aba Reservas |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-08 — v6.0 milestone closed; all v6.0 requirements moved to Validated; LOC updated to ~12,300 Dart*
