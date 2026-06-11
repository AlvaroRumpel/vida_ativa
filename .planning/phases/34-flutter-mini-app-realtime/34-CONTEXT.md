# Phase 34: Flutter Mini-App + Realtime - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Construir um mini-app Flutter isolado em `/spike-supabase/flutter_app/` que autentica via Supabase Auth, lê slots com RLS filtrando por tenant sem `.eq()` explícito no cliente, e chama `book_slot()` via RPC. Separadamente, criar script Node.js `tests/realtime-test.js` que avalia isolamento cross-tenant de eventos Realtime + latência.

Deliverables:
- `/spike-supabase/flutter_app/` — projeto Flutter standalone (flutter create)
- Prova SPIKE-08: login + leitura comparativa (2 tenants) + book_slot() RPC
- `/spike-supabase/tests/realtime-test.js` — avaliação SPIKE-09
- Output dos testes documentado (log console + markdown)

Zero toque em `lib/`, `functions/`, Firebase prod.

</domain>

<decisions>
## Implementation Decisions

### Setup do Mini-App

- **D-01:** Projeto Flutter **standalone** via `flutter create spike_flutter` em `/spike-supabase/flutter_app/`. Roda no browser via `flutter run -d chrome`. Usa `supabase_flutter ^2.14.1` — mesma integração que produção usaria.
- **D-02:** Autenticação com **email/password hardcoded** das contas de teste do seed data (`testclient@spike.local`, `testadmin@spike.local`). Sem UI de login — foco em provar comportamento do SDK. Credentials ficam apenas em `.env` local (gitignored), lidas via `String.fromEnvironment` ou hardcoded apenas no mini-app isolado.

### Escopo Funcional (SPIKE-08)

- **D-03:** Mini-app Flutter prova **três coisas**: (1) autenticar via Supabase Auth, (2) ler slots — RLS filtra por tenant sem `.eq()`, (3) chamar `book_slot()` via RPC. Prova E2E completa: o SDK Flutter consegue invocar a função PL/pgSQL validada nas fases 32–33.

### Prova RLS no Cliente

- **D-04:** Prova comparativa com **dois usuários de tenants diferentes**. Mesmo query sem `.eq('tenant_id', ...)`: login como `client_tenant_1` → recebe N slots; login como `client_tenant_2` → recebe M slots diferentes. Delta prova que RLS filtra automaticamente. Output: log console + tabela markdown no doc de prova.

### Avaliação Realtime (SPIKE-09)

- **D-05:** Realtime avaliado em **script Node.js separado** (`tests/realtime-test.js`) usando `@supabase/supabase-js`. Mais fácil orquestrar 2 clientes simultâneos (tenant_1 assina canal, admin_tenant_2 insere dado).
- **D-06:** Avaliação cobre **três pontos**: (1) isolamento cross-tenant — confirmar que tenant_1 NÃO recebe evento de inserção do tenant_2 via canal Realtime; (2) latência baseline — medir tempo event → handler; (3) limites free tier — documentar limite de 200 conexões simultâneas.
- **D-07:** Se RLS não filtra eventos Realtime, documentar como **bloqueante** para multi-tenant no arquivo de avaliação. Essa é a questão mais crítica para o DECISION.md (fase 35).

### Claude's Discretion

- Estrutura interna do flutter_app (pubspec.yaml, main.dart, screen layout)
- Nome do arquivo de avaliação Realtime em docs/ (ex: `realtime-evaluation.md`)
- Formato do output de prova (console.log JSON vs tabela formatada)
- Se usar `StatefulWidget` ou `StreamBuilder` para mostrar resultado no Flutter
- Número exato de inserts no teste de Realtime (mínimo 3 eventos)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Spike Requirements
- `.planning/REQUIREMENTS.md` — SPIKE-08 (Flutter mini-app), SPIKE-09 (Realtime evaluation), SPIKE-13 (service role key never in Flutter)

### Fases Anteriores
- `.planning/phases/31-schema-sql-rls/31-CONTEXT.md` — D-05: service role key nunca no código Flutter; D-06/D-07: RLS policies + seed data (testclient/testadmin accounts)
- `.planning/phases/32-book-slot-auth-hook/32-01-PLAN.md` — `book_slot()` signature, parâmetros da RPC, códigos de retorno (`CONFIRMED`, `SLOT_ALREADY_BOOKED`)

### Spike Docs (Provas Anteriores)
- `spike-supabase/docs/isolation-proof.md` — SPIKE-06 resultado (referência para DECISION.md)
- `spike-supabase/docs/concurrency-proof.md` — SPIKE-07 resultado (referência para DECISION.md)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `spike-supabase/package.json` — `@supabase/supabase-js` já instalado; `realtime-test.js` pode importar diretamente
- `spike-supabase/tests/concurrency-test.js` — padrão de autenticação via `supabase.auth.signInWithPassword()` + cleanup ao final; reusar estrutura para `realtime-test.js`
- `spike-supabase/tests/isolation-proof.js` — padrão de teste com 2 usuários de tenants distintos; reusar para prova RLS no Flutter (mesmas contas de teste)
- `spike-supabase/schema/` — SQL files com tabela `slots` e `bookings`; entender estrutura para query Flutter

### Established Patterns
- Scripts Node.js no spike usam `Promise.allSettled()` para testes paralelos (ver `concurrency-test.js`)
- Contas de teste: `testclient@spike.local` / `testadmin@spike.local` com dados em staging `fasirsbiadcchfgvktzt`
- `.env` local com `SUPABASE_URL` e `SUPABASE_ANON_KEY` — mini-app Flutter usa as mesmas variáveis

### Integration Points
- Flutter app autentica com `SUPABASE_URL` + `SUPABASE_ANON_KEY` do staging (não service role)
- `book_slot()` chamado via `supabase.rpc('book_slot', {...})` — mesma API do Node.js
- Realtime channel: `supabase.channel('bookings').on(PostgresChangeEvent.insert, ...)` no supabase_flutter

</code_context>

<specifics>
## Specific Ideas

- **Prova mais convincente para DECISION.md:** logar explicitamente "query sem .eq() → X rows" para tenant_1 e "mesma query → Y rows diferentes" para tenant_2 — side-by-side no doc.
- **SPIKE-09 é a questão crítica:** se Realtime não isola por tenant, é um bloqueante real. O script Node.js precisa ser conclusivo — não apenas "não recebeu evento" mas confirmar via timeout que o evento realmente não chegou.

</specifics>

<deferred>
## Deferred Ideas

- Teste Realtime com carga real (múltiplos tenants simultâneos) — isso é SPIKE-11, pertence à fase 35
- UI de login real com TextField/buttons — não agrega valor ao spike

</deferred>

---

*Phase: 34-flutter-mini-app-realtime*
*Context gathered: 2026-06-11*
