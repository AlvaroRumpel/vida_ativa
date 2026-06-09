# Phase 31: Schema SQL + RLS - Context

**Gathered:** 2026-06-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Criar o schema PostgreSQL multi-tenant no Supabase cloud staging, habilitar RLS com políticas de isolamento, e incluir seed data para verificação manual — tudo dentro de `/spike-supabase/`. Zero toque em `lib/`, `functions/`, Firebase prod.

Deliverables:
- Projeto Supabase cloud staging configurado
- 4 tabelas com tenant_id FK e UNIQUE constraints
- RLS habilitado com políticas USING + WITH CHECK em todas as tabelas
- Seed data: 2-3 tenants, 4-6 users, slots e bookings de teste
- `.env.example` com template de credenciais

</domain>

<decisions>
## Implementation Decisions

### Ambiente Supabase
- **D-01:** Usar projeto Supabase **cloud** (staging real em supabase.com) — não local CLI. Espelha exatamente o que iria para produção; Auth real; dashboard ativo para inspeção.

### Organização dos SQL files
- **D-02:** Múltiplos arquivos separados por concern: `01_schema.sql`, `02_rls.sql`, `03_seed.sql` — cada arquivo reaplicável individualmente, histórico de git limpo por concern.

### Seed data
- **D-03:** Incluir seed data nessa fase (`03_seed.sql`): 2-3 tenants, 4-6 users (mix de admin/client em tenants diferentes), alguns slots e bookings de teste. Necessário para verificação manual de RLS antes das provas formais na fase 33.

### bookings.status — enum
- **D-04:** Status **Firebase completo** — todos os 7 valores: `pending`, `confirmed`, `cancelled`, `rejected`, `pending_payment`, `expired`, `refunded`. Avalia se schema Supabase suporta o modelo completo sem retrabalho futuro.

### Segurança (SPIKE-13 — já fixo)
- **D-05:** Service role key (`sb_secret_xxx`) nunca entra em código Flutter nem em commits git. Fica apenas em `.env` local (gitignored). `.env.example` no repo com placeholders.

### RLS — padrão fixo da pesquisa
- **D-06:** RLS policies usam SOMENTE `auth.jwt() -> 'app_metadata' -> 'tenant_id'` — nunca `user_metadata()` (modificável pelo usuário, CVE-2025-48757). Toda política de INSERT/UPDATE inclui cláusula WITH CHECK.
- **D-07:** Política diferenciada por role: cliente (`role = 'client'`) vê apenas próprias reservas em `bookings`; admin (`role = 'admin'`) vê todas as reservas do seu tenant.

### Claude's Discretion
- Naming exato das colunas (snake_case seguindo convenção Postgres)
- Tipos de coluna (UUID vs BIGSERIAL para IDs)
- Ordem dos campos dentro de cada tabela
- Índices auxiliares além do UNIQUE constraint
- Formato do enum Postgres para `status` vs CHECK constraint

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Spike Requirements
- `.planning/REQUIREMENTS.md` — SPIKE-01 (schema 4 tabelas), SPIKE-03 (RLS policies), SPIKE-04 (política cliente/admin), SPIKE-13 (credenciais)

### Spike Research
- `.planning/research/ARCHITECTURE.md` — Directory structure completo do spike, schema de tabelas, integração entre layers
- `.planning/research/PITFALLS.md` — Pitfall 1 (app_metadata vs user_metadata), Pitfall 2 (WITH CHECK obrigatório), Pitfall 3 (service role key)
- `.planning/research/STACK.md` — Stack decisions, por que Supabase vs Firebase, migration path

### Project Context
- `.planning/PROJECT.md` §Constraints — hard constraints do spike (zero toque em produção, spike em /spike-supabase/)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Nenhum: `/spike-supabase/` ainda não existe — tudo será criado do zero nessa fase.

### Established Patterns
- `BookingModel.status` no Flutter usa strings: `pending | confirmed | cancelled | rejected | pending_payment | expired | refunded` — o enum SQL deve espelhar esses valores exatos para facilitar migração futura.

### Integration Points
- Schema criado aqui é base para Phase 32 (book_slot PL/pgSQL) e Phase 34 (Flutter mini-app)
- `.env.example` definido aqui orienta Phase 32 e Phase 34 sobre quais env vars existem

</code_context>

<specifics>
## Specific Ideas

- Arquivos SQL em `spike-supabase/schema/`: `01_schema.sql`, `02_rls.sql`, `03_seed.sql`
- Seed deve criar pelo menos 2 tenants distintos para viabilizar provas cross-tenant na fase 33
- `bookings.id` pode usar `gen_random_uuid()` como default (sem ID determinístico — diferente do Firebase; o UNIQUE constraint é o anti-double-booking aqui)

</specifics>

<deferred>
## Deferred Ideas

- `book_slot()` PL/pgSQL com SELECT FOR UPDATE NOWAIT → Phase 32
- Auth Hook (Edge Function para injetar tenant_id no JWT) → Phase 32
- Provas formais de isolamento e concorrência → Phase 33
- App Flutter mini-app → Phase 34

None — discussão ficou dentro do escopo da fase.

</deferred>

---

*Phase: 31-schema-sql-rls*
*Context gathered: 2026-06-09*
