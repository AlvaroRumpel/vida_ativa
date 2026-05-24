---
status: complete
phase: 21-backend-do-dashboard
source: [ROADMAP.md success criteria]
started: 2026-05-23T00:00:00Z
updated: 2026-05-23T00:00:00Z
---

## Current Test

[all tests complete]

## Tests

### 1. Cloud Function atualiza contadores ao confirmar/cancelar reserva
expected: Fazer reserva → confirmar no admin → verificar /config/dashboard no Firestore mostra contadores atualizados (receita, ocupação). Cancelar → contadores revertem.
result: pass

### 2. Documentos de agregação existem para semana/mês/ano
expected: Console Firebase → /config/dashboard → verificar que existem documentos com campos de receita, ocupação, contagem de clientes e distribuição por esporte para períodos week/month/year.
result: pass

### 3. DashboardCubit carrega dados corretamente
expected: Admin → Dashboard → toggle Semana/Mês/Ano → KPI cards atualizam sem erros. Estado de loading visível antes dos dados aparecerem.
result: pass — revenueBySport vazio é esperado: só atualiza às 03:00 BRT via scheduledDailyAggregation (D+1 lag por design)

### 4. Regras Firestore bloqueiam escrita cliente em /config/dashboard
expected: Apenas admin pode ler /config/dashboard. Cliente não pode escrever (somente Cloud Functions escrevem). Verificável via Firestore Rules Playground no console Firebase.
result: pass — code review: allow write: if false em /config/dashboard e /config/dashboard/periods/{period} (D-16)

## Summary

total: 4
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
