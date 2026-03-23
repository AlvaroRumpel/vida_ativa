# Vida Ativa

## What This Is

PWA de agendamento de quadra de areia (futevôlei/vôlei de praia) para a Academia Vida Ativa. Substitui o gerenciamento de reservas feito por listas no WhatsApp, permitindo que clientes vejam horários disponíveis e reservem pelo celular, enquanto admins controlam a agenda e confirmam reservas.

## Core Value

Clientes conseguem reservar um horário de quadra em segundos, sem depender de mensagens no WhatsApp.

## Requirements

### Validated

- ✓ Projeto Flutter Web criado com suporte a PWA — existente
- ✓ Firebase inicializado (firebase_options.dart gerado) — existente
- ✓ Dependências instaladas: firebase_core, firebase_auth, cloud_firestore — existente
- ✓ main.dart inicializa Firebase corretamente — existente
- ✓ INFRA-01: firestore.rules deployável com bootstrap de autenticação — Validated in Phase 1: Foundation
- ✓ INFRA-02: Modelos UserModel, SlotModel, BookingModel, BlockedDateModel com serialização Firestore — Validated in Phase 1: Foundation
- ✓ PWA-01: manifest.json com nome "Vida Ativa", theme_color verde, display standalone, ícones maskable — Validated in Phase 1: Foundation
- ✓ PWA-02: App shell mobile-first com BottomNavigationBar e roteamento go_router — Validated in Phase 1: Foundation
- ✓ AUTH-01: Login com Google (signInWithPopup) — Validated in Phase 2: Auth
- ✓ AUTH-02: Login com email/senha — Validated in Phase 2: Auth
- ✓ AUTH-03: Cadastro com email/senha — Validated in Phase 2: Auth
- ✓ AUTH-04: Recuperação de senha por email — Validated in Phase 2: Auth
- ✓ AUTH-05: Sessão persistente entre sessões do browser — Validated in Phase 2: Auth
- ✓ SCHED-01: Usuário pode visualizar horários disponíveis/ocupados/bloqueados organizados por semana — Validated in Phase 3: Schedule
- ✓ SCHED-02: Usuário pode selecionar um dia para ver os slots daquele dia — Validated in Phase 3: Schedule
- ✓ SCHED-03: Preço do slot exibido na listagem — Validated in Phase 3: Schedule
- ✓ PWA-01 (finalized): iOS install banner via SnackBar; apple-mobile-web-app-title = "Vida Ativa"; app deployed to vida-ativa-94ba0.web.app — Validated in Phase 6: PWA Hardening
- ✓ INFRA-01 (finalized): Firestore rules with isAdmin() checking role == "admin", per-collection RBAC deployed; unauthenticated writes denied — Validated in Phase 6: PWA Hardening

### Active

- [ ] Usuário pode fazer login com Google ou número de telefone
- [ ] Usuário pode visualizar horários disponíveis para reserva na semana
- [ ] Usuário pode reservar um horário disponível
- [ ] Usuário pode cancelar sua própria reserva
- [ ] Sistema impede dupla reserva no mesmo slot/dia
- [x] Admin pode criar e gerenciar slots recorrentes (dia da semana + horário + preço) — Validated in Phase 5: Admin
- [x] Admin pode bloquear datas específicas (feriados, manutenção, etc.) — Validated in Phase 5: Admin
- [x] Admin pode visualizar todas as reservas — Validated in Phase 5: Admin
- [x] Admin pode confirmar ou recusar reservas pendentes — Validated in Phase 5: Admin
- [x] Fluxo de confirmação de reserva é configurável (automático ou requer aprovação do admin) — Validated in Phase 5: Admin
- [x] App é instalável como PWA no celular — Validated in Phase 6: PWA Hardening

### Out of Scope

- Pagamento online — pagamento é presencial; app gerencia só o agendamento
- Múltiplas academias — v1 é exclusivo para a Academia Vida Ativa
- Notificações push — pode entrar em v2
- App nativo (iOS/Android) — PWA é suficiente para v1
- Chat ou mensagens entre usuários e admins

## Context

- Stack: Flutter Web, Firebase Auth (Google + email/password), Cloud Firestore, Firebase Hosting, flutter_bloc, go_router
- Modelo de dados implementado: `/users`, `/slots`, `/bookings`, `/blockedDates` — com serialização Firestore e Equatable
- Slots são recorrentes (ex: toda segunda às 08h); bookings são instâncias para uma data específica
- BookingModel.generateId(slotId, date) → ID determinístico `{slotId}_{date}` — anti-double-booking via Transaction
- Perfis: `client` (reserva) e `admin` (gerencia) — role guard no go_router em Phase 2
- Estrutura de pastas implementada: `lib/features/{auth,schedule,booking,admin}/ui/` + `lib/core/{models,theme,router}`
- FlutterFire configurado; app shell com BottomNav (Agenda/Minhas Reservas/Perfil) + rotas /admin e /login

**Current state:** Phase 6 complete — all 6 phases done. App is live at vida-ativa-94ba0.web.app. Production Firestore rules with isAdmin() role-based access deployed. iOS install SnackBar in AppShell. PWA title "Vida Ativa" fixed. v1 milestone complete.

## Constraints

- **Stack**: Flutter Web / Firebase — já decidido e configurado
- **Plataforma**: PWA only para v1 — web-first, mobile via browser/instalação
- **Pagamento**: Fora do escopo — só agendamento

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flutter Web como PWA | Academia já usa dispositivos variados; PWA evita app store | — Pending |
| Firebase Auth com Google + Phone | Clientes têm Google; Phone Auth como fallback sem email | — Pending |
| Confirmação de reserva configurável | Academia pode querer aprovação manual no início, depois automatizar | — Pending |
| Slots recorrentes + bookings por data | Separa a configuração do horário da instância de reserva | — Pending |

---
*Last updated: 2026-03-23 after Phase 6: PWA Hardening complete — v1 milestone done*
