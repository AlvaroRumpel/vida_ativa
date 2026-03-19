# Phase 2: Auth - Context

**Gathered:** 2026-03-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Implementar autenticação completa: Google Sign-In, email/senha (login + cadastro + recuperação de senha), persistência de sessão entre sessões do browser, guards de rota por role (client vs admin), e tela de perfil funcional.

</domain>

<decisions>
## Implementation Decisions

### Tela de Login (/login)

- Layout único com Google + email/senha na mesma tela — botão Google no topo, separador "ou", campos email e senha abaixo
- Identidade visual: nome "Vida Ativa" em fonte grande + subtítulo "Reserve sua quadra" — sem dependência de arquivo de imagem
- Link "Esqueci minha senha" aparece abaixo do campo de senha (sempre visível, não só após erro)
- Erros de login (senha errada, email não cadastrado): mensagem inline vermelha abaixo do campo com problema — sem modal ou SnackBar
- Link "Não tem conta? Criar" navega para /register

### Fluxo de Cadastro (/register)

- Tela separada acessada pelo link na tela de login — não inline/toggle
- Campos: Nome completo, Email, Senha, Confirmar senha
- Nome vira `displayName` no UserModel e no Firebase Auth
- Role inicial: sempre `'client'` — admins são criados manualmente no Firebase Console
- Erros de validação: inline, mesma abordagem do login

### Aba Perfil (autenticado)

- Exibe: avatar circular (foto do Google se disponível, ou inicial do nome), nome completo, email
- Botão "Sair da conta" para logout
- Read-only em Phase 2 — sem edição de nome ou dados
- Aba Perfil quando não autenticado: nunca acessível (redirect para /login)

### Redirecionamento e Guards de Rota

- Após login bem-sucedido: sempre navega para `/home` (simples e previsível)
- Usuário não autenticado tentando acessar qualquer rota protegida (`/home`, `/bookings`, `/profile`, `/admin`): redirect para `/login`
- Usuário autenticado com role `'client'` tentando acessar `/admin`: tela "Acesso negado" — não redireciona silenciosamente
- Guard implementado no `redirect` callback do GoRouter usando `AuthCubit` state

### Cold Start / Splash

- Enquanto Firebase Auth inicializa e verifica sessão: exibe splash screen com nome "Vida Ativa" e cor verde da marca (`#2E7D32`)
- Após auth state resolver: navega para `/home` (autenticado) ou `/login` (não autenticado)
- Evita flash de tela branca / flash de login desnecessário

### Criação do UserModel no Firestore

- Login com Google (primeiro acesso): cria documento em `/users/{uid}` com `role: 'client'`, `displayName` e `email` do Google
- Login com Google (acesso subsequente): documento já existe — não sobrescreve
- Cadastro com email/senha: cria usuário no Firebase Auth E documento em `/users/{uid}` atomicamente (ou em sequência imediata)
- AuthCubit é responsável por esta lógica

### Claude's Discretion

- Implementação interna do AuthCubit (estados: initial, loading, authenticated, unauthenticated, error)
- Animação de transição da splash screen para o destino
- Validação de senha (comprimento mínimo, etc.)
- Layout exato do avatar (tamanho, border, fallback para inicial)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — AUTH-01 a AUTH-05 são os requisitos desta fase

### Roadmap
- `.planning/ROADMAP.md` §Phase 2 — Success criteria completos (5 critérios verificáveis)

### Foundation (Phase 1)
- `.planning/phases/01-foundation/01-CONTEXT.md` — Estrutura de pastas, UserModel, go_router setup, BLoC sem root wrapper

### Projeto
- `.planning/PROJECT.md` — Stack (flutter_bloc, go_router, firebase_auth), decisões de arquitetura

No external specs — requirements fully captured in decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/core/models/user_model.dart` — UserModel com campos `uid`, `email`, `displayName`, `role`, `phone`; getter `isAdmin`; `fromFirestore`/`toFirestore`
- `lib/core/router/app_router.dart` — GoRouter com `StatefulShellRoute.indexedStack`, redirect hook (`/` → `/home`), rotas `/login` e `/admin` já declaradas como placeholders
- `lib/features/auth/ui/login_placeholder_screen.dart` — Placeholder existente para substituir
- `lib/features/auth/ui/profile_placeholder_screen.dart` — Placeholder existente para substituir
- `lib/core/theme/app_theme.dart` — `primaryGreen (#2E7D32)`, `primaryBlue (#0175C2)`, Material 3 theme

### Established Patterns
- BLoC: `flutter_bloc ^9.1.1` instalado; nenhum root wrapper — `BlocProvider` adicionado por feature
- go_router redirect: callback sem estado externo em Phase 1 — Phase 2 precisa injetar AuthCubit no redirect (via `refreshListenable` ou `GoRouter.of(context)`)
- Firebase Auth: `firebase_auth 6.2.0` já instalado e configurado via `firebase_options.dart`

### Integration Points
- `lib/core/router/app_router.dart` — Adicionar guard de auth no `redirect` callback; substituir builders dos placeholders por telas reais
- `lib/main.dart` — Adicionar `BlocProvider<AuthCubit>` acima do `MaterialApp.router` para expor AuthCubit ao GoRouter redirect
- `lib/features/auth/` — Criar: `auth_cubit.dart`, `login_screen.dart`, `register_screen.dart`; atualizar `profile_screen.dart`
- Firestore `/users` collection — Criar documento do usuário no primeiro login (regras Phase 1 já permitem writes autenticados)

</code_context>

<specifics>
## Specific Ideas

- Tela "Acesso negado" para clientes tentando acessar /admin — simples, com mensagem clara e botão "Voltar para Agenda"
- Splash screen deve usar a cor verde `#2E7D32` (primaryGreen do AppTheme) como background — consistente com manifest.json `theme_color`

</specifics>

<deferred>
## Deferred Ideas

- Login com número de telefone (OTP) — AUTH-v2-01 já no backlog v2
- Edição de perfil (nome, telefone) — pode entrar em v2
- Foto de perfil personalizada (upload) — fora de escopo

</deferred>

---

*Phase: 02-auth*
*Context gathered: 2026-03-19*
