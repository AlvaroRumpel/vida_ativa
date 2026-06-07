# Phase 30: Validação Visual Arena — Context

**Gathered:** 2026-06-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 30 valida que a identidade Arena Esportivo está corretamente implementada em todas as telas ativas do app. A validação é feita em duas frentes:

1. **Automatizada (Claude):** Audit de código + conformidade visual + build + testes
2. **Manual (usuário):** Screenshot comparison contra design bundle Arena

**Telas cobertas (por tela, não por fase):**
- Agenda do cliente (day selector, slot rows hairline, wordmark)
- Booking flow (confirmação Anton 88px, Pix QR screen, Minhas Reservas hero 72px + hairline rows)
- Painel Admin — frame (AppBar wordmark, TabBar underline, notification banner)
- Admin tabs operacionais: Slots, Reservas, Usuários (hairline rows, UserDetailSheet)
- Admin tabs config: Preços (Anton 44px timeline), Ajustes (Switch sport, underline fields MP)

**Fora de escopo:**
- Admin Dashboard — iterado e validado ao vivo durante sessão 2026-06-07
- Phase 24 (Agenda Cliente) — ainda não implementada; excluída da validação

**Output da fase:**
- `VALIDATION.md` — relatório de issues encontrados pelo audit automático
- Código corrigido (fixes aplicados inline)
- Checklist manual de screenshot comparison para o usuário

</domain>

<decisions>
## Implementation Decisions

### Audit Automatizado — Escopo

- **D-01:** Grep por tokens incorretos: buscar `Color(0x`, `Colors.`, `#[0-9A-Fa-f]{6}`, `TextStyle(` hardcoded em todos os arquivos de UI das telas cobertas.
- **D-02:** Confirmar uso de `AppTheme.display()`, `AppTheme.ui()`, `AppTheme.mono()` para tipografia; `AppTheme.orange`, `AppTheme.ink`, `AppTheme.concrete`, `AppTheme.court`, `AppTheme.lineHair` para cores.
- **D-03:** Conformidade visual por arquivo: Claude lê cada arquivo de tela e verifica ponto a ponto contra as decisões do CONTEXT.md da fase que o implementou (ex: `27-CONTEXT.md` para Slots/Reservas/Usuários).
- **D-04:** `flutter analyze` deve retornar 0 errors. Warnings info-level (style) são tolerados.
- **D-05:** `flutter build web --release` deve completar sem erros.
- **D-06:** Verificar que widgets implementados nas fases 26-29 possuem pelo menos widget tests básicos (não golden tests — apenas cobertura existente).

### Checklist Manual — Screenshot Comparison

- **D-07:** Referência visual: design bundle Arena Esportivo em `C:/Users/alvar/.claude/projects/f---geral-Projetos-vida-ativa/design-bundle/vida-ativa/` (JSX/HTML files).
- **D-08:** Claude gera descrição visual esperada por tela baseada no design bundle, com marcadores específicos (ex: "Anton 88px visível como elemento hero, sem Card elevado, faixa laranja 2px esquerda no banner de aprovação manual").
- **D-09:** Formato do checklist: Markdown com `- [ ]` por item visual. Usuário abre app no staging, faz screenshot de cada tela, confirma visualmente.
- **D-10:** Checklist organizado por tela (mesma ordem das telas listadas no Phase Boundary).

### Quando Bug é Encontrado

- **D-11:** Claude documenta o issue em `VALIDATION.md` E aplica o fix no mesmo plan de execução.
- **D-12:** Severidade: `CRITICAL` (cor errada, fonte errada, layout quebrado) = fix obrigatório. `MINOR` (espaçamento ~2px fora) = documentado, fix opcional.
- **D-13:** `VALIDATION.md` estrutura: issue ID, tela, severidade, descrição, arquivo + linha, fix aplicado (ou "pendente manual").

### Claude's Discretion
- Ordem de execução do audit (qual tela primeiro)
- Nível de detalhe das descrições visuais no checklist manual
- Agrupamento de fixes em commits (pode ser por tela ou por tipo de issue)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design System
- `.planning/design-reference.md` — tokens Arena Esportivo (cores, tipografia), caminho do design bundle
- `lib/core/theme/app_theme.dart` — AppTheme tokens implementados (fonte of truth para código)

### Fases que implementaram as telas
- `.planning/phases/26-fluxo-de-reserva-cliente/26-CONTEXT.md` — Booking flow decisions (Anton 88px, HairlineBookingRow, SportBtn)
- `.planning/phases/27-admin-slots-reservas-usu-rios/27-CONTEXT.md` — Admin Slots/Reservas/Usuários hairline rows
- `.planning/phases/28-admin-pre-os-ajustes/28-CONTEXT.md` — Preços (Anton 44px) e Ajustes (Switch sport, underline fields)
- `.planning/phases/29-admin-dashboard/29-CONTEXT.md` — Dashboard (KPI, heatmap, donut) — para referência, não revalidar

### Design Bundle (referência visual)
- `C:/Users/alvar/.claude/projects/f---geral-Projetos-vida-ativa/design-bundle/vida-ativa/project/screens-sport/admin-slots.jsx`
- `C:/Users/alvar/.claude/projects/f---geral-Projetos-vida-ativa/design-bundle/vida-ativa/project/screens-sport/admin-bookings.jsx`
- `C:/Users/alvar/.claude/projects/f---geral-Projetos-vida-ativa/design-bundle/vida-ativa/project/screens-sport/admin-users.jsx`
- `C:/Users/alvar/.claude/projects/f---geral-Projetos-vida-ativa/design-bundle/vida-ativa/project/arena-sport.jsx` — tokens

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/core/theme/app_theme.dart` — todos os tokens Arena; qualquer divergência aqui é raiz do problema
- `lib/features/admin/ui/dashboard_tab.dart` — referência de implementação correta (validada ao vivo 2026-06-07)

### Established Patterns
- Hairline rows: `Container(height: 0.5, color: AppTheme.lineHair)` como divisor
- Tipografia: sempre via `AppTheme.display()`, `AppTheme.ui()`, `AppTheme.mono()`
- Faixa laranja: `Container(width: 3, color: AppTheme.orange)` lateral esquerda
- SportBtn: widget reutilizável em `lib/features/admin/ui/sport_btn.dart`

### Integration Points
- Audit começa por `lib/features/` — subpastas `admin/ui/`, `booking/ui/`, `schedule/ui/`
- `VALIDATION.md` vai em `.planning/phases/30-*/`

</code_context>

<specifics>
## Specific Ideas

- O checklist manual deve descrever o visual com precisão suficiente para comparação com screenshot (ex: "valor em Anton 32px, delta '↑ 8.2%' em verde JBM mono 10px abaixo, sparkline 64×36px à direita do número")
- Design bundle JSX usa `SPORT.*` tokens — mapear para `AppTheme.*` equivalentes ao comparar

</specifics>

<deferred>
## Deferred Ideas

- Golden tests (screenshot-based regression testing automatizado) — seria Phase 31+ se necessário
- Admin Dashboard revalidação formal — feita ao vivo na sessão 2026-06-07, considerada válida

</deferred>

---

*Phase: 30-valida-o-visual-arena-uat-automatizado-checklist-manual*
*Context gathered: 2026-06-07*
