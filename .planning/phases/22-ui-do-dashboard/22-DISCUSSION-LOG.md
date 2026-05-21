# Phase 22: UI do Dashboard - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-21
**Phase:** 22-ui-do-dashboard
**Areas discussed:** Tab + período toggle, Gráfico de receita (DASH-05), Layout e scroll dos gráficos, Estados vazios / dados D+1

---

## Tab + período toggle

| Option | Description | Selected |
|--------|-------------|----------|
| Primeira aba | Dashboard como índice 0; _reservasTabIndex passa de 2 para 3 | ✓ |
| Última aba | Após Ajustes; menos disruptivo | |
| Segunda aba | Após Slots; requer ajuste de índice | |

**User's choice:** Primeira aba

---

| Option | Description | Selected |
|--------|-------------|----------|
| SegmentedButton nativo | Material 3, sem package extra | ✓ |
| TabBar secundário | Tabs menores abaixo do AppBar | |
| ChoiceChip row | Row de 3 chips | |

**User's choice:** SegmentedButton nativo

---

| Option | Description | Selected |
|--------|-------------|----------|
| Fixo no topo | Fora do scroll; Column com toggle + SingleChildScrollView | ✓ |
| Dentro do scroll | Some quando admin rola para baixo | |

**User's choice:** Fixo no topo

---

| Option | Description | Selected |
|--------|-------------|----------|
| Tudo junto na mesma aba | Cards + gráficos em scroll único | ✓ |
| Abas separadas dentro de Dashboard | Sub-tabs Métricas e Gráficos | |

**User's choice:** Tudo junto na mesma aba

---

| Option | Description | Selected |
|--------|-------------|----------|
| Dashboard | Nome descritivo | ✓ |
| Painel | Português | |
| Métricas | Foca no conteúdo | |

**User's choice:** "Dashboard"

---

## Gráfico de receita (DASH-05)

| Option | Description | Selected |
|--------|-------------|----------|
| Linha | LineChart fl_chart — tendência temporal | ✓ (inicial) |
| Barra | BarChart fl_chart — comparação de valores | → redefinido |
| Toggle | Botão para trocar entre linha e barra | |

**User's choice:** Linha inicialmente, porém redefinido para BarChart após descoberta de que DashboardData não tem série temporal diária.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Simplificar: Pix vs Presencial | BarChart com split de pagamento | ✓ |
| Query client-side | Buscar /bookings no Flutter por data | |
| Adicionar campo backend (Phase 21 gap) | dailyRevenue[] no doc de dashboard | |

**User's choice:** Simplificar com BarChart Pix vs Presencial

---

| Option | Description | Selected |
|--------|-------------|----------|
| 2 barras: Pix + Presencial | Mais limpo | |
| 3 barras: Total + Pix + Presencial | Total como referência visual | ✓ |

**User's choice:** 3 barras (Total + Pix + Presencial)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Abaixo do gráfico | Padrão fl_chart | ✓ |
| Tooltip/inline | Label nas barras ou tooltip ao tocar | |

**User's choice:** Abaixo do gráfico

---

## Layout e scroll dos gráficos

| Option | Description | Selected |
|--------|-------------|----------|
| Métricas → Receita → Heatmap → Pizza → Donut | KPIs primeiro, detalhes depois | ✓ |
| Receita → Heatmap → Pizza → Donut → Métricas | Gráficos primeiro | |
| Métricas → Heatmap → Receita → Pizza → Donut | Heatmap antes de receita | |

**User's choice:** Métricas → Receita → Heatmap → Pizza → Donut

---

| Option | Description | Selected |
|--------|-------------|----------|
| Card com título por gráfico | Flutter Card + Text acima | ✓ |
| Seções com divider | Header + divider, sem card | |
| Sem container visual | Direto no scroll | |

**User's choice:** Card com título por gráfico

---

| Option | Description | Selected |
|--------|-------------|----------|
| Grid 2x3 | GridView 2 colunas | ✓ |
| Lista vertical | 1 coluna | |
| Scroll horizontal | Row scrollable | |

**User's choice:** Grid 2x3

---

| Option | Description | Selected |
|--------|-------------|----------|
| Esconde card inteiro quando sem dados | Sem placeholder | |
| Mostra card com "Nenhum dado de esporte" | Empty state informativo | ✓ |

**User's choice:** Mostra card com mensagem "Nenhum dado de esporte ainda"

---

| Option | Description | Selected |
|--------|-------------|----------|
| Altura fixa 200px | SizedBox previsível | |
| Aspect ratio 16:9 | Escala com largura da tela | ✓ |

**User's choice:** AspectRatio 16:9

---

## Estados vazios / dados D+1

| Option | Description | Selected |
|--------|-------------|----------|
| '--' no lugar do valor | Simples, não confunde com zero | ✓ |
| Skeleton loader | Pulsante enquanto null | |
| Esconde o card até ter dado | Layout dinâmico | |

**User's choice:** '--'

---

| Option | Description | Selected |
|--------|-------------|----------|
| CircularProgressIndicator central | Padrão do app | ✓ |
| Shimmer/skeleton de toda a tela | Layout ghost | |

**User's choice:** CircularProgressIndicator central

---

| Option | Description | Selected |
|--------|-------------|----------|
| Texto de erro + botão Tentar Novamente | Widget centralizado | |
| SnackBar de erro + manter conteúdo anterior | Menos disruptivo | |
| Substituir tela por mensagem | Toda tela de erro | |

**User's choice (custom):** SnackBar de erro com botão "Tentar Novamente" + timestamp "Última atualização: HH:MM" discreto abaixo do SegmentedButton (usando `updatedAt`)

---

## Claude's Discretion

- Estrutura interna de DashboardTab (StatefulWidget vs StatelessWidget)
- State local para selectedPeriod dentro de DashboardTab
- Cores das barras fl_chart
- Configuração do flutter_heatmap_calendar
- Formatação de valores monetários

## Deferred Ideas

- Série temporal diária de receita (linha real) — requer backend change, v6+
- Export CSV/PDF — DASH-F01, out of scope
- Atualização em tempo real via FCM — DASH-F02, out of scope
- Filtros avançados — DASH-F03, out of scope
