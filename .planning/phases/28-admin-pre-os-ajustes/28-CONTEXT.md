# Phase 28: Admin Preços + Ajustes - Context

**Gathered:** 2026-06-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 28 redesenha as abas Preços e Ajustes do painel admin com identidade Arena Esportivo:
- `pricing_tab.dart` — faixas hairline com Anton 30px hora, barra laranja timeline 3px, Anton 44px preço, SportBtn.filledInk "Salvar tabela"
- `settings_tab.dart` — toggle Pix com Anton 26px, underline fields credenciais MP, esportes em hairline rows

Completa: ADMN-22, ADMN-23, ADMN-24, ADMN-25

Fora de escopo: lógica de PricingCubit/SettingsCubit (não mudar), Phase 29 (Dashboard).

</domain>

<decisions>
## Implementation Decisions

### Aba Preços — PricingTab (ADMN-22, ADMN-23)

- **D-01:** Cada faixa de preço exibe em hairline row (sem Card/sombra):
  - Label: "FAIXA 01 · SEG–SEX" em mono 9.5px uppercase concrete
  - Horários: Anton 30px (Scoreboard) com "→" Anton 20px concrete entre eles
  - Preço: Anton 44px (direita do row)
  - Timeline bar: height 3px, fundo lineHair, segmento laranja proporcional ao horário (left: from/24*100%, width: (to-from)/24*100%)
- **D-02:** Tap numa faixa → abre sheet existente (lógica PricingCubit preservada). Zero mudança de comportamento.
- **D-03:** "Adicionar faixa" = ícone + texto mono inline centrado (sem button), tap abre mesma sheet com slot vazio.
- **D-04:** "Salvar tabela" = SportBtn.filledInk fixado no rodapé com borda top `1px lineHair`. SportBtn.filledInk = fundo AppTheme.ink + texto AppTheme.paper (nova variante a criar em sport_btn.dart).

### Aba Ajustes — SettingsTab (ADMN-24, ADMN-25)

- **D-05:** Seção Pix:
  - Label "PAGAMENTO" em mono 9.5px uppercase concrete
  - "PIX ATIVO" em Anton 26px
  - Descrição em UI 12.5px concrete
  - SportSwitch (AppTheme.switchTheme já configurado — laranja quando ativo)
- **D-06:** Seção Mercado Pago:
  - Label "MERCADO PAGO" mono + "✓ CONECTADO" verde (AppTheme.court) se token salvo
  - Campos Access Token e Webhook Secret como underline fields: label mono 10px uppercase + valor mascarado "••••••••" em mono + ícone olho (revelar) + ícone check (se preenchido)
  - UnderlineInputBorder (sem OutlineInputBorder)
  - "Salvar credenciais" = SportBtn.outlined (ink border + ink text)
- **D-07:** Seção Esportes: hairline rows — esporte em Manrope bold + drag handle à direita + ícone delete. Sem Card. "Adicionar esporte" = SportBtn.outlined na base da lista.
- **D-08:** Status section: grid 2 colunas (label UI 13px | valor mono 12px bold). "Modo" = AppTheme.court se PRODUÇÃO.

### SportBtn — Nova Variante (para Phase 28)

- **D-09:** Adicionar `SportBtn.filledInk(label, {onPressed})` em `lib/core/widgets/sport_btn.dart`:
  - `FilledButton` com `backgroundColor: AppTheme.ink`, `foregroundColor: AppTheme.paper`
  - Mesma tipografia/shape das outras variantes (Anton 15px, StadiumBorder, minimumSize: Size(double.infinity, 52))

### Claude's Discretion
- Padding interno das seções no settings_tab
- Espaçamento entre label e campo nos underline fields
- Altura das hairline rows de preço (mínimo para caber Anton 44px)
- Ícone de drag para reordenar esportes (Icons.drag_handle)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design Reference
- `.planning/design-reference.md` — URL do bundle + specs de todas as telas Arena admin
- Bundle: `C:/Users/alvar/.claude/projects/f---geral-Projetos-vida-ativa/design-bundle/vida-ativa/project/screens-sport/admin-pricing.jsx`
- Bundle: `C:/Users/alvar/.claude/projects/f---geral-Projetos-vida-ativa/design-bundle/vida-ativa/project/screens-sport/admin-settings.jsx`

### Requisitos
- `.planning/REQUIREMENTS.md` §ADMN-22, §ADMN-23, §ADMN-24, §ADMN-25

### Design System
- `lib/core/theme/app_theme.dart` — AppTheme completo; NÃO modificar exceto se necessário
- `.planning/research/PITFALLS.md` — pitfalls v6.0 (Anton height clip, hardcoded colors)

### Padrões de Referência (fases anteriores)
- `lib/core/widgets/sport_btn.dart` — SportBtn a estender com variante filledInk
- `lib/features/admin/ui/slot_management_tab.dart` — padrão de hairline row com Anton
- `lib/features/admin/ui/admin_booking_row.dart` — padrão de 2-row layout

### Arquivos a Modificar
- `lib/core/widgets/sport_btn.dart` — adicionar SportBtn.filledInk
- `lib/features/admin/ui/pricing_tab.dart` — redesign completo
- `lib/features/admin/ui/settings_tab.dart` — redesign completo

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sport_btn.dart` — SportBtn.filled/outlined já existem; adicionar filledInk
- `AppTheme.display(size:)` — Anton typography helper
- `AppTheme.mono(size:)` — JBM mono helper
- `AppTheme.ui(size:)` — Manrope helper
- `AppTheme.lineHair` — `#EAE3CE` para hairlines e timeline bg
- `AppTheme.line` — `#D9D2BE` para divisores maiores
- `AppTheme.concrete` — cor de texto secundário
- `PricingCubit` — lógica existente preservada (só muda UI)
- `SettingsCubit`/`SportConfigCubit` — lógica existente preservada

### Established Patterns
- Hairline row: `DecoratedBox(decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.lineHair, width: 0.5))))`
- Sem Card/sombra: usar apenas `Padding` + `DecoratedBox`
- UnderlineInputBorder já no AppTheme (campos de credencial)

### Integration Points
- `PricingCubit` → tap na faixa abre sheet existente via `showModalBottomSheet`
- `SettingsCubit` → toggle Pix e save de credenciais
- `SportConfigCubit` → lista e gestão de esportes

</code_context>

<specifics>
## Specific Ideas

- Timeline bar: `Stack` com `Positioned` para o segmento laranja, calculado como fração de 24h
- Anton 44px preço: usar `NumberFormat.currency` para formatar como "R$ 150"
- Underline field mascarado: `obscureText: true` com toggle via ícone olho

</specifics>

<deferred>
## Deferred Ideas

- Reordenação de esportes via drag-and-drop — pode ser implementado mas não é prioridade; fase futura se necessário

</deferred>

---

*Phase: 28-admin-pre-os-ajustes*
*Context gathered: 2026-06-05*
