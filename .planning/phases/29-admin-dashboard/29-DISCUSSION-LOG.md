# Phase 29: Admin Dashboard - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-05
**Phase:** 29-admin-dashboard
**Areas discussed:** Heatmap dados vs placeholder, KPI delta e sparklines, Revenue chart fl_chart vs Containers, Status distribution PieChart → Donut

---

## Heatmap — dados vs placeholder

| Option | Description | Selected |
|--------|-------------|----------|
| Placeholder Arena (Recommended) | Grid custom 7×7 vazio em lineHair, sem texto 'Dados em breve'. Título mono + legenda laranja. ADMN-28 satisfeito visualmente. | ✓ |
| Remover heatmap desta fase | ADMN-28 é marcação visual; sem dados, remover seção. | |

**User's choice:** Placeholder Arena
**Notes:** Estrutura Arena completa presente; dados reais ficam para fase futura.

---

## KPI delta e sparklines

| Option | Description | Selected |
|--------|-------------|----------|
| Delta '--' quando ausente, sem sparkline (Recommended) | Layout kicker + Scoreboard + delta mono. Delta '--' se null. Sparkline omitida — sem histórico. | ✓ |
| Omitir delta completamente | Apenas kicker + valor. Diverge do design bundle. | |

**User's choice:** Delta '--' quando ausente, sem sparkline
**Notes:** DashboardData não tem trend histórico — não modificar modelo nesta fase.

---

## Revenue chart — fl_chart vs Containers

| Option | Description | Selected |
|--------|-------------|----------|
| Custom Containers (como no JSX) (Recommended) | 3 Containers proporcionais em Row, altura relativa, zero eixos. Label mono acima + kicker mono abaixo. Fiel ao design bundle. | ✓ |
| Manter fl_chart BarChart | Remove borderRadius, substitui cores. Grid Y e eixos não existem no design. | |

**User's choice:** Custom Containers
**Notes:** fl_chart ainda usado para PieChart/Donut — apenas BarChart removido desta seção.

---

## Status distribution — PieChart → Donut

| Option | Description | Selected |
|--------|-------------|----------|
| 4 categorias + total no centro (Recommended) | Confirmadas/Pendentes/Canceladas/Expiradas. Total Anton no centro. Representa todos os estados reais. | ✓ |
| 3 categorias como no design (sem Expiradas) | Conf/Pend/Canc. Mais simples, fiel ao JSX. Expiradas são estado real significativo. | |

**User's choice:** 4 categorias + total no centro
**Notes:** AppTheme.concrete para Expiradas. fl_chart PieChart com centerSpaceRadius.

---

## Claude's Discretion

- Padding interno das seções (22px sugerido)
- Altura mínima das células do heatmap
- Gap entre células do heatmap
- centerSpaceRadius do donut
- Ordem das seções no scroll

## Deferred Ideas

- Dados reais hora×dia para heatmap — extensão DashboardData + Cloud Function
- Sparklines por KPI — série temporal histórica
- Horas por esporte — campo RevenueBySportEntry
