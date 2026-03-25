---
phase: 9
slug: gestao-de-usuarios-admin
created: 2026-03-25
status: ready
---

# Phase 9: Gestão de Usuários Admin - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Admin pode alternar entre visão admin e visão cliente sem logout (ADMN-07) e pode buscar e promover usuários cadastrados a administrador no painel (ADMN-08). Rebaixar admin não está no escopo desta fase.

</domain>

<decisions>
## Implementation Decisions

### Toggle Modo Cliente (ADMN-07)

- **Implementação ephemeral** — ViewMode enum no cubit state (`ViewMode.admin` / `ViewMode.client`). Nenhum write no Firestore; `UserModel.role` permanece "admin" no banco durante o modo cliente.
- **Ao ativar modo cliente:** app navega para `/home` automaticamente.
- **Em modo cliente, aba Admin some do BottomNav** — admin enxerga exatamente o que um cliente vê (sem aba admin, sem botão "Painel Admin" no perfil). Fiel ao SC #2.
- **Toggle de retorno:** apenas na ProfileScreen. Em modo cliente, a ProfileScreen mostra toggle "Voltar à visão admin" onde normalmente ficaria o botão "Painel Admin". Sem banner no topo.
- **Guard do router:** verificar `viewMode == ViewMode.admin` (e `user.isAdmin`) para permitir acesso a `/admin`. Em modo cliente, redirect para `/access-denied` ou `/home` se tentar acessar `/admin`.

### Tela de Usuários / Promoção (ADMN-08)

- **4ª aba "Usuários" no AdminScreen** — consistente com as 3 abas existentes (Slots, Bloqueios, Reservas).
- **Busca por nome ou email** — TextField no topo da aba; filtra a lista em tempo real (client-side sobre resultado Firestore, ou query Firestore com `startAt`/`endAt` por displayName).
- **Card do usuário:** displayName + email + chip/badge "Admin" se `role == "admin"`. Botão "Promover" visível para todos, mas desabilitado (ou oculto) para quem já é admin.

### Confirmação de Promoção

- **Dialog de confirmação** antes de executar: `"Promover [Nome] a administrador? Esta ação não pode ser desfeita pelo app."` com botões Confirmar / Cancelar.
- **Após confirmação:** escreve `role: "admin"` em `/users/{uid}` no Firestore. SnackBar de sucesso: `"[Nome] agora é administrador"`.
- **Sessão do promovido:** nenhuma ação — na próxima abertura do app (ou quando `authStateChanges` re-emitir), o usuário passará a ter acesso admin automaticamente.

### Claude's Discretion

- Design do chip/badge "Admin" no card de usuário
- Debounce do campo de busca (se query Firestore) vs filtragem client-side
- Estado vazio da aba Usuários quando nenhum resultado de busca

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

No external specs — requirements are fully captured in decisions above.

### Roadmap & Requirements
- `.planning/ROADMAP.md` §Phase 9 — Success Criteria 1, 2, 3 (toggle, modo cliente, promoção)
- `.planning/REQUIREMENTS.md` §ADMN-07, ADMN-08 — Acceptance criteria completos

### Codebase Reference
- `lib/features/auth/cubit/auth_cubit.dart` — AuthCubit e AuthState; ViewMode enum será adicionado aqui ou em auth_state.dart
- `lib/features/auth/ui/profile_screen.dart` — Localização do toggle (substituir botão "Painel Admin" condicionalmente)
- `lib/core/router/app_router.dart` — Guard `/admin` deve checar viewMode além de isAdmin
- `lib/features/admin/ui/admin_screen.dart` — DefaultTabController (length: 3 → 4); nova aba "Usuários"
- `lib/core/models/user_model.dart` — `role` field, `isAdmin` getter

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ProfileScreen`: já tem `if (user.isAdmin)` condicional — toggle substitui/complementa o botão "Painel Admin"
- `AdminScreen`: `DefaultTabController(length: 3)` — incrementar para 4, adicionar `Tab(text: 'Usuários')` e `UsersManagementTab()`
- `AuthCubit.updatePhone()`: padrão de update Firestore + re-emit state — replicar para `promoteUser(String uid)`
- `AppTheme.primaryGreen`: cor do FilledButton já usada em outras telas — manter consistência

### Established Patterns
- **Cubit state via AuthAuthenticated**: toda lógica de "quem está logado" passa pelo AuthCubit; ViewMode vai no mesmo cubit
- **FieldValue pattern**: mutations Firestore via update parcial (não set completo)
- **`context.read<AuthCubit>()`** capturado antes de `showModalBottomSheet`/`showDialog` — aplicar no dialog de confirmação de promoção
- **SnackBar de sucesso**: `ScaffoldMessenger.of(context).showSnackBar(...)` — padrão de toda a app

### Integration Points
- `AuthState` / `AuthAuthenticated`: ViewMode pode ser campo adicional em `AuthAuthenticated` ou estado separado no AuthCubit
- Router `redirect`: condição em `/admin` guard precisa verificar ViewMode além de `user.isAdmin`
- `BottomNavigationBar` (em `app_shell.dart`): aba admin visível condicionalmente por `user.isAdmin && viewMode == admin`

</code_context>

<specifics>
## Specific Ideas

- Toggle "Visão Cliente / Visão Admin" na ProfileScreen — label muda conforme o modo atual
- Em modo cliente, a ProfileScreen mostra o toggle de retorno no lugar do botão "Painel Admin" — fluxo simétrico
- Dialog de promoção com nome do usuário no texto: `"Promover João Silva a administrador?"`

</specifics>

<deferred>
## Deferred Ideas

- Rebaixar admin para cliente — não está no escopo desta fase
- Histórico de promoções (audit log) — complexidade desnecessária para v2
- Transferência de ownership / proteção de último admin — futuro

</deferred>

---

*Phase: 09-gestao-de-usuarios-admin*
*Context gathered: 2026-03-25*
