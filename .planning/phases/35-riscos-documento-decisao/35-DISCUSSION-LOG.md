# Phase 35: Riscos + Documento de Decisão - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-11
**Phase:** 35-riscos-documento-decisao
**Areas discussed:** DECISION.md formato e estrutura, Profundidade SPIKE-10 (senhas), Peso do resultado Realtime

---

## DECISION.md — Formato e Estrutura

| Option | Description | Selected |
|--------|-------------|----------|
| Tabela SPIKE + recomendação | Tabela SPIKE-01..11 com status, parágrafo recomendação go/conditional-go/no-go, riscos remanescentes | ✓ |
| ADR formal | Architecture Decision Record: Context/Decision/Consequences/Alternatives | |
| Narrativa livre | Documento em prosa, mais flexível, menos scannable | |

**User's choice:** Tabela SPIKE + recomendação
**Notes:** Fácil de ler e verificar; adequado para stakeholders não-técnicos.

Follow-up — Próximos Passos:

| Option | Selected |
|--------|----------|
| Sim, lista curta de próximas fases | ✓ |
| Não, só a recomendação | |

---

## Profundidade SPIKE-10 (Senhas)

| Option | Description | Selected |
|--------|-------------|----------|
| Estratégia concreta | Pesquisa real: SCRYPT→bcrypt, opções (reset/auth paralelo/import), timeline, impacto ~200 users | ✓ |
| Risco conceitual | Só pontuar incompatibilidade, sem pesquisa aprofundada | |
| Avaliar só viabilidade | Só responder: é viável tecnicamente? | |

**User's choice:** Estratégia concreta
**Notes:** Deve servir como plano de ação se go for aprovado.

Follow-up — Google OAuth:

| Option | Selected |
|--------|----------|
| Sim, cobrir ambos separadamente | ✓ |
| Email/password primeiro, OAuth resumido | |

**Notes:** OAuth re-link (~30 usuários) é risco secundário mas real — cobrir separadamente.

---

## Peso do Resultado Realtime (SPIKE-09)

| Option | Description | Selected |
|--------|-------------|----------|
| Bloqueador automático para go | FAIL = no-go imediato, sem workaround | |
| Go conditional | FAIL vira condição: go só se Realtime substituído por polling/SSE | ✓ |
| Risco aceitável | Realtime não é crítico agora, registrar como risco conhecido | |

**User's choice:** Go conditional
**Notes:** Realtime não é feature crítica para booking. FAIL não invalida RLS + book_slot() + Auth Hook (os pilares críticos). Mas deve ser condição explícita no DECISION.md.

---

## Claude's Discretion

- Nome dos arquivos de risco (password-migration-risk.md, realtime-load-risk.md)
- Profundidade da pesquisa web para SCRYPT→bcrypt
- Formato do parágrafo de recomendação

## Deferred Ideas

- Análise de custo Supabase vs Firebase em produção
- Plano de rollback se migração falhar
- Migração de dados históricos (bookings, payments)
