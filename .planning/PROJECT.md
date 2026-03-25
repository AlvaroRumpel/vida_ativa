# Vida Ativa

## What This Is

PWA de agendamento de quadra de areia (futevôlei/vôlei de praia) para a Academia Vida Ativa. Substitui o gerenciamento de reservas feito por listas no WhatsApp, permitindo que clientes vejam horários disponíveis e reservem pelo celular, enquanto admins controlam a agenda, confirmam reservas e configuram o fluxo de aprovação.

**Status:** v2.0 em desenvolvimento — v1.0 live em `vida-ativa-94ba0.web.app`

## Current Milestone: v2.0 Funcionalidades Sociais & Admin

**Goal:** Adicionar visibilidade social entre jogadores, melhorar UX do admin, e integrar monitoramento de erros em produção.

**Target features:**
- Visibilidade de reservas entre clientes (nomes visíveis na agenda)
- Campo de participantes na reserva
- Compartilhar reserva via WhatsApp
- Campo de telefone no cadastro
- Alternância Admin ↔ Cliente sem trocar de conta
- Promoção de usuários a admin no painel
- Agenda estilo Google Calendar
- Refatoração visual com logo e cores do cliente (bloqueado até receber assets)
- Monitoramento de erros em produção

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

### Active (v2.0)

- ✓ SOCIAL-01: Usuário pode ver o nome do cliente que reservou cada horário na agenda — Validated in Phase 07: Visibilidade Social
- ✓ SOCIAL-02: Usuário pode adicionar campo de texto com participantes ao fazer reserva — Validated in Phase 07: Visibilidade Social
- ✓ ADMN-09: Admin pode ver nome do cliente e participantes diretamente na listagem de reservas — Validated in Phase 07: Visibilidade Social
- [ ] SOCIAL-03: Usuário pode compartilhar reserva confirmada via WhatsApp com mensagem pré-formatada
- [ ] PROF-01: Usuário pode cadastrar número de telefone no fluxo de registro/perfil
- [ ] ADMN-07: Admin pode alternar para visão de cliente sem sair da conta (toggle na tela de Perfil)
- [ ] ADMN-08: Admin pode promover usuário cadastrado a administrador via painel admin
- [ ] UI-01: App exibe logo e paleta de cores fornecidas pelo cliente em todas as telas (⚠️ bloqueado até receber assets)
- [ ] UI-02: Agenda exibe horários com layout inspirado no Google Calendar
- [ ] OPS-01: Erros em produção são capturados e registrados em ferramenta de monitoramento

### Future (v3.0+)

- Login com número de telefone (OTP via SMS) — complexidade web reCAPTCHA; deferido de v1
- Notificação push quando reserva é confirmada/recusada — infra significativa; v3
- Lembrete automático antes do horário reservado — v3
- Prazo mínimo de cancelamento configurável pelo admin — v3
- Domínio customizado (ex: vidaativa.com.br) — pode ser configurado manualmente no console Firebase Hosting

### Out of Scope

- Pagamento online — pagamento é presencial; fora do escopo explícito
- Múltiplas academias / multi-tenant — v1 é exclusivo para Academia Vida Ativa
- Chat / mensagens entre usuário e admin — WhatsApp já cobre isso
- App nativo iOS/Android — PWA é suficiente para v1
- Ver nome de outros clientes no slot — era privacidade em v1; decisão revertida em v2.0 a pedido do dono da academia (SOCIAL-01)
- Suporte offline completo — conflita com booking transactions; deferido

## Context

- **Stack:** Flutter Web, Firebase Auth (Google + email/password), Cloud Firestore, Firebase Hosting, flutter_bloc, go_router
- **Modelo de dados:** `/users`, `/slots`, `/bookings`, `/blockedDates`, `/config/booking` — serialização Firestore + Equatable
- **Slots recorrentes** (ex: toda segunda às 08h); bookings são instâncias para uma data específica
- **BookingModel.generateId(slotId, date)** → ID determinístico `{slotId}_{date}` — anti-double-booking via Transaction
- **Perfis:** `client` (reserva) e `admin` (gerencia) — `role: String` no Firestore; go_router guard + Firestore rules
- **Estrutura de pastas:** `lib/features/{auth,schedule,booking,admin}/ui/` + `lib/core/{models,theme,router,pwa}`
- **Codebase:** ~3,831 linhas de Dart (v1.0)

**Current state:** v2.0 em desenvolvimento — v1.0 live em `vida-ativa-94ba0.web.app`. 21 requirements v1 entregues. Phase 07 complete — visibilidade social (SOCIAL-01, SOCIAL-02, ADMN-09) entregues. v2.0 foca em funcionalidades sociais, UX admin, e monitoramento de erros (10 requirements, 6 fases a partir da 07).

## Constraints

- **Stack:** Flutter Web / Firebase — já decidido e configurado
- **Plataforma:** PWA only para v1 — web-first, mobile via browser/instalação
- **Pagamento:** Fora do escopo — só agendamento

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flutter Web como PWA | Academia já usa dispositivos variados; PWA evita app store | ✓ Funcionou — app instalável no Android/iOS |
| Firebase Auth com Google + email/password | Clientes têm Google; email como fallback | ✓ Implementado; phone auth deferido para v2 |
| Confirmação de reserva configurável | Academia pode querer aprovação manual no início | ✓ Toggle automático/manual no painel admin |
| Slots recorrentes + bookings por data | Separa configuração do horário da instância de reserva | ✓ Cleanly separados; generateId() previne double-booking |
| isAdmin() via role field no Firestore | Sem custom claims, sem Admin SDK | ✓ role == "admin" — simples e funcional |
| iOS install banner sempre que acessado via Safari | Sem localStorage "shown once" — simplicidade | ✓ SnackBar não intrusivo via addPostFrameCallback |
| dart:ui_web para iOS detection | dart:js deprecated; dart:ui_web nativo ao Flutter | ✓ Sem JS interop necessário |

---
*Last updated: 2026-03-25 after v2.0 milestone started*
