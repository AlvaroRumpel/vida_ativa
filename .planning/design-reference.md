# Design Reference — Arena Esportivo

**Bundle URL:** https://api.anthropic.com/v1/design/h/N6in3WOqq9wB5tVbZh37zw?open_file=Arena+-+Esportivo.html

**Extracted to:** `C:/Users/alvar/.claude/projects/f---geral-Projetos-vida-ativa/design-bundle/vida-ativa/`

**Key files:**
- `project/screens-sport/admin-slots.jsx` — Slots tab design
- `project/screens-sport/admin-bookings.jsx` — Reservas tab design
- `project/screens-sport/admin-users.jsx` — Usuários tab design
- `project/arena-sport.jsx` — Design tokens (colors, typography)

## Design Tokens

| Token | Value | Use |
|-------|-------|-----|
| `SPORT.sand` | `#F4EFE2` | bg principal |
| `SPORT.paper` | `#FBF8F0` | surface lifted |
| `SPORT.ink` | `#0E0E0C` | near-black |
| `SPORT.concrete` | `#6B6B66` | text dim |
| `SPORT.line` | `#D9D2BE` | divisor |
| `SPORT.lineHair` | `#EAE3CE` | hairline |
| `SPORT.orange` | `#FF4D17` | accent primary |
| `SPORT.court` | `#1B5E2A` | success/pix |
| `SPORT.sun` | `#FFB800` | warning |

**Fonts:** Anton (display), Manrope (UI), JetBrains Mono (mono)

## Admin Header (shared)

```
Wordmark | "PAINEL ADMIN" mono 10px | "cliente →" orange mono
[Title Anton 40px]                          [count mono 11px]
──────────────────────────────────────
[DASHBOARD] [SLOTS] ... tabs underline orange 2px
```

## Admin Slots

**Day selector:**
- Row: `← [SEG\n10] [TER\n11] ... [DOM\n16] →`
- Day abbr: mono 8px, selected = ink; unselected = concrete
- Date: Anton 18px, underline orange 2px if selected

**Slot row (3-col grid: 78px | flex | auto):**
- Time: Anton 32px — orange if booked, ink if not; opacity 0.4 if inactive
- Center: booked → name (UI 13px bold) + "RESERVADO" (mono orange uppercase); not booked → price (concrete)
- Right: booked → chevron; not booked → toggle switch

## Admin Reservas

**Date selector:** `← [QUINTA\n13 DE MARÇO] →` — day in mono 9.5px uppercase, date in Anton 24px

**Booking row (2 rows):**
- Row 1: Anton 36px time + name UI 15px bold + participants UI 12px concrete | price
- Row 2: status mono 10px uppercase colored | pills (if pending: `[✓ CONFIRMAR]` ink filled + `[RECUSAR]` quiet outline)

## Admin Usuários

**User row (3-col: 40px | flex | auto):**
- Avatar: 40x40 circle — orange bg if admin, ink bg if not; initial letter Anton 20px white
- Center: name UI 14px bold + (email mono 10.5px concrete + `· N` count if >0)
- Right: admin → "ADMIN" mono orange uppercase; not admin → "Promover" pill quiet

**No UserDetailSheet** — actions inline in row only
