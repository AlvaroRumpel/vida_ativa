# Phase 31: Schema SQL + RLS - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-09
**Phase:** 31-schema-sql-rls
**Areas discussed:** Ambiente Supabase, Organização dos SQL files, Seed data fase 31, bookings.status — escopo do enum

---

## Ambiente Supabase

| Option | Description | Selected |
|--------|-------------|----------|
| Cloud (projeto staging real) | Cria projeto Supabase.com dedicado. Dashboard ativo, Auth real, credenciais no .env. Espelha exatamente produção. | ✓ |
| Local CLI (supabase start) | Postgres + Auth rodam local via Docker. Sem internet, sem billing, mais rápido para iterar. | |

**User's choice:** Cloud (projeto staging real)
**Notes:** Quer espelhar o ambiente real; Auth e PostgREST reais são importantes para validar o spike com fidelidade.

---

## Organização dos SQL files

| Option | Description | Selected |
|--------|-------------|----------|
| Múltiplos arquivos por concern | `01_schema.sql`, `02_rls.sql`, `03_seed.sql`. Fácil de reaplicar partes individualmente. | ✓ |
| Um único arquivo init.sql | Tudo junto. Simples de rodar. | |

**User's choice:** Múltiplos arquivos por concern
**Notes:** Preferência pelo padrão recomendado na pesquisa.

---

## Seed data fase 31

| Option | Description | Selected |
|--------|-------------|----------|
| Sim, incluir seed nessa fase | 2-3 tenants, 4-6 users, slots e bookings de teste. Necessário para verificar RLS manualmente. | ✓ |
| Não, só estrutura vazia | Schema + RLS only. Seed fica para fase 33. | |

**User's choice:** Sim, incluir seed nessa fase
**Notes:** Queria poder verificar RLS manualmente antes das provas formais.

---

## bookings.status — escopo do enum

| Option | Description | Selected |
|--------|-------------|----------|
| Mínimo do spike | `pending`, `confirmed`, `cancelled`. Suficiente para validar RLS. | |
| Firebase completo | Todos os 7 status: `pending`, `confirmed`, `cancelled`, `rejected`, `pending_payment`, `expired`, `refunded`. | ✓ |

**User's choice:** Firebase completo
**Notes:** Quer avaliar se o schema Supabase suporta o modelo completo sem retrabalho futuro.

---

## Claude's Discretion

- Naming exato das colunas
- Tipos de coluna (UUID vs BIGSERIAL)
- Índices auxiliares
- Enum Postgres vs CHECK constraint para status

## Deferred Ideas

- book_slot() → Phase 32
- Auth Hook → Phase 32
- Provas cross-tenant → Phase 33
- Flutter mini-app → Phase 34
