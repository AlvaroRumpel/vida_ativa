# Phase 29: Admin Dashboard - Context

**Gathered:** 2026-06-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 29 redesenha visualmente a `DashboardTab` com identidade Arena Esportivo completa:
- KPI grid 2×N com hairlines, sem Card/sombra, Anton 32px + delta mono
- Period selector: underline tabs (mono uppercase) substituindo SegmentedButton
- Receita: custom Containers proporcionais (sem fl_chart BarChart) com labels mono
- Heatmap 7×7: custom GridView com escala laranja rgba(255,77,23,opacity)
- Status: Donut fl_chart (centerSpaceRadius) com 4 categorias + total Anton no centro
- Receita por esporte: hairline rows com progress bar 3px laranja

Completa: ADMN-26, ADMN-27, ADMN-28, ADMN-29

Fora de escopo: DashboardCubit, DashboardData model, Cloud Functions, dados históricos/trend.

</domain>

<decisions>
## Implementation Decisions

### Heatmap de Ocupação (ADMN-28)

- **D-01:** DashboardData não tem breakdown hora×dia — implementar como placeholder visual funcional.
- **D-02:** GridView custom 7 colunas (SEG–DOM) × N linhas de horários (08h–20h), cada célula `Container` com escala `rgba(255,77,23,opacity)`. Valor 0 → `AppTheme.lineHair` (célula vazia).
- **D-03:** Legenda de escala laranja: "BAIXA" · 5 quadrados de opacidade crescente · "ALTA" em mono 9px.
- **D-04:** Eixo Y (horários) em JBM mono 9px concrete. Eixo X (dias) em mono 8.5px concrete.
- **D-05:** Sem texto "Dados em breve" — estrutura Arena presente, células em lineHair indicam ausência de dados.
- **D-06:** `flutter_heatmap_calendar` NÃO usado — não suporta escala de cor arbitrária laranja.

### KPI Grid (ADMN-26)

- **D-07:** Layout: grid `Wrap` ou `Table` 2×N com hairlines divisórias — sem `GridView.count` com `Card`.
- **D-08:** Por célula: kicker JBM mono 9.5px uppercase concrete + Scoreboard 32px (AppTheme.display) + delta mono 10px abaixo.
- **D-09:** Delta: mostrar `↑ X%` / `↓ X%` em court/orangeDk se dado disponível. Mostrar `--` (JBM mono concrete) quando `null`. Sem sparkline — DashboardData não tem trend histórico.
- **D-10:** R$ prefixo em JBM mono 11px concrete quando unidade for receita. `%` sufixo em Anton 18px concrete quando unidade for percentagem.
- **D-11:** Último item ímpar ocupa grid inteiro (gridColumn: 1/-1) para evitar célula vazia.
- **D-12:** Hairline vertical 0.5px lineHair entre colunas; hairline horizontal 0.5px lineHair entre linhas.

### Period Selector

- **D-13:** Substituir `SegmentedButton` por Row de tabs underline: `padding: 14px 0`, `borderBottom: 2px solid laranja` (ativo) ou `2px solid transparent` (inativo). JBM mono 10px uppercase.
- **D-14:** Período ativo: AppTheme.ink. Inativo: AppTheme.concrete.

### Revenue Chart — Barras Simples (ADMN-27)

- **D-15:** Remover fl_chart BarChart. Implementar como `Row` de 3 colunas com `Container` proporcionais.
- **D-16:** Altura de cada barra: `(valor / máximo) * 100%` relativa à altura fixa da seção (130px).
- **D-17:** Cores: Total = AppTheme.ink, Pix = AppTheme.primary (laranja), Presencial = AppTheme.concrete.
- **D-18:** Label acima da barra: "R$ X.XXX" em JBM mono 10px ink. Label abaixo: kicker mono 9.5px uppercase concrete.
- **D-19:** Zero border radius — `BorderRadius.zero`.
- **D-20:** Header da seção: kicker "RECEITA" mono + SPrice do total + delta em court se > 0.

### Status Distribution — Donut (ADMN-28 / existente)

- **D-21:** Manter fl_chart `PieChart` com `centerSpaceRadius: 52` (donut mode).
- **D-22:** 4 categorias: Confirmadas (AppTheme.court), Pendentes (AppTheme.sun), Canceladas (AppTheme.orangeDk), Expiradas (AppTheme.concrete).
- **D-23:** Total no centro: Anton (AppTheme.display 28px) + "RESERVAS" mono 9px abaixo.
- **D-24:** Legenda lateral: ícone 8×8 + label UI 12.5px + percentagem mono 10px + Scoreboard 18px. Grid 4 colunas → legenda.
- **D-25:** `sectionsSpace: 2`, `pieTouchData: disabled`.

### Receita por Esporte — Progress Bars (ADMN-29)

- **D-26:** Remover `PieChart` donut de sport. Substituir por hairline rows — um por esporte.
- **D-27:** Por row: `padding: 14px 0`, `borderTop: 1px lineHair` (primeiro: `1px line`).
- **D-28:** Linha 1: nome esporte em Manrope 14px bold + `SPrice` à direita.
- **D-29:** Linha 2: barra de progresso 3px — `Container(height:3, color:lineHair)` com overlay `Container` laranja `width: share * 100%` + texto "XX% · XXh" em mono 10px concrete à direita.
- **D-30:** `share` calculado client-side: `sport.revenue / data.totalRevenue`. Se `totalRevenue == 0` → share = 0.
- **D-31:** `hours` não disponível em DashboardData — exibir apenas percentagem ("XX%"), sem "· XXh".

### Claude's Discretion
- Padding externo das seções (22px horizontal sugerido pelo design bundle)
- Altura mínima das células do heatmap (22px no design)
- Espaçamento gap entre células do heatmap (3px)
- Tamanho do centerSpaceRadius do donut (ajustar visualmente)
- Ordem das seções no scroll (manter atual: period → KPI → receita → heatmap → status → esporte)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design Reference
- `C:/Users/alvar/.claude/projects/f---geral-Projetos-vida-ativa/design-bundle/vida-ativa/project/screens-sport/admin-dashboard.jsx` — Design bundle completo da DashboardTab Arena (fonte de verdade para layout)

### Design System
- `lib/core/theme/app_theme.dart` — AppTheme completo; NÃO modificar
- `.planning/research/PITFALLS.md` — pitfalls v6.0 (Anton height clip, hardcoded colors)

### Arquivo Principal a Reescrever
- `lib/features/admin/ui/dashboard_tab.dart` — redesign completo (arquivo existe)

### Modelo de Dados (leitura apenas)
- `lib/core/models/dashboard_data.dart` — DashboardData, RevenueBySportEntry — NÃO modificar

### Padrões de Referência (fases anteriores)
- `lib/features/admin/ui/admin_booking_row.dart` — padrão hairline row com Anton
- `lib/features/admin/ui/pricing_tab.dart` — padrão hairline rows + barra laranja 3px (Phase 28)
- `lib/core/widgets/sport_btn.dart` — SportBtn variantes
- `lib/features/admin/ui/slot_management_tab.dart` — padrão day selector underline

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AppTheme.display(size:)` — Anton/Scoreboard helper
- `AppTheme.mono(size:)` — JBM mono helper
- `AppTheme.ui(size:)` — Manrope helper
- `AppTheme.lineHair` — #EAE3CE para hairlines e fundo de heatmap
- `AppTheme.line` — #D9D2BE para divisores maiores
- `AppTheme.primary` (laranja #FF4D17) — barras e células heatmap
- `AppTheme.court` — verde para delta positivo / "Confirmadas"
- `AppTheme.orangeDk` — vermelho-laranja para delta negativo / "Canceladas"
- `AppTheme.sun` — amarelo para "Pendentes"
- `AppTheme.concrete` — cinza concreto para labels e kickers
- `fl_chart` — ainda usado para PieChart/Donut (status); BarChart removido desta tab

### Dead Code a Remover
- `_buildKpiCard` com `Card(elevation: 1)` — substituído por grid hairline
- `_buildRevenueChart` com fl_chart BarChart — substituído por Containers simples
- `_buildSportDonut` com PieChart donut — substituído por progress bars hairline
- `_buildHeatmap` com placeholder "Dados em breve" — substituído por GridView
- `_sportColor` helper — hardcoded colors; substituído por AppTheme tokens

### Established Patterns
- Hairline rows: `DecoratedBox` com `Border(top: BorderSide(color: AppTheme.lineHair, width: 0.5))`
- Sem fundo colorido: remover todos `Container(color: ...)` hardcoded
- Sem Card elevation
- Heatmap: custom `GridView` (não `flutter_heatmap_calendar`)

### Integration Points
- `DashboardCubit` e `DashboardState` — não modificar
- `DashboardLoaded` state com `week`, `month`, `year` — manter acesso
- `_selectedPeriod` state local — manter lógica, só atualizar UI do selector

</code_context>

<specifics>
## Specific Ideas

- Heatmap vazio (placeholder) deve ter estrutura completa Arena: eixos, legenda de escala, grid — não só mensagem de texto
- Revenue chart: 3 colunas fixas (Total/Pix/Presencial) — sem loop dinâmico por série
- Receita por esporte: sem coluna de horas (DashboardData não tem) — apenas percentagem
- Design bundle linha 244–248 define legenda heatmap: quadrados `width:10, height:10` com opacidades `[0.15, 0.35, 0.55, 0.75, 1]`

</specifics>

<deferred>
## Deferred Ideas

- Dados reais hora×dia para heatmap — requer extensão de DashboardData + Cloud Function — fase futura
- Sparklines por KPI — requer série temporal histórica — fase futura
- Horas por esporte na seção "Receita por esporte" — requer campo em RevenueBySportEntry — fase futura

</deferred>

---

*Phase: 29-admin-dashboard*
*Context gathered: 2026-06-05*
