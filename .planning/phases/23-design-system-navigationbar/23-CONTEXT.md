# Phase 23: Design System + NavigationBar - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 23 verifica e fecha o design system foundation para v6.0 Arena Esportivo:
- AppTheme.lightTheme já construído — verificar completude e compilação
- Bundle 5 arquivos de fonte em assets/google_fonts/ para funcionamento offline
- Corrigir Color(0xFF...) hardcoded nos 3 arquivos identificados no pitfall log
- Corrigir token de borda no NavigationBar (line → lineHair)
- Fechar Phase 23 = flutter build web limpo + flutter analyze zero warnings

Fora de escopo: redesign de telas individuais (Phases 24–29), mudanças em BLoC/models/router.

</domain>

<decisions>
## Implementation Decisions

### Font Bundling
- **D-01:** Bundle os 5 arquivos de fonte como assets locais em `assets/google_fonts/`:
  - Anton — peso 400 (único disponível)
  - Manrope — pesos 400, 600, 700
  - JetBrains Mono — peso 700
  - Adicionar seção `fonts:` no pubspec.yaml e `assets/google_fonts/` para que google_fonts use arquivos locais offline
  - Estratégia: google_fonts procura automaticamente em `assets/google_fonts/` se a família/peso existe lá — zero mudança de código

### Hardcoded Color Audit
- **D-02:** Auditar e substituir todas as ocorrências de `Color(0xFF...)` inline por tokens `AppTheme.*` nos seguintes arquivos:
  - `lib/features/booking/ui/booking_card.dart` (6+ ocorrências)
  - `lib/features/admin/ui/admin_booking_card.dart` (`_sportBgColors`/`_sportFgColors` maps)
  - `lib/features/booking/ui/booking_confirmation_sheet.dart`
  - Auditoria via grep antes de editar cada arquivo

### Completion Criteria
- **D-03:** Phase 23 está done quando:
  - `flutter build web` completa sem erros de compilação
  - `flutter analyze` retorna zero issues (ou apenas hints, não warnings/errors)
  - Verificação visual em staging NÃO é requisito para fechar esta fase

### Claude's Discretion
- Corrigir `AppTheme.line` → `AppTheme.lineHair` no `app_shell.dart` (borda top do NavigationBar) — requisito NAV-02 especifica "borda superior hairline"
- Ordem de execução das tarefas (buscar fontes → pubspec → audit de cores → build verify)
- Filenames exatos dos .ttf: confirmar no flutter pub cache antes de commitar

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design System Foundation
- `.planning/REQUIREMENTS.md` §DS-01..DS-04, §NAV-01..NAV-02 — requisitos a satisfazer
- `.planning/research/FEATURES.md` — feature landscape, tabela de status (done vs not done)
- `.planning/research/PITFALLS.md` — 11 pitfalls identificados; Font FOUT, Anton height clip, hardcoded colors

### Codebase Estado Atual
- `lib/core/theme/app_theme.dart` — AppTheme já construído (224 linhas); NÃO reconstruir
- `lib/app_shell.dart` — NavigationBar já atualizado; só corrigir borda line→lineHair
- `pubspec.yaml` — verificar seção `fonts:` e `assets:` antes de adicionar

### Font Bundling
- `.planning/STATE.md` §Decisions — decisão de bundlar Anton/Manrope/JBM documentada aqui

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AppTheme.display()` / `AppTheme.ui()` / `AppTheme.mono()` — helpers prontos, não modificar
- `AppTheme.lightTheme` — ThemeData completo com NavigationBarThemeData, TabBarThemeData, CardThemeData, etc.

### Established Patterns
- NavigationBar configurado via `NavigationBarThemeData` no theme — não passar propriedades inline no widget
- `Container` wrapping `NavigationBar` com `BoxDecoration` para borda top (padrão de app_shell.dart)
- Todos os tokens de cor via `AppTheme.* const` — nunca `Color(0xFF...)`

### Integration Points
- `lib/main.dart` usa `AppTheme.lightTheme` — nenhuma mudança necessária aqui
- `pubspec.yaml` precisa de nova seção `fonts:` + `assets/google_fonts/` listado em `assets:`
- google_fonts 6.2.1 detecta automático arquivos em `assets/google_fonts/` pelo nome canônico

</code_context>

<specifics>
## Specific Ideas

- Filenames canônicos google_fonts para as fontes: verificar em `~/.pub-cache/hosted/pub.dev/google_fonts-*/lib/src/google_fonts_parts/` — o arquivo lista os nomes exatos dos .ttf
- Anton pitfall: `height: 0.92` já setado nos helpers — não mudar

</specifics>

<deferred>
## Deferred Ideas

- Verificação visual em staging — diferida para após Phase 24+ quando há telas para ver
- Dark mode — v7+ conforme REQUIREMENTS.md
- Bundling de outros pesos de fonte (ex: Manrope 500, 800) — apenas 400/600/700 necessários agora

</deferred>

---

*Phase: 23-design-system-navigationbar*
*Context gathered: 2026-05-25*
