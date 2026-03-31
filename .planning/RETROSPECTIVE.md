# Retrospective: Vida Ativa

---

## Milestone: v1.0 — MVP

**Shipped:** 2026-03-23
**Phases:** 6 | **Plans:** 13

### What Was Built

1. Data models + Firebase wiring + PWA manifest + Firestore bootstrap rules
2. Google + email/password auth with BLoC, persistent sessions, role-based routing
3. Read-only weekly schedule with real-time Firestore streams (available/booked/blocked/price)
4. Booking flow with atomic Firestore transaction preventing double-booking; MyBookings + cancel
5. Admin panel — slot CRUD, blocked dates, booking confirm/reject, automatic/manual mode toggle
6. Production deployment with restrictive Firestore rules (`isAdmin()` via `role`), iOS SnackBar, live URL

### What Worked

- **Phase-by-phase dependency chain** — each phase built cleanly on the previous; no rework across phase boundaries
- **Research-before-planning** caught the critical `role` vs `isAdmin` field mismatch before execution (would have silently broken all admin writes in production)
- **Plan checker** caught `firebase deploy --dry-run` (invalid flag) and the CONTEXT.md/standalone check discrepancy before a subagent wasted time on wrong implementation
- **Atomic commits per task** made it easy to spot-check progress and identify exactly what changed at each step
- **YoloMode + auto_advance** eliminated confirmation bottlenecks for non-interactive steps

### What Was Inefficient

- **ROADMAP.md Phase 5 checkbox**: Phase 5 was left with `[ ]` checkbox in ROADMAP despite completing — small tracking drift that carried through to Phase 6
- **MILESTONES.md CLI extraction**: The `milestone complete` CLI returned zero accomplishments — had to manually fill them in; the one_liner field isn't populated in SUMMARY.md files by gsd-executor
- **Wave 0 Nyquist gap**: VALIDATION.md required a test stub that would have violated `feedback_no_tests.md`; the plan had to explicitly document the exclusion to prevent the executor from creating it anyway

### Patterns Established

- **Cubit-as-constructor-param** for modals/dialogs — prevents context loss when widget unmounts before modal closes (established in Phase 4, extended in Phase 5)
- **MultiBlocProvider at router level** — all admin cubits provided at `/admin` route builder so all 3 tabs share same instances (Phase 5)
- **`(data['price'] as num).toDouble()`** — Firestore returns int or double depending on stored value; always cast via num
- **BookingModel.generateId()** — deterministic `{slotId}_{date}` IDs for anti-double-booking; always use this, never `.add()`

### Key Lessons

- **Firestore field names ≠ Dart getter names**: `UserModel.isAdmin` is a computed getter from `role: String`; the Firestore field is `role`, not `isAdmin`. Rules checking `.data.isAdmin` would silently always return false.
- **dart:js is deprecated** — use `dart:ui_web` for platform detection; no JS interop needed when installed PWAs bypass Safari entirely
- **`firebase deploy --dry-run` does not exist** — the valid verify for a build output is `ls build/web/index.html`
- **Service worker update is free**: `firebase.json` Cache-Control: no-cache on `flutter_service_worker.js` means zero code changes needed for update strategy

### Cost Observations

- Model profile: balanced (sonnet for executor/verifier)
- Sessions: ~3 (discuss-phase, plan-phase, execute-phase + complete-milestone)
- Notable: research agent caught a silent production bug (role field mismatch) before any code was written — high ROI on the research step

---

---

## Milestone: v2.0 — Funcionalidades Sociais & Admin

**Shipped:** 2026-03-31
**Phases:** 5 (7–11) | **Plans:** 10

### What Was Built

1. Agenda social: nome do reservante e campo de participantes visíveis para todos os clientes; admin vê participantes na listagem
2. Compartilhamento de reserva confirmada via WhatsApp com mensagem pré-formatada; campo de telefone no cadastro e edição de perfil
3. Admin pode alternar entre visão admin e visão cliente sem logout; promoção de usuários a admin via painel com busca
4. Monitoramento de erros em produção via Sentry — todos os cubits instrumentados (AuthCubit + 5 outros)
5. Agenda estilo Google Calendar com DayView e colunas horárias; tokens AppSpacing aplicados em todas as telas
6. Polish visual: paleta arena (verde profundo), fonte Nunito, botão Google polido, snackbars, chips e ícones PWA

### What Worked

- **Sentry MCP integration** — `.mcp.json` com Sentry MCP Server permitiu consultar issues diretamente no Claude Code; verificação de erros sem sair do editor
- **Padrão FieldValue.delete()** estabelecido na Phase 07 reutilizado diretamente na Phase 08 para phone — zero decisão nova, zero risco
- **BookingCubit captured before showModalBottomSheet** — padrão estabelecido na Phase 04 reaplicado consistentemente em Phases 07, 08, 11 sem regressão
- **calendar_view DayView** integrou limpo com slots do Firestore via SlotEventTile; nenhum workaround necessário
- **Sentry kReleaseMode guard** — DSN nunca vai para o source; --dart-define pattern funcionou sem ajustes

### What Was Inefficient

- **MILESTONES.md accomplishments**: gsd-tools `milestone complete` retornou `"accomplishments": []` pela segunda vez (v1.0 teve o mesmo problema) — one_liner não é extraído dos SUMMARY.md; requer preenchimento manual
- **SOCIAL-03 checkbox não atualizado**: REQUIREMENTS.md deixou SOCIAL-03 como `[ ]` mesmo depois de implementado na Phase 08; inconsistência carregou para o milestone completion
- **Phase 07 SUMMARY.md formato inconsistente**: Phases 07 e 09 têm SUMMARY.md no formato de "dependency graph" (frontmatter YAML), não no formato legível com `## Accomplishments`; CLI não consegue extrair one_liner

### Patterns Established

- **Nullable Firestore fields via FieldValue.delete()** — padrão canônico para todos os campos opcionais; evita strings vazias no banco
- **Context capture before modal** — `context.read<XCubit>()` capturado antes de `showModalBottomSheet`; reaplicado em toda feature com modal/sheet
- **Sentry instrumentation pattern** — `onError` lambda síncrono com `captureException` (sem await) em stream listeners; SentryUser com uid somente

### Key Lessons

- **calendar_view 2.x: pin versão exata** — pub.dev avisa que minor versions podem quebrar; sempre `calendar_view: 2.0.0` não `^2.0.0`
- **AppSpacing file paths no PLAN.md estavam errados**: plano apontava para arquivos que não existiam; executor precisou adaptar para os arquivos reais — planos devem verificar paths antes de listar
- **gsd-tools accomplishments extraction é broken**: two milestones consecutivos com `"accomplishments": []`; workaround atual é preencher manualmente após o CLI

### Cost Observations

- Model profile: balanced (sonnet para executor)
- Sessions: ~6 (uma por fase + complete-milestone)
- Notable: Sentry MCP no `.mcp.json` foi adicionado durante Phase 10 — integração ativa que gerou valor real na verificação pós-deploy

---

## Cross-Milestone Trends

| Metric | v1.0 | v2.0 |
|--------|------|------|
| Phases | 6 | 5 |
| Plans | 13 | 10 |
| Timeline | 5 days | 8 days |
| Lines of Dart | ~3,831 | ~6,236 |
| Silent bugs caught by research | 1 (role field) | 0 |
| Plan checker blockers fixed | 2 | 0 |
| gsd-tools accomplishments extracted | 0 | 0 |
