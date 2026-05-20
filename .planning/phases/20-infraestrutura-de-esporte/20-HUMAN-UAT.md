---
status: partial
phase: 20-infraestrutura-de-esporte
source: [20-VERIFICATION.md]
started: 2026-05-20T00:00:00Z
updated: 2026-05-20T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Dropdown visível com dados reais
expected: Abrir slot de reserva, dropdown "Esporte (opcional)" aparece com opções. Selecionar esporte, confirmar reserva. Verificar doc Firestore tem campo `sport` com valor selecionado.
result: [pending]

### 2. Dropdown oculto quando /config/sports vazio
expected: Deletar doc /config/sports no console Firebase. Abrir sheet de reserva. Verificar que dropdown não aparece (D-04).
result: [pending]

### 3. Seção Esportes no admin — interação completa
expected: Admin > Configurações > seção "Esportes" exibe lista reordenável. Reordenar (arrastar), adicionar novo esporte (TextField + botão), remover (IconButton), salvar. Verificar Firestore atualizado.
result: [pending]

### 4. Validação de input no admin
expected: Tentar adicionar esporte duplicado → snackbar de erro "Esporte já existe". Tentar nome >50 chars → snackbar "Nome muito longo".
result: [pending]

### 5. Chip de esporte em AdminBookingCard e AdminBookingDetailSheet
expected: Reserva com esporte selecionado: card exibe chip colorido com nome do esporte. Abrir detalhe: info-row com ícone de esporte e nome.
result: [pending]

### 6. Backward compat — reservas antigas sem campo esporte
expected: Reserva sem campo `sport` (criada antes da phase 20): card não exibe chip, detail sheet não exibe info-row de esporte. Sem erros ou dados ausentes visíveis.
result: [pending]

## Summary

total: 6
passed: 0
issues: 0
pending: 6
skipped: 0
blocked: 0

## Gaps
