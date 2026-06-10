# Phase 33: Provas de Isolamento + Concorrência - Context

**Gathered:** 2026-06-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Executar e documentar provas de que o sistema Supabase multi-tenant está correto em dois eixos:
1. **SPIKE-06** — Isolamento cross-tenant: 3 ataques bloqueados por RLS, registrados em `isolation-proof.md`
2. **SPIKE-07** — Anti-double-booking sob concorrência: 50+ requests simultâneos → exatamente 1 booking confirmado, registrado em `concurrency-proof.md`

Deliverables:
- `spike-supabase/docs/isolation-proof.md` — prova de isolamento (dupla: SQL + HTTP)
- `spike-supabase/docs/concurrency-proof.md` — prova de concorrência
- Scripts de execução em `spike-supabase/tests/` (reutilizáveis)

Zero toque em `lib/`, `functions/`, Firebase prod.

</domain>

<decisions>
## Implementation Decisions

### Método dos Ataques de Isolamento (SPIKE-06)
- **D-01:** Dupla abordagem de prova:
  - **Interna (SQL):** Reusar `tests/rls_isolation_test.sql` + `tests/rls_insert_isolation_test.sql` via psql — documenta isolamento a nível de RLS interno (SET LOCAL jwt.claims)
  - **Externa (HTTP):** Novo script Node.js usando `@supabase/supabase-js` com anon key — faz SELECT/INSERT/UPDATE cruzados como usuário autenticado de outro tenant via HTTP real
- **D-02:** Script anon key cria 2 usuários de teste via `signUp`, insere nas `memberships` via service role key (para Auth Hook injetar tenant_id correto no JWT), executa os 3 ataques, e faz cleanup completo ao final (deleta usuários + memberships criados).

### Tool para Concorrência (SPIKE-07)
- **D-03:** Node.js + `Promise.allSettled()` — 50 chamadas simultâneas de `book_slot()` via HTTP para o mesmo slot. Mesmo usuário autenticado para todos os 50 requests. Resultado esperado: exatamente 1 `CONFIRMED`, 49 `SLOT_ALREADY_BOOKED`.

### Formato das Provas
- **D-04:** Cada arquivo de prova contém:
  1. Tabela markdown estruturada com resultado por ataque/cenário (PASS/FAIL com explicação)
  2. Output raw do terminal/script colado literalmente
  Formato auditável: fase 35 (DECISION.md) pode citar os arquivos diretamente.

### Reset de Estado antes da Concorrência
- **D-05:** Script de concorrência cria slot de teste dedicado via service role key antes do teste, usa esse slot exclusivamente, e deleta slot + booking ao final. Idempotente — não depende do estado atual do staging.

### Claude's Discretion
- Nome exato dos scripts (ex: `isolation-proof.js`, `concurrency-test.js`)
- Estrutura interna dos scripts Node.js (setup/teardown como funções separadas)
- Número exato de requests no teste (mínimo 50, pode usar 60-100 se melhorar legibilidade)
- Formato do output raw (JSON stringify ou console.table)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Spike Requirements
- `.planning/REQUIREMENTS.md` — SPIKE-06 (isolation-proof.md), SPIKE-07 (concurrency-proof.md)

### Fases Anteriores
- `.planning/phases/31-schema-sql-rls/31-CONTEXT.md` — Decisões D-06/D-07: RLS policies usando app_metadata, política cliente/admin, seed data com 2+ tenants
- `.planning/phases/32-book-slot-auth-hook/32-RESEARCH.md` — Detalhes de book_slot() PL/pgSQL, Auth Hook Edge Function, erro codes (SLOT_ALREADY_BOOKED)

### Testes existentes (reusar como base)
- `spike-supabase/tests/rls_isolation_test.sql` — 3 ataques SQL: SELECT, UPDATE cross-tenant + admin cross-tenant
- `spike-supabase/tests/rls_insert_isolation_test.sql` — Ataque INSERT WITH CHECK
- `spike-supabase/tests/book_slot_test.sql` — Testes da função book_slot()

### Schema do projeto
- `spike-supabase/schema/01_schema.sql` — Estrutura das tabelas (tenants, memberships, slots, bookings)
- `spike-supabase/schema/02_rls.sql` — Políticas RLS implementadas
- `spike-supabase/schema/03_seed.sql` — Seed data (UUIDs dos tenants de referência)
- `spike-supabase/schema/04_book_slot.sql` — Função book_slot() implementada

### Pesquisa de Spike
- `.planning/research/PITFALLS.md` — Pitfall 1 (app_metadata), Pitfall 3 (service role key)

### Projeto Context
- `.planning/PROJECT.md` §Constraints — hard constraints (staging fasirsbiadcchfgvktzt, credenciais fora do git)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `spike-supabase/tests/rls_isolation_test.sql` — Já cobre 3 ataques via psql; reusar output como prova SQL interna
- `spike-supabase/tests/rls_insert_isolation_test.sql` — 4º ataque (WITH CHECK INSERT); incluir na prova SQL
- `spike-supabase/.env.example` — Template de variáveis (SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY)

### Established Patterns
- Auth Hook injeta `tenant_id` + `role` em `app_metadata` no login — script de isolamento deve usar `signIn` real (não SET LOCAL) para obter JWT com claims corretos
- `book_slot()` retorna código estruturado (`SLOT_ALREADY_BOOKED`) — script de concorrência deve contar por código de retorno, não por HTTP status

### Integration Points
- Script anon key usa `supabase-js` com `SUPABASE_ANON_KEY` (público, ok para scripts de teste)
- Operações de setup/cleanup usam `SUPABASE_SERVICE_ROLE_KEY` (secreto, nunca no código Flutter, lido de `.env`)
- Docs de prova ficam em `spike-supabase/docs/` (criar diretório na fase)

</code_context>

<specifics>
## Specific Ideas

- Arquivos de script em `spike-supabase/tests/`: `isolation-proof.js` e `concurrency-test.js`
- Arquivos de prova em `spike-supabase/docs/`: `isolation-proof.md` e `concurrency-proof.md`
- Os docs de prova são gerados manualmente (copiar output dos scripts) — não auto-gerados
- Seed UUIDs dos tenants (de 03_seed.sql) são hardcoded nos scripts de teste

</specifics>

<deferred>
## Deferred Ideas

- Avaliação do Supabase Realtime → Phase 34 (SPIKE-09)
- Avaliação de risco de migração de senhas → Phase 35 (SPIKE-10)
- Documento de decisão go/no-go → Phase 35 (SPIKE-12)

None — discussão ficou dentro do escopo da fase.

</deferred>

---

*Phase: 33-provas-isolamento-concorrencia*
*Context gathered: 2026-06-10*
