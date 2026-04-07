# Vida Ativa

## What This Is

PWA de agendamento de quadra de areia (futevôlei/vôlei de praia) para a Academia Vida Ativa. Substitui o gerenciamento de reservas feito por listas no WhatsApp, permitindo que clientes vejam horários disponíveis e reservem pelo celular. Inclui visibilidade social entre jogadores (quem reservou, com quem vai jogar), compartilhamento via WhatsApp, toggle admin/cliente, promoção de usuários e monitoramento de erros em produção.

**Status:** v2.0 live em `vida-ativa-94ba0.web.app` — aguardando assets do cliente para v3.0 (rebrand visual)

## Core Value

Clientes conseguem reservar um horário de quadra em segundos, sem depender de mensagens no WhatsApp.

## Requirements

### Validated (v1.0)

- ✓ Projeto Flutter Web criado com suporte a PWA — existente
- ✓ Firebase inicializado (firebase_options.dart gerado) — existente
- ✓ Dependências instaladas: firebase_core, firebase_auth, cloud_firestore — existente
- ✓ main.dart inicializa Firebase corretamente — existente
- ✓ INFRA-01: Regras de segurança do Firestore com isAdmin() role-based + deployadas — v1.0
- ✓ INFRA-02: Modelos UserModel, SlotModel, BookingModel, BlockedDateModel com serialização Firestore — v1.0
- ✓ PWA-01: App instalável como PWA; iOS install banner; apple-mobile-web-app-title = "Vida Ativa"; live em vida-ativa-94ba0.web.app — v1.0
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
- ✓ SOCIAL-03: Usuário pode compartilhar reserva confirmada via WhatsApp com mensagem pré-formatada — v2.0
- ✓ PROF-01: Usuário pode cadastrar número de telefone no fluxo de registro — v2.0
- ✓ PROF-02: Usuário pode editar telefone via BottomSheet no perfil — v2.0
- ✓ ADMN-07: Admin pode alternar para visão de cliente sem sair da conta — v2.0
- ✓ ADMN-08: Admin pode promover usuário cadastrado a administrador via painel admin — v2.0
- ✓ OPS-01: Erros em produção são capturados e registrados via Sentry — v2.0
- ✓ UI-02: Agenda exibe horários com layout inspirado no Google Calendar — v2.0
- ✓ UI-03: Ajustes gerais de UI — consistência visual, espaçamentos, tipografia — v2.0

### Validated (v3.0)

- ✓ ADMN-10: Admin vê label de semana contextualizada + navegação ← → entre semanas — v3.0
- ✓ ADMN-11: Admin abre detalhe completo de qualquer reserva via bottomsheet — v3.0
- ✓ BOOK-04: Cliente abre detalhe de reserva via bottomsheet em "Minhas Reservas" — v3.0
- ✓ BOOK-06: Aviso explícito de pagamento exibido na confirmação de reserva — v3.0
- ✓ BOOK-05: Agendamento recorrente semanal com data de término; conflitos ignorados — v3.0
- ✓ NOTF-01: Push notifications FCM para admin quando nova reserva é criada — v3.0

## Current Milestone: v4.0 Pagamento Pix

**Goal:** Tornar o app modular via feature toggles por academia e integrar pagamento Pix automático no fluxo de reserva.

**Target features:**
- Pagamento Pix automático — QR code gerado na reserva, confirmação via webhook (Mercado Pago)

### Active (v4.0)

- [ ] PIX-01: Cliente pode pagar a reserva via Pix QR code + copia-e-cola gerado no app após criar reserva
- [ ] PIX-02: Reserva fica em status `pending_payment`; slot bloqueado por 30 min durante janela de pagamento
- [ ] PIX-03: App exibe timer de expiração do QR code; botão regenerar QR sem refazer a reserva
- [ ] PIX-04: Cloud Function recebe webhook do Mercado Pago, verifica assinatura, processa idempotente
- [ ] PIX-05: Cliente vê status de pagamento em tempo real em "Minhas Reservas"
- [ ] PIX-06: Admin vê status de pagamento no painel e pode confirmar manualmente se webhook falhar
- [ ] PIX-07: Cloud Function expira reservas não pagas após 45 min; libera slot

### Active (v3.0 pendente)

- [ ] UI-01: App exibe logo e paleta de cores fornecidas pelo cliente em todas as telas *(⚠️ BLOQUEADO — aguardando assets do cliente)*

### Future (v4.0+)

- Login com número de telefone (OTP via SMS) — complexidade web reCAPTCHA; deferido de v1
- Lembrete automático antes do horário reservado
- Prazo mínimo de cancelamento configurável pelo admin
- Domínio customizado (ex: vidaativa.com.br) — pode ser configurado manualmente no console Firebase Hosting
- Multi-tenant completo com seleção de academia no login — arquitetura base em v4.0, UI em v5+

### Out of Scope

- Pagamento online com cartão de crédito/débito — Pix em v4.0; cartão é complexidade extra desnecessária agora
- Múltiplas academias / multi-tenant — v1/v2 é exclusivo para Academia Vida Ativa
- Chat / mensagens entre usuário e admin — WhatsApp já cobre isso
- App nativo iOS/Android — PWA é suficiente
- Ver nome de outros clientes no slot — era privacidade em v1; decisão revertida em v2.0 a pedido do dono da academia (SOCIAL-01)
- Suporte offline completo — conflita com booking transactions; deferido
- Dashboard de métricas/relatórios de ocupação — Alta complexidade; pode ser v3+

## Context

- **Stack:** Flutter Web, Firebase Auth (Google + email/password), Cloud Firestore, Firebase Hosting, flutter_bloc, go_router, sentry_flutter, url_launcher, calendar_view
- **Modelo de dados:** `/users`, `/slots`, `/bookings`, `/blockedDates`, `/config/booking` — serialização Firestore + Equatable
- **Slots recorrentes** (ex: toda segunda às 08h); bookings são instâncias para uma data específica
- **BookingModel.generateId(slotId, date)** → ID determinístico `{slotId}_{date}` — anti-double-booking via Transaction
- **Perfis:** `client` (reserva) e `admin` (gerencia) — `role: String` no Firestore; go_router guard + Firestore rules
- **ViewMode (admin/client):** estado in-memory no AuthAuthenticated; admin pode ver app como cliente sem logout
- **Estrutura de pastas:** `lib/features/{auth,schedule,booking,admin}/ui/` + `lib/core/{models,theme,router,pwa,utils}`
- **Codebase:** ~6,236 linhas de Dart (v2.0) — +2,405 desde v1.0
- **Monitoramento:** Sentry com kReleaseMode guard; DSN via --dart-define; SentryUser com Firebase UID apenas (sem PII)
- **Deploy:** `firebase deploy --only hosting,firestore:rules` — atomiza app + rules em único comando

## Constraints

- **Stack:** Flutter Web / Firebase — já decidido e configurado
- **Plataforma:** PWA only — web-first, mobile via browser/instalação
- **Pagamento:** Fora do escopo — só agendamento

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flutter Web como PWA | Academia já usa dispositivos variados; PWA evita app store | ✓ Funcionou — app instalável no Android/iOS |
| Firebase Auth com Google + email/password | Clientes têm Google; email como fallback | ✓ Implementado; phone auth deferido para v3 |
| Confirmação de reserva configurável | Academia pode querer aprovação manual no início | ✓ Toggle automático/manual no painel admin |
| Slots recorrentes + bookings por data | Separa configuração do horário da instância de reserva | ✓ Cleanly separados; generateId() previne double-booking |
| isAdmin() via role field no Firestore | Sem custom claims, sem Admin SDK | ✓ role == "admin" — simples e funcional |
| iOS install banner sempre que acessado via Safari | Sem localStorage "shown once" — simplicidade | ✓ SnackBar não intrusivo via addPostFrameCallback |
| dart:ui_web para iOS detection | dart:js deprecated; dart:ui_web nativo ao Flutter | ✓ Sem JS interop necessário |
| ViewMode como estado in-memory no BLoC | Admin toggle é UX preference, não dado persistido | ✓ Sem round-trip Firestore; reset no logout é comportamento correto |
| Sentry com kReleaseMode guard | Evitar ruído no dashboard durante dev; DSN via --dart-define | ✓ Erros de produção capturados; 0 DSN no source code |
| calendar_view: 2.0.0 pin exato | 2.x pode ter breaking changes por minor version | ✓ DayView estável; SlotEventTile integrado sem regressão |
| WhatsApp share via wa.me/?text= (sem número) | Universal link — funciona sem WhatsApp instalado no web | ✓ Compartilhamento funciona em todos os browsers |
| FieldValue.delete() para campos nullable no Firestore | Evitar strings vazias no banco; padrão consistente | ✓ Aplicado em participants (Phase 07), phone (Phase 08) |

---
*Last updated: 2026-04-06 after v4.0 milestone start*
