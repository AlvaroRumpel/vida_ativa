# Vida Ativa

## What This Is

PWA de agendamento de quadra de areia (futevôlei/vôlei de praia) para a Academia Vida Ativa. Substitui o gerenciamento de reservas feito por listas no WhatsApp, permitindo que clientes vejam horários disponíveis e reservem pelo celular, enquanto admins controlam a agenda, confirmam reservas e configuram o fluxo de aprovação.

**Status:** v1.0 shipped — live at `vida-ativa-94ba0.web.app`

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

### Active (v2.0 candidates)

- [ ] Login com número de telefone (OTP via SMS) — AUTH-v2-01
- [ ] Notificação push quando reserva é confirmada/recusada — NOTF-v2-01
- [ ] Lembrete automático antes do horário reservado — NOTF-v2-02
- [ ] Prazo mínimo de cancelamento configurável pelo admin — BOOK-v2-01
- [ ] Domínio customizado (ex: vidaativa.com.br) via Firebase Hosting console

### Out of Scope

- Pagamento online — pagamento é presencial; fora do escopo explícito
- Múltiplas academias / multi-tenant — v1 é exclusivo para Academia Vida Ativa
- Chat / mensagens entre usuário e admin — WhatsApp já cobre isso
- App nativo iOS/Android — PWA é suficiente para v1
- Ver nome de outros clientes no slot — privacidade; não necessário
- Suporte offline completo — conflita com booking transactions; deferido

## Context

- **Stack:** Flutter Web, Firebase Auth (Google + email/password), Cloud Firestore, Firebase Hosting, flutter_bloc, go_router
- **Modelo de dados:** `/users`, `/slots`, `/bookings`, `/blockedDates`, `/config/booking` — serialização Firestore + Equatable
- **Slots recorrentes** (ex: toda segunda às 08h); bookings são instâncias para uma data específica
- **BookingModel.generateId(slotId, date)** → ID determinístico `{slotId}_{date}` — anti-double-booking via Transaction
- **Perfis:** `client` (reserva) e `admin` (gerencia) — `role: String` no Firestore; go_router guard + Firestore rules
- **Estrutura de pastas:** `lib/features/{auth,schedule,booking,admin}/ui/` + `lib/core/{models,theme,router,pwa}`
- **Codebase:** ~3,831 linhas de Dart (v1.0)

**Current state:** v1.0 complete — app live em `vida-ativa-94ba0.web.app`. Todas as 21 requirements v1 entregues. Próximo passo: v2.0 com notificações push, phone auth, e domínio customizado.

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
*Last updated: 2026-03-23 after v1.0 milestone complete*
