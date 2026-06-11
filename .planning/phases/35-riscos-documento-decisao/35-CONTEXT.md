# Phase 35: Riscos + Documento de Decisão - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Produzir três entregáveis dentro de `/spike-supabase/docs/`:

1. `password-migration-risk.md` — SPIKE-10: avaliação concreta da migração Firebase→Supabase para ~200 usuários email/password (SCRYPT→bcrypt) e ~30 Google OAuth (re-link), com estratégia de migração recomendada.
2. `realtime-load-risk.md` — SPIKE-11: avaliação de Realtime sob carga: limites free tier, comportamento multi-tenant, recomendação de tier para produção.
3. `DECISION.md` — SPIKE-12: tabela de status por SPIKE (01–11) + parágrafo de recomendação go/conditional-go/no-go + lista de próximos passos se go for dado.

Zero toque em `lib/`, `functions/`, Firebase prod.

</domain>

<decisions>
## Implementation Decisions

### DECISION.md — Formato

- **D-01:** Formato: **tabela de SPIKEs + recomendação**. Tabela com SPIKE-01..11 (colunas: SPIKE | Descrição | Status | Evidência). Status: `proved` / `blocked` / `acceptable-risk` / `conditional`. Parágrafo de recomendação go/conditional-go/no-go. Lista de riscos remanescentes explícitos.

- **D-02:** DECISION.md inclui seção **"Próximos Passos (se go)"** com lista curta: ex. spike de migração de senhas, definir tier Supabase, planejar multi-tenancy schema em prod. Dá continuidade imediata se a decisão for positiva.

### SPIKE-10 — Profundidade da Avaliação de Senhas

- **D-03:** Avaliação **concreta** com pesquisa real — não só conceitual. Inclui:
  - Email/password: SCRYPT (Firebase) vs bcrypt (Supabase), opções de migração (reset de senha forçado, auth paralelo Firebase+Supabase, Supabase import tool se existir), timeline estimado, impacto nos ~200 usuários ativos.
  - Google OAuth: processo de re-link no Supabase Auth, se exige ação do usuário ou é transparente, risco de disruption nos ~30 usuários OAuth.
  - Ambos cobertos separadamente — email/password é risco principal (100% incompatível), OAuth é risco secundário mas real.

- **D-04:** Recomendação explícita de estratégia preferida (qual das opções minimiza disruption para usuários existentes).

### SPIKE-11 — Realtime sob Carga

- **D-05:** Avaliação baseada em dados já coletados (fases 33–34): limite 200 conexões simultâneas free tier, 2M mensagens/mês. Expandir com: comportamento esperado com múltiplos tenants simultaneamente (cada tenant multiplica conexões), recomendação de tier pago se produção tiver >X tenants ativos.

- **D-06:** Se `realtime-evaluation.md` (fase 34) tiver resultado de isolamento cross-tenant, referenciar diretamente. SPIKE-11 foca em carga/limites, não em isolamento (isso é SPIKE-09).

### Peso do Resultado Realtime (SPIKE-09) no DECISION.md

- **D-07:** Se SPIKE-09 retornar FAIL/BLOCKING (tenant A recebe evento de tenant B): **conditional-go**, não no-go automático. DECISION.md documenta a condição: "go somente se Realtime for substituído por polling ou Server-Sent Events antes de produção." Registrar como risco `conditional`, não `blocked`.

- **D-08:** Realtime não é feature crítica para booking (o fluxo de reserva não depende de Realtime). DECISION.md deve deixar claro que FAIL em SPIKE-09 não invalida RLS, book_slot(), ou Auth Hook — que são os pilares críticos do spike.

### Claude's Discretion

- Nome dos arquivos de risco (password-migration-risk.md, realtime-load-risk.md)
- Profundidade da pesquisa web para estratégias de migração SCRYPT→bcrypt
- Número exato de SPIKEs na tabela (01–11 ou 01–12 com SPIKE-12 marcado como "this document")
- Formato do parágrafo de recomendação (1 parágrafo ou bullet points)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Spike Requirements
- `.planning/REQUIREMENTS.md` — SPIKE-10 (password migration risk), SPIKE-11 (Realtime load), SPIKE-12 (DECISION.md go/no-go)

### Evidências das Fases Anteriores (inputs para DECISION.md)
- `spike-supabase/docs/isolation-proof.md` — SPIKE-06: resultado de isolamento cross-tenant (SQL + HTTP)
- `spike-supabase/docs/concurrency-proof.md` — SPIKE-07: resultado anti-double-booking 50+ requests
- `spike-supabase/docs/realtime-evaluation.md` — SPIKE-09: resultado de isolamento Realtime + latência + free tier limits
- `spike-supabase/docs/flutter-proof.md` — SPIKE-08: resultado Flutter mini-app (a preencher manualmente antes da fase)

### Prior Phase Contexts
- `.planning/phases/31-schema-sql-rls/31-CONTEXT.md` — D-05: SPIKE-13 segurança; D-06/D-07: RLS policies; D-04: status enum Firebase completo
- `.planning/phases/34-flutter-mini-app-realtime/34-CONTEXT.md` — D-07: se SPIKE-09 FAIL = bloqueante para Realtime (refina aqui como conditional-go)

### State Context
- `.planning/STATE.md` — decisão v7.0: "go/no-go é julgamento após ler o documento de decisão, não critério binário"

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `spike-supabase/docs/` — pasta já existe com isolation-proof.md, concurrency-proof.md, realtime-evaluation.md (templates/resultados)
- `spike-supabase/docs/realtime-evaluation.md` — contém dados já coletados: limite 200 conexões, 2M mensagens/mês; reusar números diretamente em SPIKE-11

### Established Patterns
- Docs do spike seguem formato markdown com seção Summary + tabelas de resultado + SPIKE-13 audit + Conclusion
- SPIKE-13 audit (grep para service role key) deve aparecer em todo entregável novo

### Integration Points
- DECISION.md referencia todos os docs de prova existentes — é o documento de fechamento do spike
- Após DECISION.md, o milestone v7.0 está completo → trigger para `/gsd-complete-milestone`

</code_context>

<specifics>
## Specific Ideas

- DECISION.md deve ser claro o suficiente para um stakeholder não-técnico entender a recomendação sem ler os docs de prova
- A tabela de SPIKEs é o "at a glance" — a recomendação e riscos são o "executive summary"
- "Próximos Passos (se go)" deve mencionar: spike de migração de senhas, escolha de tier Supabase, planejamento do schema de prod multi-tenant

</specifics>

<deferred>
## Deferred Ideas

- Análise de custo Supabase vs Firebase em produção — fora do escopo deste spike (seria própria análise)
- Plano de rollback se migração falhar — fase futura se go for dado
- Migração de dados históricos (bookings, payments) — escopo de spike de migração separado

</deferred>

---

*Phase: 35-riscos-documento-decisao*
*Context gathered: 2026-06-11*
