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

### 📋 v3.0 (Planned)

- [ ] **Phase 12: Rebrand Visual** - Logo e paleta de cores do cliente aplicados em todas as telas *(BLOQUEADO — aguardando assets do cliente)*

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
| 12. Rebrand Visual | v3.0 | 0/? | BLOCKED | - |
