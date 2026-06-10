---
phase: 32-book-slot-auth-hook
reviewed: 2026-06-10T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - spike-supabase/schema/04_book_slot.sql
  - spike-supabase/tests/book_slot_test.sql
  - supabase/functions/custom-access-token/index.ts
findings:
  critical: 1
  warning: 2
  info: 3
  total: 6
status: issues_found
---

# Phase 32: Code Review Report

**Reviewed:** 2026-06-10
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Spike validação multi-tenant + Auth Hook analisado. PL/pgSQL book_slot() implementa corretamente lock otimista com SELECT FOR UPDATE NOWAIT. Hook de acesso personalizado segue CVE-2025-48757 (app_metadata, não user_metadata).

**Achados principais:**
- **1 Crítico:** Auth Hook não valida tenant_id do usuário contra claims existentes
- **2 Avisos:** Erro não tratado em Edge Function + p_user_id não validado no book_slot()
- **3 Info:** Teste falta de cobertura + logs revelam informações sensíveis

---

## Critical Issues

### CR-01: Auth Hook não valida tenant_id em contexto de autenticação existente

**File:** `supabase/functions/custom-access-token/index.ts:91-98`

**Issue:**
Hook injeta `tenant_id` e `role` de memberships sem validar se o usuário já possui `tenant_id` em claims. Em cenários onde usuário já autenticado tenta refresh com contexto diferente, hook silenciosamente sobrescreve `app_metadata.tenant_id`.

Risco: Um token válido pode ser manipulado se caller conseguir forçar refresh com memberships() incorreta. Embora memberships() use service role, falha no controller (Auth) permite privilege escalation.

**Fix:**
```typescript
// Após linha 91, ANTES de modificar claims:
// Se usuário já tem tenant_id em claims, validar que é mesmo
const existingTenantId = (claims.app_metadata as Record<string, unknown>)?.tenant_id;
if (existingTenantId && existingTenantId !== membership.tenant_id) {
  console.warn(
    `Auth Hook: tenant_id mismatch for user ${user_id}. ` +
    `Existing: ${existingTenantId}, Membership: ${membership.tenant_id}. ` +
    `Returning claims unchanged (potential session hijack attempt).`
  );
  return new Response(JSON.stringify({ claims }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}
```

Alternativa mais segura: Aceitar que Hook APENAS injeta na primeira autenticação. Para refresh, devolver claims unchanged se já contém tenant_id válido.

---

## Warnings

### WR-01: Auth Hook não trata erro de parsing JSON

**File:** `supabase/functions/custom-access-token/index.ts:43`

**Issue:**
`await req.json()` pode falhar se payload não for JSON válido. Erro não é capturado dentro do try-catch correto — a exceção ocorre ANTES do catch.

Payload malformado causa Internal Server Error (500), mas sem mensagem clara no log. Supabase Auth receberá erro sem contexto.

**Fix:**
```typescript
  try {
    const event = await req.json(); // Mover DENTRO do try-catch existente
    const user_id: string = event.user_id;
    const claims: Record<string, unknown> = event.claims ?? {};
    // resto do código...
  } catch (err) {
    // Captura JSON parse errors + outros erros
    if (err instanceof SyntaxError) {
      console.error("Auth Hook JSON parse error:", err.message);
      return new Response(
        JSON.stringify({ error: "Invalid JSON payload" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }
    // outras exceções como 500
    console.error("Auth Hook unexpected error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error in auth hook" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
```

---

### WR-02: book_slot() não valida p_user_id contra memberships

**File:** `spike-supabase/schema/04_book_slot.sql:67`

**Issue:**
Função aceita `p_user_id` como parâmetro, mas não valida se usuário realmente existe ou pertence ao tenant. Um cliente malicioso pode passar UUID aleatório → booking criado com usuário inválido.

Comentário no código (linhas 30-31) reconhece limitação ("production must validate"). Spike está aceitando risco deliberadamente, mas isso NÃO é seguro para produção.

**Fix:**
```sql
-- Adicionar ANTES do INSERT (linha 67):
-- Validate that p_user_id belongs to p_tenant_id
IF NOT EXISTS (
  SELECT 1 FROM public.memberships
  WHERE user_id = p_user_id AND tenant_id = p_tenant_id
) THEN
  RETURN QUERY SELECT FALSE, 'USER_NOT_IN_TENANT'::TEXT, NULL::UUID;
  RETURN;
END IF;

-- Depois prosseguir com INSERT
INSERT INTO public.bookings (tenant_id, user_id, slot_id, booking_date, status)
VALUES (p_tenant_id, p_user_id, p_slot_id, p_booking_date, 'pending')
RETURNING id INTO v_new_id;
```

**Observação:** Se isso for intencionalmente deferido para produção, documentar explicitamente em CLAUDE.md ou arquivo de segurança.

---

## Info

### IN-01: Teste não cobre SLOT_LOCKED_RETRY

**File:** `spike-supabase/tests/book_slot_test.sql:12-15`

**Issue:**
Apenas 3 casos testados (SUCCESS, SLOT_ALREADY_BOOKED, return structure). SLOT_LOCKED_RETRY é mencionado no comentário como "não testável em SQL sequencial", mas não há teste integrado com múltiplas transações.

Spike atual está aceitando isso (linha 110-115 reconhece limitação). Para produção, testar lock contention via shell script com `psql` paralelo ou Deno + pg-promise.

**Fix:**
Criar `book_slot_test_concurrent.sh` com 2+ processos psql iniciados em paralelo:
```bash
#!/bin/bash
(psql ... -c "BEGIN; SELECT book_slot(...) FOR UPDATE NOWAIT; COMMIT;") &
(psql ... -c "SELECT book_slot(...);") &
wait
```

---

### IN-02: Auth Hook logs revelam tenant_id do usuário

**File:** `supabase/functions/custom-access-token/index.ts:100-102`

**Issue:**
Log em produção imprime `tenant_id` e `role` em plaintext:
```
Auth Hook: injected tenant_id={id} role={role} for user {id}
```

Em logs públicos ou coletados, isso revela estrutura de tenants do sistema.

**Fix:**
Remover tenant_id/role do log em produção. Usar apenas log de sucesso genérico:
```typescript
console.log(`Auth Hook: membership injected for user ${user_id}`);
```

Se auditoria precisa de tenant_id, usar Supabase Audit Logs (integrado, criptografado) em vez de console.log.

---

### IN-03: book_slot() não incrementa índice de contention

**File:** `spike-supabase/schema/04_book_slot.sql:29`

**Issue:**
Comentário menciona que `idx_bookings_slot_date` existe em 01_schema.sql, mas não verifica se realmente foi criado. Se índice não existir, SELECT FOR UPDATE varreria toda tabela → O(n) lock, não O(log n).

**Fix:**
Adicionar verificação de índice no próprio arquivo:
```sql
-- Verify index exists before applying function
-- (defensive check against missing 01_schema.sql)
DO $$
BEGIN
  PERFORM 1 FROM pg_indexes
  WHERE schemaname = 'public' 
    AND tablename = 'bookings'
    AND indexname = 'idx_bookings_slot_date';
  IF NOT FOUND THEN
    RAISE WARNING 'Expected idx_bookings_slot_date not found. book_slot() may have O(n) lock performance.';
  END IF;
END $$;
```

Ou adicionar índice aqui se ainda não existe:
```sql
CREATE INDEX IF NOT EXISTS idx_bookings_slot_date 
  ON public.bookings (slot_id, booking_date);
```

---

_Reviewed: 2026-06-10_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
