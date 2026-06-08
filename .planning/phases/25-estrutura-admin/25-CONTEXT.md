# Phase 25: Estrutura Admin - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 25 redesenha o frame compartilhado do painel admin com identidade Arena Esportivo:
- Remover AppBar padrão → inline header custom com wordmark + eyebrow + link "cliente →"
- TabBar com identidade Arena (AppTheme já configurado — só precisa de wiring inline)
- Restyle _NotificationBanner (permissão FCM) com faixa laranja + sem fundo colorido
- Substituir SnackBar "nova reserva" por inline banner com faixa laranja + auto-dismiss 5s

Completa: ADMN-13, ADMN-14, ADMN-15

Fora de escopo: redesign das abas individuais (Slots, Reservas, Usuários, Preços, Ajustes, Dashboard) — fases 27-29.

</domain>

<decisions>
## Implementation Decisions

### Estrutura do Header (ADMN-14)
- **D-01:** Remover AppBar — usar inline header no body do Scaffold (mesmo padrão Phase 24)
- **D-02:** Estrutura: `SafeArea` wrapping o body; `Column([header, TabBar, Expanded(TabBarView)])` — TabBar fica sticky naturalmente
- **D-03:** Header layout — 2 linhas:
  - Linha 1: wordmark "VIDA ATIVA" (idêntico Phase 24 — "VIDA" em Anton ink + "ATIVA" em rect orange borderRadius:4)
  - Linha 2: "PAINEL ADMIN" em JetBrains Mono uppercase ink (eyebrow) + "cliente →" em JetBrains Mono orange à direita (link que navega para `/home`)

### TabBar (ADMN-13)
- **D-04:** TabBar posicionado abaixo do header no Column — AppTheme.tabBarTheme já configurado (JBM mono, underline orange 2px, fundo sand, unselected: concrete)
- **D-05:** Borda inferior do TabBar = `lineHair` (já no AppTheme.tabBarTheme.dividerColor: line — verificar se precisa ajuste para lineHair)
- **D-06:** TabBar permanece `isScrollable: true` (7 abas)

### Notification Banners (ADMN-15)
- **D-07:** _NotificationBanner (permissão FCM) — restylar: remover `color: primaryGreen.withValues(alpha: 0.1)`, adicionar faixa lateral laranja 2px à esquerda (Container width:2, color:orange + Row) sem fundo colorido
- **D-08:** SnackBar "nova reserva" → inline banner no Column body (acima do TabBarView):
  - Faixa lateral laranja 2px à esquerda + Row com texto + botão "Ver" (ink, navega para aba Reservas)
  - Auto-dismiss 5s via `Timer` + `setState(() => _pendingMessage = null)`
  - Estado controlado por `String? _pendingMessage` no `_AdminScreenState`
  - Remove chamada `ScaffoldMessenger.showSnackBar` — substitui por `setState(() => _pendingMessage = message)`

### Claude's Discretion
- Padding interno do header (horizontal 16-20px, vertical)
- Tamanho do Anton no wordmark (usar mesmo da Phase 24)
- Espaçamento entre linha 1 e linha 2 do header
- Cor do texto eyebrow "PAINEL ADMIN" (AppTheme.concrete ou AppTheme.ink — discretion)
- Animação de entrada do inline banner (pode ser sem animação para simplicidade)
- `Timer` vs `Future.delayed` para auto-dismiss — Claude escolhe

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requisitos
- `.planning/REQUIREMENTS.md` §ADMN-13, §ADMN-14, §ADMN-15 — requisitos exatos a satisfazer

### Design System
- `lib/core/theme/app_theme.dart` — AppTheme completo; tabBarTheme já configurado; NÃO modificar
- `.planning/research/PITFALLS.md` — pitfalls v6.0 (Anton height clip, hardcoded colors)

### Padrões de Referência (Phase 24)
- `lib/features/schedule/ui/schedule_screen.dart` — padrão de header inline sem AppBar + SafeArea
- `lib/features/booking/ui/booking_confirmation_sheet.dart` — padrão de faixa laranja lateral

### Arquivo a Modificar
- `lib/features/admin/ui/admin_screen.dart` — arquivo principal desta phase

### Arquivos a NÃO Modificar
- `lib/features/admin/ui/*.dart` (abas individuais) — fora de escopo desta phase
- `lib/core/theme/app_theme.dart` — não modificar

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AppTheme.display()` — Anton com height 0.92 (wordmark)
- `AppTheme.mono()` — JetBrains Mono (eyebrow, link "cliente →", TabBar labels)
- `AppTheme.orange`, `AppTheme.ink`, `AppTheme.concrete`, `AppTheme.lineHair`, `AppTheme.sand` — tokens relevantes
- Wordmark pattern (Phase 24): `Row([Text("VIDA", Anton ink), Container(rect orange, child: Text("ATIVA", Anton white))])`

### Established Patterns
- Header inline: `SafeArea(child: Column([headerWidget, TabBar/Strip, Expanded(content)]))`
- Faixa lateral: `IntrinsicHeight(child: Row([Container(width:2, color:orange), Expanded(content)]))`
- Tokens de cor via `AppTheme.* const` — nunca `Color(0xFF...)`
- Sem AppBar em telas v6.0 (Phase 24 estabeleceu padrão)

### Integration Points
- `TabController(length: 7)` — manter sem mudança
- `_fcmCubit.onForegroundMessage.listen(...)` — trocar `showSnackBar` por `setState(() => _pendingMessage = ...)`
- `navigateToReservasNotifier` — manter sem mudança
- `context.go('/home')` — link "cliente →" (mesmo target do TextButton atual)

### FCM State Coverage
- `AdminFcmPermissionRequired` → _NotificationBanner (restyle esta)
- `AdminFcmError` → banner de erro FCM com `Colors.red` — FORA de escopo ADMN-15 (é um erro técnico, não banner UX)

</code_context>

<specifics>
## Specific Ideas

- Wordmark Phase 24 como referência visual: `schedule_screen.dart` (linha ~15-35 aproximadamente)
- "cliente →" em mono orange: `AppTheme.mono(size: 12, color: AppTheme.orange)` + `GestureDetector` ou `TextButton` sem estilo
- Auto-dismiss banner: `Timer(const Duration(seconds: 5), () { if (mounted) setState(() => _pendingMessage = null); })`
- FCM Error banner (`Colors.red`) — manter como está, fora de escopo desta phase

</specifics>

<deferred>
## Deferred Ideas

- Animação collapse/expand do inline banner — v7+
- Dark mode para o admin panel — v7+
- FCM Error banner restyle — não é requisito ADMN-15, pode ficar para depois

</deferred>

---

*Phase: 25-estrutura-admin*
*Context gathered: 2026-05-26*
