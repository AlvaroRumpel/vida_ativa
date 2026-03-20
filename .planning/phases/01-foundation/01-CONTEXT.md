# Phase 1: Foundation - Context

**Gathered:** 2026-03-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Entregar o esqueleto estrutural do app: modelos de dados, configuração do Riverpod e go_router, app shell com BottomNav e placeholders, regras de segurança do Firestore (deny unauthenticated writes), configuração do PWA manifest e firebase.json. Nenhuma feature visível ao usuário — só a base sobre a qual todas as outras fases constroem.

</domain>

<decisions>
## Implementation Decisions

### Estrutura de pastas
- Feature-first: `lib/features/{auth,schedule,booking,admin}/` para telas e providers de cada feature
- `lib/core/models/` — os 4 modelos de dados
- `lib/core/services/` — FirestoreService, AuthService (stubs em Phase 1)
- `lib/core/theme/` — AppTheme com as cores centralizadas (fácil de mudar)

### Data models

**UserModel** (coleção `/users/{uid}`):
- `uid` (String) — ID do documento = UID do Firebase Auth
- `email` (String)
- `displayName` (String)
- `role` (String) — `"client"` ou `"admin"`
- `phone` (String?) — opcional, para o admin contactar o cliente

**SlotModel** (coleção `/slots/{slotId}`):
- `dayOfWeek` (int) — 1=Segunda, 2=Terça, ..., 7=Domingo (convenção DateTime.weekday do Dart)
- `startTime` (String) — formato `"HH:mm"` (ex: `"08:00"`)
- `price` (double) — ex: `35.5` (pagamento presencial, sem cálculos financeiros no app)
- `isActive` (bool) — false = desativado sem excluir (ADMN-02)
- Sem `durationMinutes` em v1 — todos os slots têm duração implícita de 1h ou definida pelo admin textualmente

**BookingModel** (coleção `/bookings/{bookingId}`):
- ID do documento: deterministico `{slotId}_{date}` — obrigatório para anti-double-booking via Firestore Transaction
- `slotId` (String)
- `date` (String) — formato `"YYYY-MM-DD"`
- `userId` (String) — UID de quem reservou
- `status` (String) — `"pending"` | `"confirmed"` | `"cancelled"`
- `createdAt` (Timestamp)
- `cancelledAt` (Timestamp?) — nullable, preenchido ao cancelar

**BlockedDateModel** (coleção `/blockedDates/{date}`):
- ID do documento = data no formato `"YYYY-MM-DD"` — lookup O(1) sem query
- `date` (String) — redundante com o ID mas facilita serialização
- `createdBy` (String) — UID do admin que criou o bloqueio

### App shell / navegação

- `BottomNavigationBar` com 3 tabs: **Agenda** / **Minhas Reservas** / **Perfil**
- Phase 1 entrega placeholders em cada tab — phases seguintes preenchem sem mudar a estrutura
- Admin panel: rota `/admin` separada, **não aparece na BottomNav** — go_router guard verifica `role == "admin"`
- Rotas Phase 1: `/` → redirect para `/home`, `/home` (com shell), `/admin` (placeholder com guard), `/login` (placeholder)
- MaterialApp.router com go_router

### Branding / PWA

- **Cores**: azul e verde como primárias — definidas em `AppTheme` para fácil alteração posterior
  - Verde: `Colors.green` (seed do Material 3 já no main.dart)
  - Azul: a definir no AppTheme (ex: `Color(0xFF0175C2)` como secondary ou ajustar no AppTheme)
- `manifest.json`:
  - `name`: `"Vida Ativa"`
  - `short_name`: `"Vida Ativa"`
  - `description`: `"Reserve sua quadra na Academia Vida Ativa"`
  - `background_color` e `theme_color`: atualizar para verde da marca (ex: `#2E7D32`)
  - Ícones maskable já existem — manter
- `firebase.json`: adicionar SPA rewrite (`"destination": "/index.html"`) e header `Cache-Control: no-cache` para `flutter_service_worker.js`

### Regras de segurança do Firestore (Phase 1)

- `firestore.rules` criado e deployed antes de qualquer dado real
- Phase 1: regras básicas — deny all unauthenticated writes em todas as coleções
- Phase 6 finaliza as regras com granularidade completa (client não lê bookings alheios, isAdmin() para writes admin)

### Claude's Discretion
- Exata implementação das Riverpod overrides no main.dart (ProviderScope wrapping)
- Estrutura interna de cada feature directory (ex: screens/, providers/, widgets/ dentro de cada feature)
- Enum vs String para `role` e `status` — pode usar String com constantes ou enum com serialização

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — INFRA-01, INFRA-02, PWA-01, PWA-02 são os requisitos desta fase

### Roadmap
- `.planning/ROADMAP.md` §Phase 1 — Success criteria completos (5 critérios verificáveis)

### Research
- `.planning/research/STACK.md` — Riverpod 2.x, go_router, table_calendar, renderer choice
- `.planning/research/ARCHITECTURE.md` — Feature-first folder pattern, StreamProvider pattern, Firestore composite index
- `.planning/research/PITFALLS.md` — Armadilha #1: double booking via Transaction; offline persistence vs transactions

### Projeto
- `.planning/PROJECT.md` — Context, stack, data model overview

No external specs — requirements fully captured in decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/main.dart`: Firebase init (`WidgetsFlutterBinding.ensureInitialized` + `Firebase.initializeApp`) — manter, só adicionar ProviderScope e MaterialApp.router
- `lib/firebase_options.dart`: Configuração Firebase gerada pelo FlutterFire CLI — não modificar
- `web/manifest.json`: Estrutura correta com maskable icons e `display: standalone` — só atualizar name/colors/description
- `web/icons/`: Ícones 192/512 maskable já existem — não recriar

### Established Patterns
- Material 3 com `useMaterial3: true` e `ColorScheme.fromSeed` — manter e mover para AppTheme
- Firebase packages já instalados: firebase_core 4.5.0, firebase_auth 6.2.0, cloud_firestore 6.1.3 — adicionar flutter_bloc e go_router ao pubspec.yaml

### Integration Points
- `main.dart` é o único entry point — Phase 1 o transforma: troca MaterialApp por MaterialApp.router (BLoC não precisa de root wrapper como ProviderScope)
- `pubspec.yaml` precisa de 2 novas deps: `flutter_bloc` (^9.x) e `go_router` (^14.x)
- `firebase.json` existe mas sem SPA rewrite — adicionar configuração de hosting

</code_context>

<specifics>
## Specific Ideas

- Cores azul+verde devem estar em um único arquivo `lib/core/theme/app_theme.dart` — uma linha muda a cor do app inteiro
- O BookingModel com ID determinístico `{slotId}_{date}` é crítico — não usar `.add()` do Firestore, sempre `.doc('{slotId}_{date}').set()` dentro de Transaction

</specifics>

<deferred>
## Deferred Ideas

Nenhuma — discussão ficou dentro do escopo da Phase 1.

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-03-19*
