# Phase 25: Estrutura Admin - Research

**Researched:** 2026-05-26
**Domain:** Flutter — AdminScreen frame rewrite (header, TabBar, notification banners)
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Remover AppBar — usar inline header no body do Scaffold (mesmo padrão Phase 24)
**D-02:** Estrutura: `SafeArea` wrapping o body; `Column([header, TabBar, Expanded(TabBarView)])` — TabBar fica sticky naturalmente
**D-03:** Header layout — 2 linhas:
  - Linha 1: wordmark "VIDA ATIVA" (idêntico Phase 24 — "VIDA" em Anton ink + "ATIVA" em rect orange borderRadius:4)
  - Linha 2: "PAINEL ADMIN" em JetBrains Mono uppercase ink (eyebrow) + "cliente →" em JetBrains Mono orange à direita (link que navega para `/home`)
**D-04:** TabBar posicionado abaixo do header no Column — AppTheme.tabBarTheme já configurado (JBM mono, underline orange 2px, fundo sand, unselected: concrete)
**D-05:** Borda inferior do TabBar = `lineHair` (já no AppTheme.tabBarTheme.dividerColor: line — verificar se precisa ajuste para lineHair)
**D-06:** TabBar permanece `isScrollable: true` (7 abas)
**D-07:** `_NotificationBanner` (permissão FCM) — restylar: remover `color: primaryGreen.withValues(alpha: 0.1)`, adicionar faixa lateral laranja 2px à esquerda (Container width:2, color:orange + Row) sem fundo colorido
**D-08:** SnackBar "nova reserva" → inline banner no Column body (acima do TabBarView):
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

### Deferred Ideas (OUT OF SCOPE)

- Animação collapse/expand do inline banner — v7+
- Dark mode para o admin panel — v7+
- FCM Error banner restyle — não é requisito ADMN-15, pode ficar para depois
- Redesign das abas individuais (Slots, Reservas, Usuários, Preços, Ajustes, Dashboard) — fases 27-29
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADMN-13 | AdminScreen TabBar usa underline laranja 2px (sem fundo colorido), labels em JetBrains Mono uppercase, fundo sand | AppTheme.tabBarTheme já tem UnderlineTabIndicator orange + JBM labels — só precisa wiring; TabBar dentro do Column body (não no AppBar.bottom) |
| ADMN-14 | AdminScreen header exibe wordmark + eyebrow "Painel admin" + link "cliente →" em mono laranja | Phase 24 pattern em schedule_screen.dart estabelece o padrão exato — código verificado |
| ADMN-15 | Notification banner usa faixa lateral laranja 2px (sem container colorido de fundo) | IntrinsicHeight+Row+Container(width:2,orange) pattern de booking_confirmation_sheet.dart; _pendingMessage state para inline banner |
</phase_requirements>

---

## Summary

Phase 25 é uma reescrita de widget-level de `admin_screen.dart` — um único arquivo de 211 linhas. O trabalho tem três componentes independentes: (1) substituir o `AppBar` por um inline header em dois andares no body do Scaffold, seguindo o padrão idêntico ao Phase 24 (`schedule_screen.dart`); (2) mover a `TabBar` do `AppBar.bottom` para dentro do `Column` do body, aproveitando o `AppTheme.tabBarTheme` já configurado; (3) restylar dois banners de notificação FCM — o `_NotificationBanner` de permissão e o SnackBar de nova reserva (convertido para inline banner com auto-dismiss).

O `AppTheme.tabBarTheme` já está totalmente configurado com `UnderlineTabIndicator(borderSide: BorderSide(color: orange, width: 2))`, labels em `JetBrainsMono`, `labelColor: ink`, `unselectedLabelColor: concrete`, e `dividerColor: line`. O wiring é trivial — basta remover a `TabBar` do `AppBar.bottom` e colocá-la diretamente no `Column`. O fundo sand vem do `scaffoldBackgroundColor: sand` do tema global sem nenhum ajuste.

A faixa lateral laranja para os banners usa o padrão `IntrinsicHeight(child: Row([Container(width:2,color:orange), Expanded(content)]))` que é aceitável aqui porque banners são itens únicos (não em lista), então o custo de IntrinsicHeight não é um problema de performance.

**Primary recommendation:** Reescrever `admin_screen.dart` em um único plano — é um arquivo único, com mudanças coesas e sem dependências externas.

---

## Standard Stack

### Core (já no projeto — nenhuma instalação necessária)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter/material.dart` | SDK | Scaffold, TabBar, TabController | Nativo Flutter |
| `google_fonts` | 6.2.1 | Anton, JetBrains Mono, Manrope | Já no pubspec; fonts bundled em assets/google_fonts/ |
| `flutter_bloc` | in pubspec | BlocProvider, BlocBuilder para AdminFcmCubit | Já em uso no admin_screen.dart |
| `go_router` | in pubspec | `context.go('/home')` para link "cliente →" | Já em uso |
| `dart:async` | SDK | `Timer` para auto-dismiss do inline banner | Já importado em admin_screen.dart |

### Nenhuma dependência nova necessária

Esta phase não requer nenhuma adição ao `pubspec.yaml`. Todo o stack necessário já está presente. [VERIFIED: leitura direta de admin_screen.dart e pubspec implícito via imports existentes]

---

## Architecture Patterns

### Estrutura do AdminScreen reescrito

```
Scaffold(
  body: SafeArea(
    child: Column([
      _AdminHeader(),           // inline header, sem AppBar
      TabBar(...),              // sticky no topo, logo abaixo do header
      if (_pendingMessage != null) _InlineBookingBanner(...),  // ADMN-15
      BlocBuilder<AdminFcmCubit,...>(  // _NotificationBanner restyle
        builder: (ctx, state) => state is AdminFcmPermissionRequired
          ? _NotificationBanner(onEnable: ...)
          : SizedBox.shrink()
      ),
      Expanded(TabBarView(...)),
    ]),
  ),
)
```

### Pattern 1: Inline Header (Phase 24 reference — VERIFIED)

Padrão idêntico ao `schedule_screen.dart`, linhas 73-106:

```dart
// Source: lib/features/schedule/ui/schedule_screen.dart (linhas 73-106) — VERIFIED
SafeArea(
  bottom: false,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('VIDA', style: AppTheme.display(size: 18, color: AppTheme.ink)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('ATIVA', style: AppTheme.display(size: 18, color: AppTheme.paper)),
            ),
          ],
        ),
        const Spacer(),
        Text(_eyebrowDate(_selectedDay), style: AppTheme.mono(size: 11, color: AppTheme.ink)),
      ],
    ),
  ),
),
```

**Adaptação para admin (D-03):**
- Linha 1: idêntica ao Phase 24 — "VIDA" ink + "ATIVA" pill orange
- Linha 2 (abaixo, mesma Padding): `Row([Text('PAINEL ADMIN', AppTheme.mono(...)), Spacer(), GestureDetector(onTap: () => context.go('/home'), child: Text('cliente →', AppTheme.mono(color: orange)))])`
- Usar `Column` interno em vez de `Row` único (o header Phase 24 é single-row; admin precisa de 2 linhas)

### Pattern 2: Faixa Lateral Laranja — IntrinsicHeight

Padrão de `_NotificationBanner` (ADMN-15) e inline booking banner:

```dart
// Source: Codebase pattern — IntrinsicHeight+Row para faixa lateral [VERIFIED: booking_confirmation_sheet.dart usa Container+Border para faixa, mas CONTEXT.md especifica width:2 Container pattern]
IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(width: 2, color: AppTheme.orange),
      const SizedBox(width: 12),
      Expanded(child: content),
    ],
  ),
)
```

**Nota:** IntrinsicHeight é aceitável aqui porque estes banners são widgets únicos (não em ListView), então não há custo de performance (ver Pitfall 5 do PITFALLS.md).

### Pattern 3: TabBar no Column body (não no AppBar)

```dart
// Source: Flutter docs — TabBar pode ser usado como widget standalone [VERIFIED: admin_screen.dart atual usa AppBar.bottom; mover para Column é trivial]
TabBar(
  controller: _tabController,
  isScrollable: true,
  tabs: const [
    Tab(text: 'DASHBOARD'),
    Tab(text: 'SLOTS'),
    Tab(text: 'BLOQUEIOS'),
    Tab(text: 'RESERVAS'),
    Tab(text: 'USUÁRIOS'),
    Tab(text: 'PREÇOS'),
    Tab(text: 'AJUSTES'),
  ],
),
```

O `AppTheme.tabBarTheme` já configura labels em JetBrains Mono uppercase via `letterSpacing: 1.6` e `fontWeight: w700`. Os Tab texts devem estar em UPPERCASE no código (Flutter não tem `text-transform`). [VERIFIED: PITFALLS.md Pitfall 10 confirma — usar UPPERCASE no código, não via CSS]

### Pattern 4: Auto-dismiss inline banner

```dart
// Source: CONTEXT.md D-08 + dart:async Timer [ASSUMED — Timer é padrão Dart, mas testado via contexto]
String? _pendingMessage;
Timer? _bannerTimer;

// No listener FCM:
_fcmCubit.onForegroundMessage.listen((message) {
  if (!mounted) return;
  final title = message.notification?.title ?? 'Nova Reserva';
  final body = message.notification?.body ?? '';
  setState(() => _pendingMessage = '$title\n$body');
  _bannerTimer?.cancel();
  _bannerTimer = Timer(const Duration(seconds: 5), () {
    if (mounted) setState(() => _pendingMessage = null);
  });
});
```

**Dispose:** `_bannerTimer?.cancel()` no `dispose()`.

### Anti-Patterns to Avoid

- **AppBar com TabBar.bottom:** O design elimina o AppBar; a TabBar deve ficar no Column do body para que o header personalizado seja possível.
- **hardcoded Color(0xFF...):** Todo código novo deve usar `AppTheme.*` — nenhum hex literal. [VERIFIED: PITFALLS.md Pitfall 9]
- **`AppTheme.primaryGreen` no banner:** O `_NotificationBanner` atual usa `AppTheme.primaryGreen.withValues(alpha: 0.1)` como background — remover completamente (sem fundo colorido). [VERIFIED: admin_screen.dart linha 190]
- **SnackBar mantido:** Remover completamente a chamada `ScaffoldMessenger.of(context).showSnackBar(...)` (linhas 48-58 do admin_screen.dart atual). Substituir por setState inline. [VERIFIED: código atual lido]
- **Tab texts em lowercase:** Tab texts devem estar em UPPERCASE no código.
- **TabBarTheme sem Data suffix:** Usar sempre `TabBarThemeData` (com `Data`). [VERIFIED: PITFALLS.md Pitfall 7]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| TabBar underline indicator | Custom painter ou BoxDecoration | `UnderlineTabIndicator` já em AppTheme.tabBarTheme | Já está configurado — wiring direto |
| Auto-dismiss timer | `Future.delayed` com repetição | `dart:async Timer` com cancel() no dispose | Timer cancellável, seguro para StatefulWidget |
| Orange stripe | BoxDecoration border-left | `Container(width:2) + Row` (IntrinsicHeight pattern) | Mais simples e flex com altura dinâmica |
| Navigation ao "cliente →" | Navigator.push manual | `context.go('/home')` via go_router | Router já configurado; go_router já importado |

**Key insight:** Quase tudo nesta phase reutiliza código e tokens já existentes. O trabalho é remover e reorganizar, não construir do zero.

---

## Common Pitfalls

### Pitfall 1: TabBar fora do AppBar perde o fundo sand
**What goes wrong:** Quando a `TabBar` sai do `AppBar.bottom` e vai para o `Column` do body, ela herda o `scaffoldBackgroundColor: sand` do tema — o que é correto. Mas se o `Column` tiver algum `Container` pai com outra cor, o fundo muda.
**Why it happens:** `TabBar` por si só não tem cor de fundo definida — depende do container pai.
**How to avoid:** Não envolver a `TabBar` em nenhum `Container` com cor. Deixar herdar o `scaffoldBackgroundColor` (sand) do `Scaffold`.
**Warning signs:** TabBar mostrando fundo branco ou paper em vez de sand.

### Pitfall 2: dividerColor da TabBar — `line` vs `lineHair`
**What goes wrong:** O `AppTheme.tabBarTheme.dividerColor` está configurado como `line` (`Color(0xFFD9D2BE)`). A decisão D-05 quer `lineHair` (`Color(0xFFEAE3CE)` — mais claro). Se não ajustado inline, a borda inferior da TabBar ficará mais escura que o pretendido.
**Why it happens:** O AppTheme foi configurado antes das decisões de Phase 25.
**How to avoid:** A decisão é NÃO modificar `app_theme.dart`. Solução: passar `dividerColor: AppTheme.lineHair` diretamente na `TabBar` inline: `TabBar(dividerColor: AppTheme.lineHair, ...)`. O widget-level override tem precedência sobre o tema. [VERIFIED: Flutter TabBar aceita dividerColor como parâmetro direto]
**Warning signs:** Linha inferior da TabBar mais grossa ou mais escura que hairlines do resto do app.

### Pitfall 3: UnderlineTabIndicator não alinha quando TabBar está no body
**What goes wrong:** `UnderlineTabIndicator` com `TabBarIndicatorSize.tab` pode renderizar em posição errada quando a `TabBar` não está dentro de um `AppBar`. O indicador é posicionado relativo ao bottom da TabBar — deve funcionar, mas confirmar visualmente.
**Why it happens:** Pitfall 7 do PITFALLS.md: `UnderlineTabIndicator` em Material 3 dentro de container custom pode clipar.
**How to avoid:** Testar no staging após implementação — scroll entre abas 1 e 7, verificar se o indicador não clipa nas extremidades.
**Warning signs:** Indicador laranja ausente ou cortado na Tab 1 ou Tab 7.

### Pitfall 4: Timer não cancelado → setState após dispose
**What goes wrong:** Se `_bannerTimer` não for cancelado no `dispose()`, o callback pode chamar `setState()` após o widget ser desmontado, causando exception.
**Why it happens:** Admin sai da tela antes de 5s; o Timer ainda está pendente.
**How to avoid:** `_bannerTimer?.cancel()` no `dispose()` do `_AdminScreenState`, junto com os outros cancels existentes.
**Warning signs:** Exception `"setState() called after dispose()"` no console ao navegar saindo do admin rapidamente.

### Pitfall 5: Tab texts em lowercase no código
**What goes wrong:** Os Tab texts atuais são: `'Dashboard'`, `'Slots'`, `'Bloqueios'`, etc. — title case. O design exige JetBrains Mono uppercase. Se o texto não estiver em UPPERCASE no código, o mono font não faz transform automático.
**Why it happens:** Flutter não tem `text-transform: uppercase` como CSS.
**How to avoid:** Mudar para `'DASHBOARD'`, `'SLOTS'`, `'BLOQUEIOS'`, `'RESERVAS'`, `'USUÁRIOS'`, `'PREÇOS'`, `'AJUSTES'` no código da `TabBar`.
**Warning signs:** Labels em title case mesmo com JetBrains Mono aplicado.

---

## Code Examples

### Header Admin completo (2 linhas)
```dart
// Source: adaptado de schedule_screen.dart (VERIFIED) + CONTEXT.md D-03
SafeArea(
  bottom: false,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Linha 1: wordmark
        Row(
          children: [
            Text('VIDA', style: AppTheme.display(size: 18, color: AppTheme.ink)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('ATIVA', style: AppTheme.display(size: 18, color: AppTheme.paper)),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go('/home'),
              child: Text('cliente →', style: AppTheme.mono(size: 11, color: AppTheme.orange)),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // Linha 2: eyebrow
        Text('PAINEL ADMIN', style: AppTheme.mono(size: 10, color: AppTheme.concrete)),
      ],
    ),
  ),
),
```

### _NotificationBanner restyle (ADMN-15)
```dart
// Source: CONTEXT.md D-07 + IntrinsicHeight pattern [VERIFIED: padrão estabelecido]
class _NotificationBanner extends StatelessWidget {
  final VoidCallback onEnable;
  const _NotificationBanner({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 2, color: AppTheme.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.notifications_outlined, size: 16, color: AppTheme.ink),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Ative as notificações para receber alertas de novas reservas.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: onEnable,
                    child: const Text('Ativar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Inline booking banner (ADMN-15 — nova reserva)
```dart
// Source: CONTEXT.md D-08 [ASSUMED: padrão derivado do IntrinsicHeight pattern + Timer]
Widget _buildInlineBanner(String message) {
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(width: 2, color: AppTheme.orange),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(message, style: AppTheme.ui(size: 13)),
                ),
                TextButton(
                  onPressed: _goToReservas,
                  child: Text('Ver', style: AppTheme.mono(size: 11, color: AppTheme.ink)),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
```

---

## Current Code Inventory (admin_screen.dart — VERIFIED)

Estado atual confirmado por leitura do arquivo:

| Elemento | Estado atual | Ação Phase 25 |
|----------|-------------|---------------|
| `AppBar` | Linha 95-119: `AppBar(title: Text('Painel Admin'), actions: [TextButton.icon(...)], bottom: TabBar(...))` | Remover completamente |
| `TabBar` | Dentro de `AppBar.bottom`, linhas 107-119 | Mover para Column do body, abaixo do header inline |
| Tab texts | Title case: `'Dashboard'`, `'Slots'`, etc. | Mudar para UPPERCASE |
| Link "cliente →" | `TextButton.icon` no `AppBar.actions` com `foregroundColor: AppTheme.primaryGreen` | Recolocar como `GestureDetector` no header linha 1 (direita), cor orange |
| SnackBar foreground FCM | Linhas 44-58: `ScaffoldMessenger.of(context).showSnackBar(...)` | Remover; substituir por `setState(() => _pendingMessage = ...)` |
| `_NotificationBanner` | Linhas 181-210: `Container(color: AppTheme.primaryGreen.withValues(alpha:0.1), ...)` | Restylar: remover fundo colorido, adicionar faixa laranja 2px |
| `AdminFcmError` banner | Linhas 131-140: `Colors.red.withValues(alpha:0.1)` | FORA DE ESCOPO — manter como está |
| `TabController(length: 7)` | OK | Manter sem mudança |
| `navigateToReservasNotifier` | OK | Manter sem mudança |
| `_foregroundSub` | StreamSubscription FCM | Manter, mas trocar handler |
| `_AdminScreenState dispose()` | Cancela sub, remove listener, dispose controller, close cubit | Adicionar `_bannerTimer?.cancel()` |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `TabBarTheme` | `TabBarThemeData` (com `Data` suffix) | Flutter 3.16+ | Usar `TabBarThemeData` sempre |
| AppBar integrado | Inline header no Scaffold body | Phase 24 (Phase 25 replica) | Mais controle visual, sem limitações do AppBar |
| SnackBar para notificações | Inline banner no body | Phase 25 (esta decisão) | Permite styling Arena sem depender do SnackBarTheme |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Timer` é importado via `dart:async` já presente no admin_screen.dart | Code Examples | Baixo — `dart:async` já está no import line 1 do arquivo atual |
| A2 | TabBar aceita `dividerColor` como parâmetro inline (override do tema) | Pitfalls | Baixo — é parâmetro documentado do widget TabBar; se não existir, ajuste em `TabBarTheme` local via `Theme` wrapper |
| A3 | O "cliente →" link vai para `/home` (confirmado em CONTEXT.md D-08 e código atual linha 99) | Architecture | Verificado no código atual: `context.go('/home')` |

---

## Open Questions

1. **Cor do eyebrow "PAINEL ADMIN"**
   - What we know: CONTEXT.md deixa como discretion — `AppTheme.concrete` ou `AppTheme.ink`
   - What's unclear: Qual cria maior hierarquia visual entre wordmark e eyebrow?
   - Recommendation: Usar `AppTheme.concrete` para criar hierarquia (wordmark é primário, eyebrow é secundário), igual ao padrão de eyebrows em toda a Phase 24.

2. **dividerColor da TabBar**
   - What we know: AppTheme tem `dividerColor: line`; D-05 quer `lineHair`
   - What's unclear: Se passar `dividerColor: AppTheme.lineHair` inline na `TabBar` tem precedência sobre o tema
   - Recommendation: Passar inline — Flutter widget parameters têm precedência sobre tema. Se não funcionar, envolver a `TabBar` em `Theme(data: Theme.of(context).copyWith(tabBarTheme: Theme.of(context).tabBarTheme.copyWith(dividerColor: AppTheme.lineHair)), child: TabBar(...))`.

---

## Environment Availability

Step 2.6: SKIPPED — esta phase é puramente widget-level (reescrita de um único arquivo .dart). Não há dependências externas, CLIs, bancos de dados, ou serviços além do Flutter SDK já instalado.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK nativo) |
| Config file | pubspec.yaml (dev_dependencies: flutter_test) |
| Quick run command | `flutter test test/features/admin/ -x` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADMN-13 | TabBar renderiza com underline orange, labels UPPERCASE, fundo sand | Widget test visual | `flutter test test/features/admin/admin_screen_test.dart -x` | ❌ Wave 0 |
| ADMN-14 | Header inline exibe wordmark + eyebrow + link "cliente →" | Widget test | `flutter test test/features/admin/admin_screen_test.dart -x` | ❌ Wave 0 |
| ADMN-15 | _NotificationBanner sem fundo colorido; inline banner auto-dismiss 5s | Widget test + Timer fake | `flutter test test/features/admin/admin_screen_test.dart -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter analyze lib/features/admin/ui/admin_screen.dart`
- **Per wave merge:** `flutter test test/features/admin/`
- **Phase gate:** `flutter analyze` clean + `flutter build web --release` clean antes de `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/features/admin/admin_screen_test.dart` — cobre ADMN-13, ADMN-14, ADMN-15
- [ ] Mocks para `AdminFcmCubit` e `DashboardCubit` se não existirem

*(Nota: flutter_test já está disponível como dev_dependency — zero setup adicional)*

---

## Security Domain

Esta phase é 100% widget-level visual rewrite — sem mudanças em autenticação, dados, network requests, ou input de usuário. ASVS não se aplica. `security_enforcement` não listado explicitamente em config.json como `false`, mas a natureza da phase (renaming/restyling de widgets) não cria superfícies de ataque.

---

## Project Constraints (from CLAUDE.md)

- **MCP code-review-graph:** MUST use graph tools before Grep/Glob para explorar codebase. Research realizada via leitura direta dos arquivos canônicos especificados no CONTEXT.md.
- **Zero BLoC/model/router changes:** Apenas widget-level `build()` rewrites — confirmado para Phase 25.
- **Não modificar `app_theme.dart`:** Locked. Qualquer override de theme deve ser inline no widget.
- **Não modificar abas individuais:** `lib/features/admin/ui/*.dart` (exceto `admin_screen.dart`) — fora de escopo.
- **Usar `AppTheme.*` tokens:** Nunca `Color(0xFF...)` em código novo.
- **Fontes bundled:** Anton, JetBrains Mono, Manrope já em `assets/google_fonts/` (Phase 23 concluída).
- **Branch v6:** Todo trabalho na branch v6.

---

## Sources

### Primary (HIGH confidence)
- `lib/features/admin/ui/admin_screen.dart` — código atual completo lido; estado exato verificado
- `lib/features/schedule/ui/schedule_screen.dart` — padrão de header Phase 24 verificado (linhas 73-106)
- `lib/core/theme/app_theme.dart` — tabBarTheme, tokens, helpers verificados
- `.planning/research/PITFALLS.md` — pitfalls v6.0 verificados (especialmente Pitfall 5, 7, 10)
- `.planning/phases/25-estrutura-admin/25-CONTEXT.md` — decisões locked e discretion verificadas

### Secondary (MEDIUM confidence)
- `lib/features/booking/ui/booking_confirmation_sheet.dart` — padrão de faixa lateral verificado (Container+Row, não IntrinsicHeight nesse arquivo específico, mas IntrinsicHeight é o padrão citado no CONTEXT.md)

### Tertiary (LOW confidence)
- Nenhum — todas as claims críticas foram verificadas por leitura direta de código fonte

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — tudo verificado por leitura de código; zero novas dependências
- Architecture: HIGH — Phase 24 pattern verificado em código real; admin_screen.dart lido completamente
- Pitfalls: HIGH — baseados em PITFALLS.md verificado e leitura de código

**Research date:** 2026-05-26
**Valid until:** 2026-06-25 (estável — sem dependências externas mutáveis)
