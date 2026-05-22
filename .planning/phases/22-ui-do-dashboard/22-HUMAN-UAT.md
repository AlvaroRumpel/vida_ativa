---
status: partial
phase: 22-ui-do-dashboard
source: [22-VERIFICATION.md]
started: 2026-05-22T13:24:29.693Z
updated: 2026-05-22T13:24:29.693Z
---

## Current Test

[aguardando teste humano]

## Tests

### 1. Visual dashboard — gráficos com dados reais
expected: Todos os 4 cards de gráfico renderizam corretamente (BarChart receita, HeatMapCalendar hora×dia, PieChart status, PieChart donut esporte) com dados reais do Firestore
result: [pending]

### 2. Toggle de período atualiza métricas
expected: Ao alternar Semana/Mês/Ano no SegmentedButton, os valores dos KPI cards mudam dinamicamente na mesma tela
result: [pending]

### 3. FCM "Ver" navega para Reservas
expected: Notificação push com botão "Ver" navega corretamente para aba Reservas (índice 3) após inserção do Dashboard no índice 0
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
