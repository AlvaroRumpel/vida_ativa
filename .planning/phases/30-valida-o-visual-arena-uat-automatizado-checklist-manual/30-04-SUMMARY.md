---
phase: "30"
plan: "04"
subsystem: "uat-checklist"
tags: [uat, visual-validation, arena-esportivo, checklist]
key-files:
  created:
    - .planning/phases/30-valida-o-visual-arena-uat-automatizado-checklist-manual/30-CHECKLIST.md
    - .planning/phases/30-valida-o-visual-arena-uat-automatizado-checklist-manual/30-04-SUMMARY.md
decisions: []
metrics:
  completed: "2026-06-07"
---

# Phase 30 Plan 04: UAT Screenshot Comparison Checklist Summary

## One-liner

Checklist manual de 96 itens visuais em 9 telas, mapeando tokens SPORT.* do design bundle para AppTheme.* do Flutter com descrições específicas para comparação por screenshot.

## What was done

Lidos os arquivos de design bundle JSX (arena-sport.jsx, admin-slots.jsx, admin-bookings.jsx, admin-users.jsx) e os arquivos Flutter de implementação (booking_confirmation_sheet.dart, my_bookings_screen.dart, admin_screen.dart, pricing_tab.dart, settings_tab.dart).

Gerado `30-CHECKLIST.md` com instruções de uso e 9 seções de tela, cada uma com descrição visual de referência e checklist de itens `- [ ]` verificáveis por screenshot.

## Checklist items per screen

| # | Tela | Itens |
|---|------|-------|
| 1 | Booking Confirmation Sheet | 13 |
| 2 | Pix QR Screen | 7 |
| 3 | Minhas Reservas (MyBookings) | 11 |
| 4 | Admin Frame (header + TabBar) | 10 |
| 5 | Admin — Aba Slots | 13 |
| 6 | Admin — Aba Reservas | 16 |
| 7 | Admin — Aba Usuários | 11 |
| 8 | Admin — Aba Preços | 13 |
| 9 | Admin — Aba Ajustes | 16 |
| **Total** | | **110** |

## Token mapping applied

| SPORT.* (JSX) | AppTheme.* (Flutter) |
|---------------|----------------------|
| SPORT.orange (#FF4D17) | AppTheme.orange |
| SPORT.ink (#0E0E0C) | AppTheme.ink |
| SPORT.paper (#FBF8F0) | AppTheme.paper |
| SPORT.sand (#F4EFE2) | AppTheme.sand |
| SPORT.concrete (#6B6B66) | AppTheme.concrete |
| SPORT.line (#D9D2BE) | AppTheme.line |
| SPORT.lineHair (#EAE3CE) | AppTheme.lineHair |
| SPORT.court (#1B5E2A) | AppTheme.court |
| S_DISPLAY (Anton) | AppTheme.display() |
| S_UI (Manrope) | AppTheme.ui() |
| S_MONO (JetBrains Mono) | AppTheme.mono() |

## Files created

- `.planning/phases/30-valida-o-visual-arena-uat-automatizado-checklist-manual/30-CHECKLIST.md` — checklist principal com 110 itens em 9 telas
- `.planning/phases/30-valida-o-visual-arena-uat-automatizado-checklist-manual/30-04-SUMMARY.md` — este arquivo

## Deviations from Plan

None — plan executed exactly as written.
