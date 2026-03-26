---
phase: 10
slug: monitoramento-de-erros
created: 2026-03-26
status: ready
---

# Phase 10: Monitoramento de Erros - Context

**Gathered:** 2026-03-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Captura automática de erros em produção via Sentry e registro de contexto suficiente (stack trace, plataforma, user ID) para diagnóstico sem reprodução manual. Sem mudanças visíveis ao usuário final — é infraestrutura de observabilidade para o desenvolvedor/admin.

</domain>

<decisions>
## Implementation Decisions

### Tool choice
- **Sentry** via `sentry_flutter` — único com suporte oficial para Flutter Web
- Firebase Crashlytics descartado — não suporta Flutter Web
- DSN armazenado via `--dart-define=SENTRY_DSN=...` no build — não hardcoded no repositório
- Usuário ainda não tem conta Sentry — plano deve incluir instruções para criar conta + projeto + obter DSN

### Escopo dos erros
- `SentryFlutter.init()` com `appRunner` para captura automática de:
  - Exceções não tratadas (Flutter framework errors via `FlutterError.onError`)
  - Erros assíncronos de plataforma via `PlatformDispatcher.instance.onError`
- `Sentry.captureException(e, stackTrace: s)` adicionado nos `catch` blocks de **todos os cubits**:
  - `AuthCubit`
  - `ScheduleCubit` (ou cubit equivalente de agenda)
  - `BookingCubit`
  - `AdminBookingCubit`
  - Qualquer outro cubit com try/catch no codebase
- Sem BlocObserver customizado (erros de Bloc geralmente viram estados de UI)

### Contexto do usuário
- `Sentry.configureScope` define `userId` com o UID do Firebase Auth
- Configurado no `AuthCubit` ao emitir `AuthAuthenticated` — sempre reflete o usuário atual
- Scope limpo ao emitir `AuthUnauthenticated` (logout)
- Somente UID — sem email, nome ou outros dados pessoais

### Claude's Discretion
- Configuração de release/environment tags no Sentry init (ex: `environment: 'production'`)
- Breadcrumb configuration (padrão do Sentry é suficiente)
- Performance monitoring desabilitado — OPS-01 é somente error tracking, não perf

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

No external specs — requirements are fully captured in decisions above.

### Roadmap & Requirements
- `.planning/ROADMAP.md` §Phase 10 — Success Criteria 1, 2 (captura de erros, contexto para diagnóstico)
- `.planning/REQUIREMENTS.md` §OPS-01 — Acceptance criteria completo

### Codebase Reference
- `lib/main.dart` — Ponto de entrada onde `SentryFlutter.init()` deve envolver o app; Firebase init já presente
- `lib/features/auth/cubit/auth_cubit.dart` — Local para configurar/limpar Sentry scope com UID; emit AuthAuthenticated / AuthUnauthenticated
- `pubspec.yaml` — Adicionar `sentry_flutter` como dependência

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `main()` em `lib/main.dart`: já tem `WidgetsFlutterBinding.ensureInitialized()` e `Firebase.initializeApp()` — `SentryFlutter.init()` envolve o bloco `runApp` existente
- `AuthCubit.emit(AuthAuthenticated(...))`: chamado em `_onAuthStateChanged` e após login — ponto ideal para `Sentry.configureScope`
- `AuthCubit.emit(AuthUnauthenticated())`: chamado no logout — ponto para `Sentry.configureScope(user: null)`

### Established Patterns
- Erros nos cubits são capturados em try/catch e emitidos como estado de erro (ex: `emit(AuthError(...))`) — adicionar `Sentry.captureException` antes do emit, sem alterar o fluxo
- `kIsWeb` já importado em `main.dart` — útil se alguma configuração do Sentry for web-específica

### Integration Points
- `main.dart` — envolve `runApp` com `SentryFlutter.init(appRunner: () => runApp(...))`
- `auth_cubit.dart` — dois pontos de scope: após login (`AuthAuthenticated`) e no logout (`AuthUnauthenticated`)
- Todos os cubits com `catch` — inserir `Sentry.captureException(e, stackTrace: s)` no catch block

</code_context>

<specifics>
## Specific Ideas

- O plano deve incluir passo manual de setup: "Criar conta em sentry.io, criar projeto Flutter, copiar DSN"
- DSN em `--dart-define` significa que o comando de build/deploy precisa ser atualizado: `flutter build web --dart-define=SENTRY_DSN=https://...`
- Se o DSN não estiver definido (ambiente de desenvolvimento), Sentry deve ser inicializado com DSN vazio ou condicional (`kReleaseMode`) para não poluir o painel com erros de dev

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 10-monitoramento-de-erros*
*Context gathered: 2026-03-26*
