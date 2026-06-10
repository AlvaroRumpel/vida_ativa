# Phase 33: Provas de Isolamento + Concorrência - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-10
**Phase:** 33-provas-isolamento-concorrencia
**Areas discussed:** Método dos ataques de isolamento, Tool para concorrência, Formato das provas, Reset de estado

---

## Método dos Ataques de Isolamento

| Option | Description | Selected |
|--------|-------------|----------|
| HTTP real com anon key | Script Node.js usa supabase-js com anon key; ataques HTTP reais | |
| SQL tests existentes via psql | Reusar rls_isolation_test.sql (mais rápido, não usa anon key real) | |
| Ambos: SQL tests + script anon key | SQL testa RLS interno; anon key testa API real | ✓ |

**User's choice:** Ambos — prova dupla (SQL interna + HTTP externa)

---

**Q: Usuários de teste já existem no Supabase Auth?**

| Option | Selected |
|--------|----------|
| Sim, usuários de seed já existem | |
| Não, script deve criar usuários de teste | ✓ |
| Não sei, precisa verificar | |

**Notes:** Script cria usuários via signUp, insere memberships via service role key, faz cleanup ao final.

---

**Q: Cleanup automático?**

| Option | Selected |
|--------|----------|
| Sim, criar + cleanup automático | ✓ |
| Criar sem cleanup | |

---

## Tool para Concorrência

| Option | Description | Selected |
|--------|-------------|----------|
| Node.js + Promise.all | Zero dependência nova, usa Promise.allSettled() | ✓ |
| k6 | Load testing dedicado, precisa instalar | |
| Python aiohttp | Precisa Python, adiciona dependência de linguagem | |

**User's choice:** Node.js + Promise.allSettled()

---

**Q: Quantos requests e qual usuário?**

| Option | Selected |
|--------|----------|
| 50 requests, mesmo usuário | ✓ |
| 100 requests, mesmo usuário | |
| 50 requests, usuários diferentes | |

**Notes:** 50 chamadas simultâneas, mesmo client autenticado. Esperado: 1 CONFIRMED, 49 SLOT_ALREADY_BOOKED.

---

## Formato das Provas

| Option | Description | Selected |
|--------|-------------|----------|
| Output raw + resumo estruturado | Tabela markdown + output raw colado | ✓ |
| Só tabela markdown estruturada | Clean mas menos auditável | |
| Só output raw colado | Máxima evidenciabilidade mas difícil de ler | |

**User's choice:** Tabela markdown estruturada + output raw do terminal

---

## Reset de Estado

| Option | Description | Selected |
|--------|-------------|----------|
| Script cria slot de teste dedicado | Idempotente, cria/usa/deleta slot próprio | ✓ |
| Reset manual via 03_seed.sql | Mais simples, requer ação manual | |

**User's choice:** Script cria slot dedicado, cleanup automático ao final.

---

## Claude's Discretion

- Nome exato dos scripts
- Estrutura interna (setup/teardown como funções)
- Número exato de requests (mínimo 50)
- Formato do output raw

## Deferred Ideas

- Realtime evaluation → Phase 34
- Password migration risk → Phase 35
- go/no-go document → Phase 35
