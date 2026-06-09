# Requirements: Vida Ativa v7.0 — Spike Supabase Multi-tenant

**Defined:** 2026-06-09
**Core Value:** Validar por evidência se migrar para Supabase (Postgres + RLS) é viável para SaaS multi-tenant — produzindo decisão go/no-go antes de qualquer toque em produção.

## v7.0 Requirements

### SCHEMA — Estrutura do banco

- [ ] **SPIKE-01**: Projeto Supabase de **staging** dedicado ao spike criado com tabelas `tenants`, `memberships`, `slots`, `bookings` — `tenant_id` FK em todas as tabelas dependentes, `UNIQUE(tenant_id, slot_id, date)` em `bookings`
- [ ] **SPIKE-02**: Função `book_slot()` em PL/pgSQL com `SELECT FOR UPDATE NOWAIT` + captura de `unique_violation` retornando código estruturado `SLOT_ALREADY_BOOKED`

### RLS — Row Level Security

- [ ] **SPIKE-03**: RLS habilitado nas 4 tabelas com políticas `USING` + `WITH CHECK` usando `auth.jwt() -> 'app_metadata' -> 'tenant_id'`
- [ ] **SPIKE-04**: Política diferenciada: cliente vê apenas próprias reservas; admin do tenant vê todas as reservas do tenant
- [ ] **SPIKE-05**: Auth Hook (Supabase Edge Function) injeta `tenant_id` em `app_metadata` do JWT no login — validado por decode manual do token

### PROOF — Provas documentadas

- [ ] **SPIKE-06**: Prova de isolamento escrita: 3 ataques cross-tenant (SELECT / INSERT / UPDATE em dados de outro tenant) FALHAM via cliente com anon key — resultado registrado em `/spike-supabase/docs/isolation-proof.md`
- [ ] **SPIKE-07**: Prova de anti-double-booking escrita: 50+ requests HTTP simultâneos no mesmo slot resultam em exatamente 1 confirmada — resultado registrado em `/spike-supabase/docs/concurrency-proof.md`

### FLUTTER — Integração mínima

- [ ] **SPIKE-08**: App Flutter mínimo isolado em `/spike-supabase/flutter_app/` que autentica via Supabase Auth e lê slots — RLS filtra por tenant sem `.eq('tenant_id', ...)` explícito no cliente
- [ ] **SPIKE-09**: Avaliação do Supabase Realtime documentada: confirma se RLS filtra eventos por tenant, mede latência baseline, registra limites do free tier (200 conexões)

### RISK — Avaliações de risco

- [ ] **SPIKE-10**: Risco de migração de senhas avaliado por escrito: Firebase SCRYPT vs Supabase bcrypt, estratégia concreta para ~200 usuários email/password + ~30 Google OAuth (re-link)
- [ ] **SPIKE-11**: Risco de Realtime sob carga avaliado por escrito: limites do free tier, comportamento com múltiplos tenants simultaneamente, recomendação de tier para produção

### DOC — Documento de decisão

- [ ] **SPIKE-12**: Documento de decisão final responde: o spike justifica migrar para Supabase? Sim/não com evidência de SPIKE-01..11 e riscos remanescentes listados explicitamente

### SECURITY — Integridade do spike

- [ ] **SPIKE-13**: Service role key Supabase nunca presente em código Flutter nem em commits git — validado por grep antes de cada commit

## Out of Scope

| Feature | Reason |
|---------|--------|
| Toque em `lib/`, `functions/`, `firestore.rules` | Spike é descartável — produção intocada |
| Firebase projeto de produção (`vida-ativa-94ba0`) | Qualquer referência Firebase usa `vida-ativa-staging` |
| Migração real de usuários ou dados | Spike usa contas de teste novas |
| Sentry | Agnóstico de backend, não entra no spike |
| Site de marketing | Milestone futura separada |
| Multi-quadra / múltiplos espaços | Fora do escopo do spike |
| Integração Mercado Pago / Pix | Spike valida apenas Auth + RLS + booking |
| App nativo iOS/Android | PWA mantida como estratégia |

## Constraints

- **Firebase:** qualquer referência Firebase usa `vida-ativa-staging` exclusivamente, nunca `vida-ativa-94ba0`
- **Credenciais:** service role key Supabase fora do cliente e fora do git em todo momento
- **Isolamento:** spike vive inteiramente em `/spike-supabase/` — nenhum import ou dependência do app Vida Ativa

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SPIKE-01 | Phase 31 | Pending |
| SPIKE-03 | Phase 31 | Pending |
| SPIKE-04 | Phase 31 | Pending |
| SPIKE-13 | Phase 31 | Pending |
| SPIKE-02 | Phase 32 | Pending |
| SPIKE-05 | Phase 32 | Pending |
| SPIKE-06 | Phase 33 | Pending |
| SPIKE-07 | Phase 33 | Pending |
| SPIKE-08 | Phase 34 | Pending |
| SPIKE-09 | Phase 34 | Pending |
| SPIKE-10 | Phase 35 | Pending |
| SPIKE-11 | Phase 35 | Pending |
| SPIKE-12 | Phase 35 | Pending |

**Coverage:**
- v7.0 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-09*
*Last updated: 2026-06-09 after initial definition*
