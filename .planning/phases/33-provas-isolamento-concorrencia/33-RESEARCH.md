# Phase 33: Provas de Isolamento + Concorrência - Research

**Researched:** 2026-06-10
**Domain:** Supabase multi-tenant proof scripts — RLS isolation (SQL + HTTP) + concurrency anti-double-booking
**Confidence:** HIGH

## Summary

Phase 33 produces two auditable proof documents that validate the Supabase multi-tenant spike:

1. **SPIKE-06 (isolation-proof.md):** Three cross-tenant attacks executed via two methods — SQL internal (existing `rls_isolation_test.sql` + `rls_insert_isolation_test.sql` via psql) and HTTP external (new Node.js `isolation-proof.js` using supabase-js with real authenticated users and anon key). Both must return PASS for every attack.

2. **SPIKE-07 (concurrency-proof.md):** 50–100 simultaneous HTTP calls to `book_slot()` via `Promise.allSettled()` — exactly 1 `success=true`, rest `SLOT_ALREADY_BOOKED`. Tested against a dedicated slot created and cleaned up by the script (idempotent, no dependency on staging state).

The core technical work is writing two Node.js scripts. The SQL tests already exist. The planner's job is to structure the wave order so the SQL proof runs first (validates internal RLS), then the Node.js isolation script (validates real HTTP path), then the concurrency script, then both docs are filled in with terminal output.

**Primary recommendation:** Write `isolation-proof.js` and `concurrency-test.js` in `spike-supabase/tests/`. Use `@supabase/supabase-js@2.x` with `createClient()` for user-scoped calls and a separate `createClient()` with service role key for setup/teardown. Load credentials from `.env` via `dotenv`. Run SQL tests via psql (SUPABASE_DB_URL). Capture all output and paste raw into the `.md` proof files.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Dupla abordagem de prova para SPIKE-06:
  - **Interna (SQL):** Reusar `tests/rls_isolation_test.sql` + `tests/rls_insert_isolation_test.sql` via psql
  - **Externa (HTTP):** Novo script Node.js usando `@supabase/supabase-js` com anon key — faz SELECT/INSERT/UPDATE cruzados como usuário autenticado de outro tenant via HTTP real
- **D-02:** Script anon key cria 2 usuários de teste via `signUp`, insere nas `memberships` via service role key, executa os 3 ataques, e faz cleanup completo ao final (deleta usuários + memberships).
- **D-03:** Node.js + `Promise.allSettled()` — 50 chamadas simultâneas de `book_slot()` via HTTP para o mesmo slot. Mesmo usuário autenticado para todos os 50 requests. Resultado esperado: exatamente 1 `CONFIRMED`, 49 `SLOT_ALREADY_BOOKED`.
- **D-04:** Cada arquivo de prova contém: (1) tabela markdown estruturada PASS/FAIL, (2) output raw do terminal literalmente colado.
- **D-05:** Script de concorrência cria slot de teste dedicado via service role key, usa exclusivamente, deleta slot + booking ao final. Idempotente.

### Claude's Discretion

- Nome exato dos scripts (ex: `isolation-proof.js`, `concurrency-test.js`)
- Estrutura interna dos scripts Node.js (setup/teardown como funções separadas)
- Número exato de requests no teste de concorrência (mínimo 50, pode usar 60–100)
- Formato do output raw (JSON stringify ou console.table)

### Deferred Ideas (OUT OF SCOPE)

- Avaliação do Supabase Realtime → Phase 34 (SPIKE-09)
- Avaliação de risco de migração de senhas → Phase 35 (SPIKE-10)
- Documento de decisão go/no-go → Phase 35 (SPIKE-12)
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SPIKE-06 | Prova de isolamento: 3 ataques cross-tenant (SELECT/INSERT/UPDATE) FALHAM via cliente com anon key — resultado em `isolation-proof.md` | SQL tests já existem; Node.js script usa signUp + real JWT → RLS bloqueia cross-tenant |
| SPIKE-07 | Prova de anti-double-booking: 50+ requests HTTP simultâneos no mesmo slot → exatamente 1 confirmada — resultado em `concurrency-proof.md` | `Promise.allSettled()` com 50–100 calls; book_slot() retorna SLOT_ALREADY_BOOKED para duplicatas; contagem por error_code |
</phase_requirements>

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| @supabase/supabase-js | 2.108.1 | Cliente HTTP para chamadas autenticadas (anon key + service role) | Biblioteca oficial Supabase; signUp, signInWithPassword, rpc() todos disponíveis |
| dotenv | 17.4.2 | Carregar SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY de `.env` | Padrão Node.js; evita hardcode de credenciais |
| Node.js built-ins | v24 (disponível) | Promise.allSettled() para concorrência; process.env para env vars | Sem dependência extra para concorrência |

**Version verification:**
```
npm view @supabase/supabase-js version → 2.108.1  [VERIFIED: npm registry]
npm view dotenv version → 17.4.2  [VERIFIED: npm registry]
node --version → v24.14.0  [VERIFIED: local environment]
```

**Installation:**
```bash
# Em spike-supabase/tests/ (package.json local) OU spike-supabase/ (se já tiver package.json)
npm install @supabase/supabase-js dotenv
```

> Note: `spike-supabase/` não tem `package.json` ainda. O planner deve incluir `npm init -y` + install como Wave 0.

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| psql CLI | sistema (não encontrado localmente) | Executar SQL tests internos | Wave SQL — requer SUPABASE_DB_URL no .env |

> **CRITICAL: psql não está no PATH local** (verificado via `where psql` — não encontrado). O usuário precisará instalar psql ou confirmar disponibilidade antes de executar os SQL tests. Alternativa: executar os SQL tests via Supabase MCP (`execute_sql`) ou via Supabase Dashboard SQL Editor como fallback.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| psql para SQL tests | Supabase MCP `execute_sql` | MCP não mostra output raw terminal (formato diferente para o doc de prova) |
| Promise.allSettled() | k6 / artillery | k6 mais robusto mas requer instalação extra; Promise.allSettled() com Node.js puro é suficiente para 50–100 requests de prova |
| signUp para criar usuários de teste | Supabase Admin API via service role | Admin API requer chamada extra; signUp é o fluxo real que valida Auth Hook |

---

## Architecture Patterns

### Recommended Project Structure

```
spike-supabase/
├── tests/
│   ├── rls_isolation_test.sql          # EXISTS: 3 ataques SQL internos
│   ├── rls_insert_isolation_test.sql   # EXISTS: ataque INSERT WITH CHECK
│   ├── book_slot_test.sql              # EXISTS: testes da função
│   ├── isolation-proof.js              # NEW: script Node.js HTTP isolation
│   └── concurrency-test.js             # NEW: script Node.js 50x concurrent
├── docs/                               # NEW: criar diretório
│   ├── isolation-proof.md              # NEW: proof document SPIKE-06
│   └── concurrency-proof.md            # NEW: proof document SPIKE-07
├── schema/                             # EXISTS: 01–04 SQL files
├── package.json                        # NEW: para supabase-js + dotenv
├── .env.example                        # EXISTS
└── .env                                # GITIGNORED: credenciais reais
```

### Pattern 1: isolation-proof.js — Setup → Attack → Assert → Cleanup

**What:** Script Node.js que cria 2 usuários de teste reais via `signUp` (Tenant A e Tenant B), insere memberships via service role, executa 3 ataques HTTP cruzados, verifica bloqueio, e deleta usuários + memberships no finally block.

**Key constraint:** Auth Hook injeta `tenant_id` em `app_metadata` no login — por isso `signUp` + `signInWithPassword` são necessários (não simulados). Após login, o JWT contém o tenant correto.

**Structure:**
```javascript
// spike-supabase/tests/isolation-proof.js
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import path from 'path';

dotenv.config({ path: path.join(path.dirname(fileURLToPath(import.meta.url)), '../.env') });

const anonClient   = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
const adminClient  = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

// Tenant UUIDs from 03_seed.sql
const TENANT_A = '10000000-0000-0000-0000-000000000001';
const TENANT_B = '20000000-0000-0000-0000-000000000001';

async function setup() {
  // signUp user A (email generated unique per run to avoid conflicts)
  // Insert into memberships via adminClient (tenant_id = TENANT_A, role = 'client')
  // signUp user B → memberships (tenant_id = TENANT_B, role = 'client')
  // signInWithPassword for both → get sessions with tenant_id in JWT
}

async function runAttacks(sessionA, sessionB) {
  // Attack 1: User A tries SELECT on Tenant B bookings → expect 0 rows
  // Attack 2: User A tries INSERT into Tenant B bookings → expect RLS error
  // Attack 3: User A tries UPDATE on Tenant B booking → expect 0 rows affected
}

async function cleanup(userA_id, userB_id) {
  // adminClient.auth.admin.deleteUser(userA_id)
  // adminClient.auth.admin.deleteUser(userB_id)
  // DELETE FROM memberships WHERE user_id IN (...)
}

async function main() {
  const { userA_id, userB_id, sessionA, sessionB } = await setup();
  try {
    await runAttacks(sessionA, sessionB);
  } finally {
    await cleanup(userA_id, userB_id);
  }
}

main();
```

**Critical detail:** `adminClient.auth.admin.deleteUser()` requer que o `adminClient` seja criado com `SERVICE_ROLE_KEY` e que o Supabase project tenha Auth management habilitado. Esta API é parte da `auth.admin` namespace em supabase-js v2. [VERIFIED: supabase-js v2 docs — `supabase.auth.admin.deleteUser(uid)` disponível com service role]

### Pattern 2: concurrency-test.js — Create Slot → 50x Parallel book_slot() → Verify → Cleanup

**What:** Script cria um slot de teste dedicado via service role, obtém session de 1 usuário, dispara 50–100 calls `rpc('book_slot', {...})` simultâneas via `Promise.allSettled()`, conta resultados por `error_code`, deleta slot + booking no finally.

**Structure:**
```javascript
// spike-supabase/tests/concurrency-test.js
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config({ path: '../.env' });

const TENANT_A = '10000000-0000-0000-0000-000000000001';
const TEST_DATE = '2099-12-31';  // far future — avoid conflicts with seed data
const CONCURRENT_REQUESTS = 50;

async function createTestSlot(adminClient) {
  // INSERT into slots via adminClient, return slot_id
}

async function bookSlot(userClient, slot_id, user_id) {
  const { data, error } = await userClient.rpc('book_slot', {
    p_slot_id: slot_id,
    p_booking_date: TEST_DATE,
    p_user_id: user_id,
    p_tenant_id: TENANT_A,
  });
  return { data, error };
}

async function main() {
  const adminClient = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

  // Create test user for concurrent calls (or use existing seed user)
  // signInWithPassword to get authenticated userClient

  const slot_id = await createTestSlot(adminClient);
  try {
    const calls = Array.from({ length: CONCURRENT_REQUESTS }, () =>
      bookSlot(userClient, slot_id, user_id)
    );
    const results = await Promise.allSettled(calls);

    const confirmed = results.filter(r => r.status === 'fulfilled' && r.value.data?.[0]?.success === true);
    const alreadyBooked = results.filter(r => r.status === 'fulfilled' && r.value.data?.[0]?.error_code === 'SLOT_ALREADY_BOOKED');

    console.log(`CONFIRMED: ${confirmed.length}  (expected: 1)`);
    console.log(`SLOT_ALREADY_BOOKED: ${alreadyBooked.length}  (expected: ${CONCURRENT_REQUESTS - 1})`);

    const pass = confirmed.length === 1 && (confirmed.length + alreadyBooked.length) === CONCURRENT_REQUESTS;
    console.log(pass ? 'RESULT: PASS' : 'RESULT: FAIL');
  } finally {
    // DELETE FROM bookings WHERE slot_id = slot_id AND booking_date = TEST_DATE
    // DELETE FROM slots WHERE id = slot_id
  }
}

main();
```

**Key detail:** `rpc('book_slot', { p_slot_id, p_booking_date, p_user_id, p_tenant_id })` — parâmetros exatamente como definidos em `04_book_slot.sql`. book_slot() é SECURITY DEFINER, então mesmo chamadas autenticadas vão funcionar.

**Important:** `book_slot()` valida `p_user_id` contra `memberships` (fix WR-02 do Phase 32). O usuário de teste DEVE existir em `memberships` para Tenant A, ou a função retorna `USER_NOT_IN_TENANT`. O planner deve garantir que o script usa um user com membership válida.

### Pattern 3: Formato do Proof Document (D-04)

Cada `.md` de prova tem:

```markdown
# Isolation Proof — SPIKE-06
**Date:** YYYY-MM-DD
**Project:** fasirsbiadcchfgvktzt (staging)

## Attack Results

| # | Attack | Method | Expected | Result |
|---|--------|--------|----------|--------|
| 1 | Cross-tenant SELECT on bookings | SQL (psql) | 0 rows | PASS |
| 2 | Cross-tenant SELECT on bookings | HTTP (Node.js anon key) | RLS blocks | PASS |
| ... | ... | ... | ... | ... |

## Raw Output — SQL Tests

```
[paste psql output here]
```

## Raw Output — HTTP Tests (Node.js)

```
[paste Node.js script output here]
```
```

### Anti-Patterns to Avoid

- **Não usar service role key para os ataques:** O objetivo é provar que o RLS bloqueia via client path (anon key). Com service role, RLS é bypassado e todos os ataques "passam" silenciosamente — prova inválida.
- **Não reusar bookings de seed para o teste de concorrência:** Seed bookings têm datas específicas (2026). Usar data futura (`2099-12-31`) + slot dedicado garante idempotência.
- **Não usar usuários placeholder do seed:** Os user_ids no seed (00000000-...) são placeholders sem auth.users correspondente. O script de isolamento deve criar usuários reais via `signUp` para que o Auth Hook injete o JWT correto.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Concurrent HTTP calls | sleep() loops sequenciais | `Promise.allSettled()` | allSettled dispara todas as promises ao mesmo tempo; loop sequencial não testa concorrência real |
| User creation + cleanup | SQL INSERT direto em auth.users | `adminClient.auth.admin.createUser()` ou `signUp` | auth.users é gerenciado pelo Supabase Auth — INSERT direto pode quebrar constraints internas |
| Verificar bloqueio de ataque | Checar HTTP status 403 | Checar `error.message` ou `data.length === 0` | RLS retorna 200 com 0 rows para SELECT, e error para INSERT/UPDATE — não é sempre 403 |
| Deletar usuários de teste | DELETE FROM auth.users | `adminClient.auth.admin.deleteUser(uid)` | auth.users tem constraints; só o Admin API limpa corretamente |

**Key insight:** RLS não lança erro HTTP 4xx para SELECTs — simplesmente retorna 0 rows. A prova de isolamento deve checar contagem de rows retornados, não status HTTP. Para INSERT/UPDATE, a checagem é `error !== null`.

---

## Common Pitfalls

### Pitfall 1: Auth Hook não injeta tenant_id — signIn retorna JWT sem app_metadata

**What goes wrong:** Script chama `signUp` e depois `signInWithPassword`. Login funciona, mas JWT não tem `app_metadata.tenant_id`. RLS nega tudo, não por isolamento cross-tenant, mas por falta de claim.

**Why it happens:** O Auth Hook (`custom-access-token`) só injeta tenant_id se o usuário tiver membership em `memberships`. Se `setup()` cria o usuário mas não insere a membership antes de `signInWithPassword`, o hook não encontra nada e retorna claims sem modificação.

**How to avoid:** Sequência obrigatória: (1) `signUp`, (2) INSERT em memberships via adminClient, (3) `signInWithPassword`. Não inverter.

**Warning signs:** `session.user.app_metadata.tenant_id` é `undefined` após login. Todas as queries retornam 0 rows (incluindo as do próprio tenant).

---

### Pitfall 2: book_slot() retorna USER_NOT_IN_TENANT — script de concorrência falha com erro inesperado

**What goes wrong:** O script de concorrência usa `p_user_id` de um usuário que não tem membership em Tenant A. Após Phase 32 fix WR-02, a função valida isso e retorna `USER_NOT_IN_TENANT` em vez de tentar o booking. Os 50 calls retornam esse código e o teste parece que falhou diferente do esperado.

**Why it happens:** WR-02 adicionou validação de membership em `04_book_slot.sql`. Usuários sem membership são bloqueados.

**How to avoid:** O script de concorrência deve usar (a) um usuário seed que já tem membership em Tenant A, ou (b) criar um usuário novo + membership via adminClient antes do teste, e deletar no cleanup.

**Warning signs:** Todos os 50 resultados têm `error_code = 'USER_NOT_IN_TENANT'`, nenhum `SLOT_ALREADY_BOOKED`.

---

### Pitfall 3: RLS bloqueia SELECT cruzado mas não registra erro — prova parece ambígua

**What goes wrong:** Script faz `SELECT * FROM bookings WHERE tenant_id = TENANT_B` como usuário de Tenant A. Supabase retorna `{ data: [], error: null }` — sem erro, 0 rows. O script precisa checar `data.length === 0` e reportar como PASS, não tratar como "query funcionou".

**How to avoid:** Definir explicitamente o critério de PASS para cada tipo de ataque:
- SELECT cross-tenant: `data.length === 0` → PASS
- INSERT cross-tenant: `error !== null && error.message.includes('row-level security')` → PASS
- UPDATE cross-tenant: `data` retorna 0 rows affected (ou error) → PASS

---

### Pitfall 4: psql não disponível localmente — SQL tests não executam

**What goes wrong:** Os SQL tests existentes (`rls_isolation_test.sql`) requerem psql com `SUPABASE_DB_URL`. psql **não está instalado** neste ambiente (verificado — `where psql` retornou vazio).

**How to avoid:** O planner deve incluir uma task de "fallback" para os SQL tests: usar Supabase MCP `execute_sql` tool para executar os SQL files, capturar output, e colar no doc de prova. Ou o usuário instala psql (PostgreSQL client tools via winget ou Chocolatey no Windows).

**Warning signs:** `psql: command not found` ao tentar executar o SQL test.

---

### Pitfall 5: Timestamp de email único — signUp falha com "User already registered"

**What goes wrong:** Script roda, cria usuários com emails fixos (ex: `test-tenant-a@spike.local`). Script falha a meio, cleanup não roda. Na próxima execução, `signUp` falha porque email já existe.

**How to avoid:** Usar emails gerados com timestamp: `test-a-${Date.now()}@spike.local`. Sempre rodar cleanup no `finally` block, não apenas no happy path.

---

### Pitfall 6: .env path resolution no Node.js

**What goes wrong:** Script usa `dotenv.config()` sem path explícito. Node.js resolve `.env` relativo ao `cwd()`, não ao arquivo. Se rodado de diretório diferente de `spike-supabase/`, `.env` não é encontrado e todas as env vars são `undefined`.

**How to avoid:** Usar path explícito baseado em `import.meta.url` (ESM) ou `__dirname` (CJS):
```javascript
// ESM (com "type": "module" no package.json):
import { fileURLToPath } from 'url';
const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '../.env') });
```

---

## Code Examples

### Supabase-js v2: signUp + signIn + rpc()

```javascript
// Source: @supabase/supabase-js v2 official API
const { data: signUpData, error: signUpError } = await anonClient.auth.signUp({
  email: `test-a-${Date.now()}@spike.local`,
  password: 'TestPassword123!'
});
const user_id = signUpData.user.id;

// Insert membership via service role (Auth Hook needs this to inject tenant_id)
const { error: membershipError } = await adminClient
  .from('memberships')
  .insert({ tenant_id: TENANT_A, user_id, role: 'client' });

// Sign in to get JWT with tenant_id in app_metadata
const { data: signInData } = await anonClient.auth.signInWithPassword({
  email: `test-a-${Date.now()}@spike.local`,
  password: 'TestPassword123!'
});
const session = signInData.session;

// Create tenant-scoped client
const clientA = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY,
  { global: { headers: { Authorization: `Bearer ${session.access_token}` } } }
);
```

### Cross-tenant SELECT Attack (Attack 1)

```javascript
// Expected: data.length === 0 (RLS blocks Tenant B rows for Tenant A user)
const { data, error } = await clientA
  .from('bookings')
  .select('*')
  .eq('tenant_id', TENANT_B);

const pass = data !== null && data.length === 0 && error === null;
console.log(`Attack 1 (SELECT cross-tenant): ${pass ? 'PASS' : 'FAIL'}`);
console.log(`  rows returned: ${data?.length}, error: ${error?.message ?? 'none'}`);
```

### Cross-tenant INSERT Attack (Attack 2)

```javascript
// Expected: error !== null (RLS WITH CHECK blocks INSERT to Tenant B)
const { data, error } = await clientA
  .from('bookings')
  .insert({
    tenant_id: TENANT_B,
    user_id: userA_id,
    slot_id: SLOT_B1,
    booking_date: '2099-06-01',
    status: 'pending'
  });

const pass = error !== null;
console.log(`Attack 2 (INSERT cross-tenant): ${pass ? 'PASS' : 'FAIL'}`);
console.log(`  error: ${error?.message ?? 'NO ERROR — FAIL'}`);
```

### book_slot() rpc call

```javascript
// Source: supabase-js rpc() + 04_book_slot.sql function signature
const { data, error } = await userClient.rpc('book_slot', {
  p_slot_id:      slotId,
  p_booking_date: TEST_DATE,
  p_user_id:      userId,
  p_tenant_id:    TENANT_A,
});
// data[0] = { success: boolean, error_code: string|null, booking_id: uuid|null }
```

### Promise.allSettled() concurrency pattern

```javascript
// 50 concurrent calls, same slot, same user
const calls = Array.from({ length: 50 }, () =>
  userClient.rpc('book_slot', {
    p_slot_id:      slotId,
    p_booking_date: TEST_DATE,
    p_user_id:      userId,
    p_tenant_id:    TENANT_A,
  })
);

const results = await Promise.allSettled(calls);

const summary = results.reduce((acc, r) => {
  if (r.status === 'rejected') { acc.errors++; return acc; }
  const row = r.value.data?.[0];
  if (!row) { acc.errors++; return acc; }
  acc[row.error_code ?? 'success'] = (acc[row.error_code ?? 'success'] ?? 0) + 1;
  return acc;
}, { success: 0, errors: 0 });

console.table(summary);
// Expected: { success: 1, SLOT_ALREADY_BOOKED: 49, errors: 0 }
```

### Cleanup de usuário de teste

```javascript
// Source: supabase-js auth.admin API (service role required)
await adminClient.auth.admin.deleteUser(userA_id);
await adminClient.auth.admin.deleteUser(userB_id);
// memberships cascade-delete via FK ON DELETE CASCADE (ver 01_schema.sql)
// Portanto: deletar auth.users via admin API é suficiente — memberships removidas automaticamente
```

---

## Runtime State Inventory

> Fase de prova — não é rename/refactor. Esta seção documenta estado de runtime existente que impacta os scripts.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Seed bookings para Tenant A em datas reais (2026-06-16 etc.) | Ignorar — scripts usam datas 2099-xx-xx |
| Stored data | Seed memberships com user_ids placeholder (00000000-...) | Não reusar para testes HTTP — criar novos usuários reais |
| Live service config | Auth Hook `custom-access-token` registrado em staging fasirsbiadcchfgvktzt | Deve estar deployado e ativo; validar antes de rodar isolation-proof.js |
| OS-registered state | None — sem Task Scheduler, pm2, ou systemd envolvidos | None |
| Secrets/env vars | `.env` não existe ainda em `spike-supabase/` (apenas `.env.example`) | Criar `.env` com credenciais reais antes de rodar qualquer script |
| Build artifacts | Nenhum package.json em spike-supabase/ | npm init + install como Wave 0 |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | isolation-proof.js, concurrency-test.js | ✓ | v24.14.0 | — |
| npm | instalar @supabase/supabase-js + dotenv | ✓ | 11.9.0 | — |
| psql CLI | rls_isolation_test.sql, rls_insert_isolation_test.sql | ✗ | — | Supabase MCP `execute_sql` ou Dashboard SQL Editor |
| Supabase staging project | todos os scripts | ✓ | fasirsbiadcchfgvktzt | — |
| .env com credenciais | todos os scripts | ✗ (não existe) | — | Criar antes da fase (Wave 0) |
| Auth Hook deployed | isolation-proof.js (signIn → JWT com tenant_id) | ✓ (Phase 32 deliverable) | — | Re-deploy se necessário |
| @supabase/supabase-js | isolation-proof.js, concurrency-test.js | ✗ (não instalado) | 2.108.1 | npm install (Wave 0) |

**Missing dependencies with no fallback:**
- `.env` com credenciais reais — deve ser criado pelo usuário antes da execução (não pode ser gerado automaticamente)

**Missing dependencies with fallback:**
- `psql` — fallback: Supabase MCP `execute_sql` para executar os SQL tests e capturar output

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Node.js scripts (self-reporting PASS/FAIL) + SQL scripts via psql/MCP |
| Config file | none — scripts são executados diretamente |
| Quick run command | `node spike-supabase/tests/isolation-proof.js` |
| Full suite command | `node spike-supabase/tests/isolation-proof.js && node spike-supabase/tests/concurrency-test.js` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SPIKE-06 | 3 ataques SQL cross-tenant bloqueados por RLS | integration SQL | `psql "$SUPABASE_DB_URL" -f tests/rls_isolation_test.sql` | ✅ (rls_isolation_test.sql) |
| SPIKE-06 | INSERT WITH CHECK bloqueia cross-tenant | integration SQL | `psql "$SUPABASE_DB_URL" -f tests/rls_insert_isolation_test.sql` | ✅ (rls_insert_isolation_test.sql) |
| SPIKE-06 | 3 ataques HTTP bloqueados (SELECT/INSERT/UPDATE) | integration HTTP | `node tests/isolation-proof.js` | ❌ Wave 0 |
| SPIKE-07 | 50 requests simultâneos → exatamente 1 CONFIRMED | integration HTTP | `node tests/concurrency-test.js` | ❌ Wave 0 |

### Wave 0 Gaps

- [ ] `spike-supabase/package.json` — `npm init -y` para habilitar `npm install`
- [ ] `npm install @supabase/supabase-js dotenv` em `spike-supabase/`
- [ ] `spike-supabase/.env` — usuário cria com credenciais reais (SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_DB_URL)
- [ ] `spike-supabase/docs/` directory — criar antes de gerar os proof docs
- [ ] `spike-supabase/tests/isolation-proof.js` — cobre SPIKE-06 HTTP path
- [ ] `spike-supabase/tests/concurrency-test.js` — cobre SPIKE-07

*(SQL tests existem — rls_isolation_test.sql e rls_insert_isolation_test.sql. Apenas precisam ser executados e output capturado.)*

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | signUp/signInWithPassword via Supabase Auth; service role key em .env (gitignored) |
| V3 Session Management | yes | JWT com app_metadata.tenant_id injetado pelo Auth Hook; session usada como Bearer token |
| V4 Access Control | yes | RLS policies testadas por ataques reais; proof documenta que USING+WITH CHECK bloqueiam |
| V5 Input Validation | yes | p_user_id validado em book_slot() via memberships JOIN (WR-02) |
| V6 Cryptography | no | Sem crypto custom; JWT gerenciado pelo Supabase |

### Known Threat Patterns for Phase 33 Scripts

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Service role key no output do terminal | InfoDisc | Não logar credenciais; logar apenas UUIDs e resultados |
| Usuários de teste não deletados (cleanup falhou) | Tampering | try/finally garante cleanup; emails com timestamp evitam colisão |
| Script de concorrência deixa slot/booking residual | Tampering | try/finally + delete slot+booking no final; data 2099 isola de seed data |
| .env commitado com credenciais | InfoDisc | .gitignore já lista `.env`; verificar com grep antes de commit |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Auth Hook (`custom-access-token`) está deployado e ativo em fasirsbiadcchfgvktzt | Environment Availability | Se não deployado, signIn retorna JWT sem tenant_id → isolation-proof.js falha por razão errada (claims ausentes, não RLS) |
| A2 | `adminClient.auth.admin.deleteUser(uid)` com service role key deleta usuário e cascade-deleta memberships (FK ON DELETE CASCADE existe em 01_schema.sql) | Code Examples | Se cascade não funcionar, memberships ficam órfãs e futuras execuções podem ter colisão de membership |
| A3 | `supabase.rpc('book_slot', params)` com cliente autenticado funciona mesmo com SECURITY DEFINER na função | Standard Stack | Se SECURITY DEFINER causar problema de permissão no contexto RPC, concurrency-test.js falhará com erro de permissão ao invés de SLOT_ALREADY_BOOKED |
| A4 | psql pode ser substituído por Supabase MCP `execute_sql` para os SQL tests sem perda de fidelidade da prova | Environment Availability | Se MCP não estiver disponível durante execução e psql não estiver instalado, SQL tests precisam de instalação manual de psql |

**Se A1 for falso:** Verificar no Supabase Dashboard → Authentication → Hooks se o hook está registrado e deployado. Se não, re-executar Phase 32 deployment task.

---

## Open Questions

1. **psql installation path no Windows**
   - What we know: psql não está no PATH local. Os SQL tests existentes dependem dele.
   - What's unclear: O usuário tem PostgreSQL instalado em path não-padrão? Ou prefere usar MCP como fallback?
   - Recommendation: O planner deve criar duas variantes para a task de SQL tests: (a) via psql se disponível, (b) via Supabase MCP `execute_sql` como fallback. Documentar no PLAN qual foi usado.

2. **Auth Hook status em staging**
   - What we know: Phase 32 deliverable era o Auth Hook. Não confirmado que está ativo.
   - What's unclear: Foi deployado e testado com sucesso em Phase 32?
   - Recommendation: Incluir verificação de smoke test no Wave 0 da fase: fazer login e checar `session.user.app_metadata.tenant_id`. Se missing, bloquear e resolver antes de continuar.

3. **Número ótimo de requests concorrentes**
   - What we know: D-03 define mínimo 50; Claude's Discretion permite até 100.
   - What's unclear: Supabase free tier tem limite de conexões simultâneas que pode throttle requests acima de ~50?
   - Recommendation: Usar 50 como default. Se resultado mostrar muitos `errors` (não SLOT_ALREADY_BOOKED), reduzir para 30. Documentar o número escolhido no proof doc.

---

## Sources

### Primary (HIGH confidence)

- `spike-supabase/tests/rls_isolation_test.sql` — 3 ataques SQL existentes, lógica de asserção verificada
- `spike-supabase/tests/rls_insert_isolation_test.sql` — ataque INSERT WITH CHECK verificado
- `spike-supabase/schema/04_book_slot.sql` — assinatura da função, error codes, WR-02 fix verificado
- `spike-supabase/schema/02_rls.sql` — 15 políticas RLS verificadas
- `spike-supabase/schema/03_seed.sql` — UUIDs de Tenant A/B e memberships verificados
- `.planning/phases/33-provas-isolamento-concorrencia/33-CONTEXT.md` — decisões D-01 a D-05 verificadas
- `npm view @supabase/supabase-js version` → 2.108.1 [VERIFIED: npm registry 2026-06-10]
- `npm view dotenv version` → 17.4.2 [VERIFIED: npm registry 2026-06-10]
- `node --version` → v24.14.0 [VERIFIED: local environment 2026-06-10]

### Secondary (MEDIUM confidence)

- `.planning/phases/32-book-slot-auth-hook/32-RESEARCH.md` — book_slot() patterns, Auth Hook setup, error codes
- `.planning/research/PITFALLS.md` — Pitfall 4 (testing RLS via correct client), Pitfall 18 (concurrent HTTP not sleep loops)

### Tertiary (LOW confidence — ASSUMED)

- `adminClient.auth.admin.deleteUser()` cascade behavior com memberships FK — [ASSUMED] baseado em PostgreSQL ON DELETE CASCADE documentado em 01_schema.sql; não testado na prática

---

## Metadata

**Confidence breakdown:**
- Standard Stack: HIGH — versões verificadas via npm registry; Node.js v24 confirmado local
- Architecture Patterns: HIGH — baseado em código existente (SQL tests, schema, book_slot) + supabase-js v2 API documentada
- Pitfalls: HIGH — Pitfalls 1–3 derivados de análise do código existente; Pitfalls 4–6 de experiência comum Node.js + Supabase
- Environment Availability: HIGH — psql confirmado ausente; Node.js/npm confirmados presentes

**Research date:** 2026-06-10
**Valid until:** 2026-07-10 (APIs Supabase estáveis; supabase-js v2 não tem breaking changes anunciados)
