# Milestones

## v2.0 Funcionalidades Sociais & Admin (Shipped: 2026-03-31)

**Phases completed:** 5 phases (7–11), 10 plans
**Timeline:** 2026-03-23 → 2026-03-31 (8 days)
**Codebase:** ~6,236 lines of Dart (+2,405 from v1.0)

**Key accomplishments:**

1. Agenda social: nome do reservante visível em cada slot ocupado; campo de participantes adicionado à reserva e exibido no painel admin
2. Compartilhamento de reserva confirmada via WhatsApp com mensagem pré-formatada; campo de telefone no cadastro e edição de perfil
3. Admin pode alternar entre visão admin e visão cliente sem logout; promoção de usuários a admin via painel com busca por nome/email
4. Monitoramento de erros em produção via Sentry — todos os cubits instrumentados com captureException e escopo de usuário
5. Agenda estilo Google Calendar (DayView com colunas horárias por dia); tokens AppSpacing aplicados em todas as telas
6. Polish visual: paleta arena (verde profundo), fonte Nunito, botão Google polido, snackbars, chips e ícones PWA atualizados

**Known gaps:** UI-01 (rebrand visual) deferred to v3 — aguardando assets do cliente (logo + paleta oficial)

**Archive:** `.planning/milestones/v2.0-ROADMAP.md`

---

## v1.0 MVP (Shipped: 2026-03-23)

**Phases completed:** 6 phases, 13 plans
**Timeline:** 2026-03-19 → 2026-03-23 (5 days)
**Codebase:** ~3,831 lines of Dart

**Key accomplishments:**

1. Four Firestore data models (UserModel, SlotModel, BookingModel, BlockedDateModel) with bidirectional serialization, Equatable, and deterministic booking ID generation for anti-double-booking
2. Google Sign-In + email/password auth with BLoC, persistent sessions, and role-based route guards (client vs admin)
3. Read-only weekly schedule with real-time Firestore streams — available/booked/blocked/price display per slot
4. Booking flow with atomic Firestore transactions preventing double-booking; MyBookings list with cancel flow
5. Admin panel — slot CRUD + active toggle, blocked date management, booking list with confirm/reject per date, configurable automatic/manual approval mode
6. Production deployment to `vida-ativa-94ba0.web.app` — restrictive Firestore rules with `isAdmin()` role-based access, iOS install SnackBar, PWA title "Vida Ativa"

**Archive:** `.planning/milestones/v1.0-ROADMAP.md`

---
