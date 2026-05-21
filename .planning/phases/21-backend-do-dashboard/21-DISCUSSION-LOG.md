# Phase 21: Backend do Dashboard - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-20
**Phase:** 21-backend-do-dashboard
**Areas discussed:** Schema de períodos, Denominador de ocupação, Frequência de atualização, Definição de semana, Top 5 clientes, Novo cliente, Taxa de conversão, Horário do scheduled

---

## Schema de Períodos

| Option | Description | Selected |
|--------|-------------|----------|
| Rolling window | 3 docs fixos: 'week', 'month', 'year'. Sempre janela atual. Scheduled CF sobrescreve diariamente. Flutter sempre lê os mesmos 3 IDs. | ✓ |
| Docs por data | Docs '2026-W20', '2026-05', '2026'. Acumula histórico. Flutter precisa calcular qual doc buscar. | |
| Híbrido | current-* + docs históricos por data. Dobra complexidade de escrita. | |

**User's choice:** Rolling window  
**Notes:** Simplicidade para Phase 22 — sempre os mesmos 3 doc IDs.

---

## Denominador de Ocupação (DASH-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Slots ativos do período | CF conta /slots onde active==true no período. Preciso, adiciona 1 query por trigger. | ✓ |
| Número fixo configurável | Admin configura 'X slots por dia' em /config/dashboard. Risco: desatualiza com mudanças de horário. | |
| Calculado no scheduled diário | Apenas scheduled calcula denominador. Taxa de ocupação atualiza 1x por dia. | |

**User's choice:** Slots ativos do período  
**Notes:** Precisão preferida sobre performance.

---

## Frequência de Atualização das Métricas Complexas

| Option | Description | Selected |
|--------|-------------|----------|
| Apenas no scheduled diário | onBookingStateChange atualiza só contadores simples. Top 5, taxa retorno, receita por esporte no scheduled. Defasagem D+1. | ✓ |
| Tudo em tempo real no trigger | onBookingStateChange calcula tudo. Dados sempre atuais. Trigger mais lento e custoso. | |

**User's choice:** Apenas no scheduled diário  
**Notes:** Defasagem D+1 aceitável para métricas complexas.

---

## Definição de "Semana Atual"

| Option | Description | Selected |
|--------|-------------|----------|
| Seg–Dom da semana civil corrente | Semana fixa. Ex: hoje = quinta, semana = seg 19/mai a dom 25/mai. | ✓ |
| Últimos 7 dias corridos | Janela móvel: D-7 até D. Melhor como trending, menos intuitivo como "esta semana". | |

**User's choice:** Seg–Dom da semana civil corrente

---

## Top 5 Clientes — Dados Armazenados (DASH-10)

| Option | Description | Selected |
|--------|-------------|----------|
| Desnormalizar nome na CF | CF lê /users/{id}.displayName e salva com o counter. Flutter exibe sem query extra. | ✓ |
| Só userId, Flutter busca nome | CF salva {userId, count}. Flutter faz N lookups em /users. | |

**User's choice:** Sim, desnormalizar nome na CF

---

## Definição de "Novo Cliente" (DASH-09)

| Option | Description | Selected |
|--------|-------------|----------|
| Primeira reserva confirmada no período | userId cuja primeira reserva confirmed ever foi nesse período. Simples: MIN(createdAt) por userId. | ✓ |
| Nunca reservou antes do período | Query histórica: excluir todos com reservas fora do período. Mais custoso. | |

**User's choice:** Primeira reserva confirmada no período

---

## Taxa de Conversão (DASH-03) — Inclui On_arrival?

| Option | Description | Selected |
|--------|-------------|----------|
| Apenas reservas Pix | Taxa = Pix confirmados / Pix criados. On_arrival excluídas. | |
| Todas as reservas | Taxa = todos confirmados / todos criados. On_arrival conta como 100% convertida. | ✓ |

**User's choice:** Todas as reservas  
**Notes:** Incluir todas. On_arrival contam como convertidas.

---

## Horário do scheduledDailyAggregation

| Option | Description | Selected |
|--------|-------------|----------|
| 03:00 AM America/Sao_Paulo | Baixo tráfego, após meia-noite, inclui reservas do dia anterior. Fuso correto para a academia. | ✓ |
| 00:00 AM America/Sao_Paulo | Exatamente meia-noite, pode conflitar com reservas da virada. | |

**User's choice:** 03:00 AM America/Sao_Paulo

---

## Claude's Discretion

- Lógica de increment/decrement por transição de status no `onBookingStateChange`
- Estrutura da query para contar `/slots` ativos
- Tratamento de erros/falhas nas CFs
- `DashboardData` model Dart com campos nullables

## Deferred Ideas

- Histórico de períodos anteriores para comparação de tendências — v6+
- Export CSV/PDF de relatório — out of scope v5.0
