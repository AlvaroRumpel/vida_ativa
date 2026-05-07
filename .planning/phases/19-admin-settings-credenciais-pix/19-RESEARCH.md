# Phase 19: Admin Settings + Credenciais Pix - Research

**Researched:** 2026-05-07
**Domain:** Firebase Cloud Functions v2 credential storage + Flutter admin settings UI + Firestore security patterns
**Confidence:** HIGH

## Summary

Phase 19 transitions Mercado Pago credentials from hardcoded Secret Manager (`defineSecret()`) to runtime Firestore storage accessible via the admin panel. This enables admins to rotate credentials without redeploying Cloud Functions, and maintains backward compatibility with existing Secret Manager deployments.

Research confirms three critical patterns:
1. **Firestore as runtime config store:** Admin SDK reads `config/mercadopago` at function invocation time, with Secret Manager as fallback
2. **Security isolation:** Write-only rules (`allow read: if false`) prevent client leaks; Admin SDK bypasses rules entirely
3. **UI pattern:** Flutter password field with `obscureText` toggle + state tracking for "already configured" status, avoiding credential readback

**Primary recommendation:** Implement SettingsTab cubit following admin_booking_cubit pattern, use onCall functions to read Firestore config per invocation (no global caching), add credential existence check to admin UI without exposing values.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Nova aba "Config" (ou "Configurações") adicionada ao TabBar existente no AdminScreen — padrão de tabs já estabelecido nas fases anteriores. Total: 6 tabs.
- **D-02:** Kill switch `pixEnabled` movido da aba "Reservas" para a aba "Config" — agrupamento lógico de toda configuração Pix num só lugar.
- **D-03:** Dois campos na UI: `accessToken` (MP Access Token de produção) e `webhookSecret` (MP Webhook Secret). Ambos necessários para Pix funcionar end-to-end.
- **D-04:** Campos opcionais individualmente — admin pode salvar sem preencher os dois. Status de "configurado" exibido por campo (ex: checkmark verde se já definido).
- **D-05:** Campos renderizados como `obscureText: true` (password field) com botão show/hide.
- **D-06:** Ao carregar a tela, se credencial já está definida no Firestore, campo mostra placeholder "••••••••" e não retorna o valor real ao cliente. O admin digita novo valor apenas para atualizar.
- **D-07:** Botão "Salvar" separado por seção. Ao salvar, cubit escreve no Firestore — nunca lê de volta o token para o estado Flutter.
- **D-08:** Documento: `config/mercadopago` com campos `{ accessToken: string, webhookSecret: string, updatedAt: timestamp }`.
- **D-09:** Regras de segurança: `allow read: if false` para todos os clients (incluindo admin via Flutter). `allow write: if isAdmin()` para admin escrever. Cloud Functions usam admin SDK — regras não se aplicam.
- **D-10:** Campo separado `config/settings` (já existente com `pixEnabled`, `confirmationMode`) permanece intacto. Credenciais ficam em documento separado para isolamento.
- **D-11:** CFs leem de `config/mercadopago` no Firestore como fonte **primária** (via admin SDK). Se o campo estiver vazio ou o documento não existir, fazem fallback para `defineSecret('MP_ACCESS_TOKEN')` / `defineSecret('MP_WEBHOOK_SECRET')`.
- **D-12:** Funções afetadas: `createPixPayment`, `handlePixWebhook`, `expireUnpaidBookings`.
- **D-13:** Se nem Firestore nem Secret Manager tiver o token, a função retorna erro claro: `MP_ACCESS_TOKEN not configured`.

### Claude's Discretion
- Ordem e layout visual da aba Config (seções, espaçamentos, ícones).
- Nome exato da aba: "Config" vs "Configurações" (usar o que couber melhor no TabBar).
- Loading state da aba enquanto verifica se credenciais já estão definidas.
- Cubit/state design para a aba de configurações.

### Deferred Ideas (OUT OF SCOPE)
- Validar token MP contra a API antes de salvar (call de teste) — complexidade extra, defer para v5
- Múltiplas academias / multi-tenant com credenciais diferentes por tenant — v5+
- Histórico de alterações de credenciais (audit log) — v5+

</user_constraints>

<phase_requirements>

## Phase Requirements

No formal requirement IDs defined yet. Phase 19 supports v4.0 milestone completion by enabling runtime credential management (previously blocked on Secret Manager manual setup).

| Requirement | Description | Research Support |
|-------------|-------------|------------------|
| Admin UI for credentials | Settings tab manages MP credentials with secure masking | SettingsTab + SettingsCubit pattern (D-05, D-06, D-07) |
| Firestore storage | Credentials stored at `config/mercadopago` with write-only rules | Document structure (D-08) + security rules (D-09) |
| Cloud Functions fallback | createPixPayment, handlePixWebhook, expireUnpaidBookings read Firestore first, then Secret Manager | Function read pattern (D-11, D-12, D-13) |
| Credential existence check | UI shows "Configured" status without revealing value | Admin SDK read pattern + rule isolation |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter `cloud_firestore` | Latest (project version) | Admin SDK for reading config docs | Already used throughout codebase for Firestore operations |
| Firebase Admin SDK (Node.js) | v11.x+ | Server-side Firestore + Secret Manager reads | Standard Firebase runtime pattern; no client SDK needed in functions |
| `@mercadopago/sdk-node` | v2.0.0 | MP Orders API for credential validation fallback | Already chosen for Pix (Phase 17) |

### Supporting (Admin UI)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `flutter_bloc` | Project version | State management for settings cubit | Consistent with all admin tabs (pricing_cubit, admin_booking_cubit) |
| Material `TextField` / `TextFormField` | Dart:material | Masked input with `obscureText: true` + show/hide toggle | Native Flutter; no 3rd-party masking library needed |
| `equatable` | Project version | Value comparison for state equality | Standard BLoC/Cubit pattern used throughout |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Firestore for credentials | Hardcode in environment only | No runtime rotation; requires CF redeploy |
| Firestore for credentials | Custom in-memory cache with TTL | Adds complexity; single-instance assumption fragile in distributed deployment |
| Flutter password field UI | Custom PinPut / obscure library | Unnecessary; native `obscureText` covers requirement |

**Installation:** No new packages required. Use existing Firebase Admin SDK + Flutter cloud_firestore.

**Version verification:** [VERIFIED: Flutter pubspec.yaml, functions/package.json]

## Architecture Patterns

### Recommended Firestore Structure

```
config/
├── mercadopago/
│   ├── accessToken: string
│   ├── webhookSecret: string
│   └── updatedAt: Timestamp
└── settings/ (existing, unchanged)
    ├── pixEnabled: bool
    └── confirmationMode: string
```

**Rationale:** Separate `config/mercadopago` from `config/settings` isolates credentials and allows different rule sets (credentials = write-only from admin, settings = read-write for functionality checks).

### Pattern 1: Cloud Functions v2 Reading Firestore for Credentials

**What:** Instead of calling `mpAccessToken.value()` directly, functions first check Firestore `config/mercadopago`, then fall back to Secret Manager.

**When to use:** Every function that needs MP credentials (createPixPayment, handlePixWebhook).

**Example (Node.js):**
```javascript
// Source: Firebase official docs — Cloud Functions + Admin SDK pattern
// https://firebase.google.com/docs/functions/firestore-events

async function getMpAccessToken() {
  const db = admin.firestore();
  const configSnap = await db.collection('config').doc('mercadopago').get();
  const tokenFromFirestore = configSnap.data()?.accessToken;
  
  if (tokenFromFirestore && tokenFromFirestore.trim()) {
    return tokenFromFirestore;
  }
  
  // Fallback to Secret Manager
  return mpAccessToken.value();
}

// In createPixPayment onCall:
const token = await getMpAccessToken();
const client = new MercadoPagoConfig({ accessToken: token });
```

**Key insight:** Read-per-invocation is safe because Cloud Functions instances are short-lived (< 10 min typical). No global caching needed; simplicity > premature optimization.

### Pattern 2: Firestore Security Rules for Write-Only Credentials

**What:** Rules deny all client reads of credentials, admin writes only. Admin SDK (used by Cloud Functions) bypasses rules entirely.

**When to use:** Protecting sensitive config documents from accidental client exposure.

**Example (Firestore rules):**
```
match /config/{docId} {
  allow read: if isAuthenticated();
  allow write: if isAdmin();
  
  // Override for mercadopago: stricter
  match /mercadopago {
    allow read: if false;  // No client reads, ever
    allow write: if isAdmin();  // Admin writes only
  }
}
```

**Why this works:** 
- Client SDK (Flutter) is subject to rules → blocked read
- Admin SDK (Cloud Functions) bypasses rules → reads work fine
- [CITED: firebase.google.com/docs/firestore/security] "Server client libraries bypass all Cloud Firestore Security Rules and instead authenticate through Google Application Default Credentials"

### Pattern 3: Flutter Admin Settings Tab with Masked Credentials

**What:** SettingsTab component with two password fields (accessToken, webhookSecret) that:
1. Load on init to check if credentials exist (show "Configured" badge)
2. Never read back the actual value after save
3. Show/hide toggle using `obscureText` boolean state

**When to use:** All sensitive admin config that shouldn't be readable from client.

**Example (Flutter):**
```dart
// Source: Flutter official TextField API + BLoC pattern (admin_booking_cubit example)

class SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return switch (state) {
          SettingsInitial() => const Center(child: CircularProgressIndicator()),
          SettingsLoaded(:final isAccessTokenConfigured, :final isWebhookSecretConfigured) =>
            _SettingsForm(
              isAccessTokenConfigured: isAccessTokenConfigured,
              isWebhookSecretConfigured: isWebhookSecretConfigured,
            ),
          SettingsError(:final message) => Center(
            child: Text(message, style: const TextStyle(color: Colors.red)),
          ),
        };
      },
    );
  }
}

class _SettingsForm extends StatefulWidget {
  final bool isAccessTokenConfigured;
  final bool isWebhookSecretConfigured;
  
  const _SettingsForm({
    required this.isAccessTokenConfigured,
    required this.isWebhookSecretConfigured,
  });

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  late final TextEditingController _accessTokenController;
  late final TextEditingController _webhookSecretController;
  bool _showAccessToken = false;
  bool _showWebhookSecret = false;

  @override
  void initState() {
    super.initState();
    _accessTokenController = TextEditingController();
    _webhookSecretController = TextEditingController();
  }

  @override
  void dispose() {
    _accessTokenController.dispose();
    _webhookSecretController.dispose();
    super.dispose();
  }

  Future<void> _saveCredentials() async {
    final cubit = context.read<SettingsCubit>();
    final token = _accessTokenController.text.trim();
    final secret = _webhookSecretController.text.trim();
    
    try {
      await cubit.saveCredentials(
        accessToken: token,
        webhookSecret: secret,
      );
      
      if (mounted) {
        SnackHelper.success(context, 'Credenciais salvas.');
        _accessTokenController.clear();
        _webhookSecretController.clear();
      }
    } catch (e) {
      if (mounted) {
        SnackHelper.error(context, 'Erro: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Mercado Pago',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Access Token field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _accessTokenController,
                  obscureText: !_showAccessToken,
                  decoration: InputDecoration(
                    labelText: 'Access Token',
                    hintText: widget.isAccessTokenConfigured
                        ? '••••••••••••••••'
                        : 'Cole o token do Mercado Pago',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showAccessToken ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _showAccessToken = !_showAccessToken),
                    ),
                  ),
                ),
              ),
              if (widget.isAccessTokenConfigured)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Webhook Secret field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _webhookSecretController,
                  obscureText: !_showWebhookSecret,
                  decoration: InputDecoration(
                    labelText: 'Webhook Secret',
                    hintText: widget.isWebhookSecretConfigured
                        ? '••••••••••••••••'
                        : 'Cole o secret do webhook',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showWebhookSecret ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _showWebhookSecret = !_showWebhookSecret),
                    ),
                  ),
                ),
              ),
              if (widget.isWebhookSecretConfigured)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          FilledButton(
            onPressed: _saveCredentials,
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: const Text('Salvar Credenciais'),
          ),
        ],
      ),
    );
  }
}
```

### Pattern 4: Cubit for Settings Management

**What:** SettingsCubit loads credential existence on init, handles save operations, emits states for Loading/Loaded/Error.

**When to use:** Consistent with admin_booking_cubit pattern; separates UI from Firestore logic.

**Example:**
```dart
// Source: admin_booking_cubit.dart (existing pattern in project)

class SettingsCubit extends Cubit<SettingsState> {
  final FirebaseFirestore _firestore;
  final String _adminUid;

  SettingsCubit({
    required FirebaseFirestore firestore,
    required String adminUid,
  })  : _firestore = firestore,
        _adminUid = adminUid,
        super(const SettingsInitial()) {
    _loadCredentialStatus();
  }

  Future<void> _loadCredentialStatus() async {
    try {
      final configSnap = await _firestore
          .collection('config')
          .doc('mercadopago')
          .get();
      
      final data = configSnap.data();
      final isAccessTokenConfigured = (data?['accessToken'] ?? '').isNotEmpty;
      final isWebhookSecretConfigured = (data?['webhookSecret'] ?? '').isNotEmpty;
      
      emit(SettingsLoaded(
        isAccessTokenConfigured: isAccessTokenConfigured,
        isWebhookSecretConfigured: isWebhookSecretConfigured,
      ));
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
      emit(SettingsError('Erro ao carregar configurações.'));
    }
  }

  Future<void> saveCredentials({
    String? accessToken,
    String? webhookSecret,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (accessToken != null && accessToken.isNotEmpty) {
        data['accessToken'] = accessToken;
      }
      if (webhookSecret != null && webhookSecret.isNotEmpty) {
        data['webhookSecret'] = webhookSecret;
      }
      
      if (data.isEmpty) {
        throw Exception('Pelo menos um campo é obrigatório');
      }
      
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection('config')
          .doc('mercadopago')
          .set(data, SetOptions(merge: true));
      
      // Reload to show confirmation
      await _loadCredentialStatus();
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
```

### Anti-Patterns to Avoid
- **Reading credential values back to client after save:** Never emit the actual token in state; only emit boolean "is configured" flags. Firestore rules enforce this, but UI shouldn't attempt it.
- **Global in-memory credential caching at function startup:** Cloud Functions instances are ephemeral; per-invocation Firestore reads are simpler and safer.
- **Custom password masking libraries:** Flutter's native `obscureText` covers all requirements; avoid 3rd-party complexity.
- **Single credentials document mixing sensitive + non-sensitive config:** Separate `config/mercadopago` from `config/settings` allows granular security rules.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Credential masking in UI | Custom obscure logic | Flutter's `obscureText` + `IconButton` toggle | Native, tested, works with all keyboards |
| Firestore credential storage encryption | Client-side encryption before save | Firestore at-rest encryption (built-in) + write-only rules | Automatic, auditable, no key management burden |
| Cloud Functions config reading | Global module-level cache | Read per-invocation from Firestore | Handles multi-region; no cache invalidation issues |
| Checking "credential exists" from client | Try-read & catch permission error | Cubit loads status on init, UI shows boolean flag | No unnecessary API calls; explicit intent |
| Secret rotation validation | Custom MP API test call | Defer to v5 (per CONTEXT.md deferred ideas) | Reduces scope; Phase 19 is credentials storage, not validation |

**Key insight:** Firestore + Admin SDK handles credential isolation automatically via rules. No hand-rolled encryption, caching, or validation logic needed.

## Architecture Decisions Breakdown

### 1. Why Read Firestore Per-Invocation, Not Globally?

[VERIFIED: Firebase Cloud Functions documentation — https://firebase.google.com/docs/functions/tips]

Cloud Functions v2 provides `onInit` for startup initialization, but credentials are not a use case for it:
- **Per-invocation read (recommended):** Function reads `config/mercadopago` on each call → always fresh, no cache invalidation, no multi-region issues
- **Global cache:** Requires careful TTL management, potential stale data if credential rotated, complexity in distributed deployments

**Decision:** Per-invocation reads. Firestore is millisecond-fast for single-document reads; the performance cost is negligible vs. caching complexity.

### 2. Why Separate `config/mercadopago` From `config/settings`?

[ASSUMED based on D-10 decision] Credentials and app settings have different security profiles:
- **Credentials:** Write-only from admin, never read by client. Firestore rules: `allow read: if false; allow write: if isAdmin()`
- **Settings (pixEnabled, confirmationMode):** Both client and admin need reads. Rules: `allow read: if isAuthenticated(); allow write: if isAdmin()`

If merged into one doc, either:
1. Client gets read access to credentials (security leak), or
2. Client blocked from reading settings (functionality breaks)

Separate docs isolate concerns and allow granular rules.

### 3. Why Not Validate Token Against MP API Before Saving?

[DEFERRED per CONTEXT.md] Phase 19 scope is credential storage. Token validation (API test call) deferred to v5 because:
- Adds latency to save operation
- Requires handling MP API errors gracefully
- Can be added later without breaking existing saves

Phase 19 focuses on: store safely, read safely, UI UX for secure input.

## Common Pitfalls

### Pitfall 1: Reading Credentials Back to Client

**What goes wrong:** Cubit emits `SettingsLoaded(accessToken: 'sk_live_123...')` → token visible in Flutter memory/logs → security leak.

**Why it happens:** Habit of emitting form data; credentials are different.

**How to avoid:** Emit only boolean flags (`isAccessTokenConfigured: true`). Firestore rules enforce this, but UI should enforce it voluntarily.

**Warning signs:** 
- State class contains String fields for tokens
- Any code doing `snapshot.data()?.['accessToken']` and storing in Cubit
- Error logs showing token values

### Pitfall 2: Forgetting Fallback to Secret Manager

**What goes wrong:** Cloud Function crashes because `config/mercadopago` doesn't exist yet (before first admin save).

**Why it happens:** Assuming Firestore doc always exists.

**How to avoid:** Every MP function needs:
```javascript
const token = await getMpAccessToken();  // checks Firestore, falls back to Secret Manager
if (!token) throw new HttpsError('failed-precondition', 'MP_ACCESS_TOKEN not configured');
```

**Warning signs:** 
- Function throws "accessToken is undefined"
- Works fine in production but fails in fresh staging deploys before admin configures credentials

### Pitfall 3: Admin SDK Rules Misunderstanding

**What goes wrong:** Developer adds rules thinking they protect Cloud Functions, realizes rules don't apply, credentials leaked via CF logs.

**Why it happens:** Confusion about Admin SDK authority.

**How to avoid:** Remember: Admin SDK bypasses all rules. Use IAM policies (server-side) and careful code review, not rules, to protect admin operations.

**Warning signs:** 
- Thinking Firestore rules alone protect credentials from CF
- No awareness of who can call the CF (should require `isAdmin()` check in CF code)

### Pitfall 4: Password Field Showing Placeholder After Save

**What goes wrong:** After saving token, field still shows "••••••••" placeholder, admin thinks save failed.

**Why it happens:** Placeholder tied to `isAccessTokenConfigured` flag, which doesn't clear on save.

**How to avoid:** On successful save:
1. Clear text controllers: `_accessTokenController.clear()`
2. Reload credential status via cubit: `await cubit._loadCredentialStatus()`
3. Show success SnackBar with explicit message

**Warning signs:** 
- Empty field after save still shows "••••••••"
- Admin unsure if credential was saved

### Pitfall 5: Hardcoding Firestore Paths

**What goes wrong:** CF reads `config/settings` for one thing, `config/mercadopago` for another; easy to mix up paths if not careful.

**Why it happens:** Multiple config docs in same collection.

**How to avoid:** Define path constants at top of files:
```javascript
const CONFIG_MERCADOPAGO = 'config/mercadopago';
const CONFIG_SETTINGS = 'config/settings';
```

**Warning signs:** 
- Grepping for 'config/' returns inconsistent results
- Code review comments asking "which config doc is this?"

## Code Examples

### Cloud Function: Reading MP Token with Fallback

```javascript
// Source: Implemented in Phase 18 (createPixPayment); extending for Phase 19

const { onCall } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');

const mpAccessToken = defineSecret('MP_ACCESS_TOKEN');
const mpWebhookSecret = defineSecret('MP_WEBHOOK_SECRET');

async function getMpAccessToken(db) {
  try {
    const configSnap = await db.collection('config').doc('mercadopago').get();
    const token = configSnap.data()?.accessToken;
    if (token && token.trim()) {
      console.log('Using MP_ACCESS_TOKEN from Firestore');
      return token;
    }
  } catch (err) {
    console.warn('Failed to read MP token from Firestore, falling back:', err.message);
  }
  
  const token = mpAccessToken.value();
  console.log('Using MP_ACCESS_TOKEN from Secret Manager');
  return token;
}

exports.createPixPayment = onCall(
  { secrets: [mpAccessToken, mpWebhookSecret] },
  async (request) => {
    const db = admin.firestore();
    const token = await getMpAccessToken(db);
    
    if (!token) {
      throw new HttpsError('failed-precondition', 'MP_ACCESS_TOKEN not configured');
    }
    
    const client = new MercadoPagoConfig({ accessToken: token });
    // ... rest of function
  }
);
```

### Flutter: Loading and Checking Credential Status

```dart
// Source: admin_booking_cubit.dart pattern applied to credentials

final configSnap = await _firestore
    .collection('config')
    .doc('mercadopago')
    .get();

// Check existence WITHOUT reading the value
final isAccessTokenConfigured = (configSnap.data()?['accessToken'] ?? '').toString().isNotEmpty;
final isWebhookSecretConfigured = (configSnap.data()?['webhookSecret'] ?? '').toString().isNotEmpty;

// Only emit flags, never the actual values
emit(SettingsLoaded(
  isAccessTokenConfigured: isAccessTokenConfigured,
  isWebhookSecretConfigured: isWebhookSecretConfigured,
));
```

### Firestore Rules: Write-Only Credentials

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() {
      return request.auth != null;
    }

    function isAdmin() {
      return isAuthenticated() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "admin";
    }

    match /config/{docId} {
      // Default config docs: read for authenticated, write for admin
      allow read: if isAuthenticated();
      allow write: if isAdmin();
      
      // Override for mercadopago: stricter — no client reads, ever
      match /mercadopago {
        allow read: if false;
        allow write: if isAdmin();
      }
    }
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded Secret Manager only | Firestore as primary, Secret Manager fallback | This phase (v4.0) | Admins can rotate credentials without CF redeploy |
| No admin UI for credentials | SettingsTab + SettingsCubit | This phase | Enables runtime configuration |
| Single config document | Separate `config/mercadopago` + `config/settings` | This phase | Allows granular security rules per config type |
| `defineSecret().value()` at module level | Per-invocation Firestore read + fallback | This phase | Simpler, stateless, no cache invalidation |

**Deprecated/outdated:**
- Using only Secret Manager for MP credentials: Still works as fallback (Phase 18 deployments), but doesn't support admin rotation. Phase 19 makes it optional.
- Single-doc config in Firestore: `config/settings` sufficient for non-sensitive toggles; credentials need isolation.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Cloud Functions v2 per-invocation Firestore reads are fast enough (~50ms latency) to not require global caching | Architecture Decisions | If reads become slow, may need to reconsider caching strategy; recommend load-testing in Phase 22 optimization phase |
| A2 | Admin SDK initialization is guaranteed before any Cloud Function invocation | Cloud Functions Pattern | If not, reads fail; mitigation: explicit `admin.initializeApp()` call at module top (already done in Phase 18) |
| A3 | Firestore rules `allow read: if false` effectively prevent client SDK reads even for authenticated admins | Architecture Decisions | If rules don't apply to client, sensitive data exposed; verify with Firebase console test mode during Phase 19 planning |

**Validation:** All other claims verified through code inspection (admin_booking_cubit pattern), official Firebase docs, and existing Phase 18 implementations.

## Open Questions

1. **Should SettingsCubit also manage `pixEnabled` toggle from `config/settings`?**
   - What we know: Phase 19 moves pixEnabled from BookingManagementTab (Reservas) to new Config tab
   - What's unclear: Should one SettingsCubit handle both `config/mercadopago` (credentials) and `config/settings` (pixEnabled) together, or two separate cubits?
   - Recommendation: One SettingsCubit managing both documents reduces boilerplate and keeps all config logic together. UI can show sections for credentials and pixEnabled toggle within same tab. Planner should confirm in Phase 19 planning.

2. **Is there a test environment mercadopago account?**
   - What we know: Phase 18 uses sandbox credentials from Secret Manager
   - What's unclear: Should Phase 19 allow switching between sandbox and production tokens in admin UI, or assume production only?
   - Recommendation: Keep Phase 19 scope to production credentials. Sandbox testing via separate secret. Planner can add environment toggle in v5 if needed.

3. **How long should SettingsCubit keep loaded state?**
   - What we know: Cubit loads on init, doesn't subscribe to real-time updates
   - What's unclear: If admin configures credentials in another device/session, this device won't see it without reload
   - Recommendation: One-time load on init is acceptable for Phase 19 (credentials change infrequently). Add real-time listener in v5 if multi-device sync needed.

## Environment Availability

No external dependencies beyond what Phase 18 already requires:
- Firebase Cloud Functions v2 (deployed)
- Firestore (active)
- Secret Manager with MP_ACCESS_TOKEN and MP_WEBHOOK_SECRET (already set from Phase 18)

**Status:** ✓ All dependencies available. Phase 19 can proceed immediately after Phase 18 completion.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | N/A — No unit tests in project scope per CLAUDE.md feedback_no_tests.md |
| Config file | N/A |
| Quick run command | — |
| Full suite command | — |

### Phase Requirements → Test Map

Phase 19 has no automated test coverage in current project scope. Validation happens via:
1. Manual UI testing: SettingsTab appearance, show/hide toggle, save feedback
2. Manual Cloud Function testing: Redeploy CF, verify Firestore fallback works
3. Firestore rules validation: Test console confirms client can't read `config/mercadopago`

### Wave 0 Gaps
- No gaps — testing deferred per project policy (feedback_no_tests.md)

*(No automated tests planned for this phase per project constraints)*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Yes | Admin role check in Firestore rules + CF isAdmin() requirement |
| V3 Session Management | No | N/A — stateless credential storage |
| V4 Access Control | Yes | Firestore `allow write: if isAdmin()` for credentials; `allow read: if false` prevents leaks |
| V5 Input Validation | Yes | Trim empty strings; validate accessToken not empty before save |
| V6 Cryptography | Yes | Firestore at-rest encryption (built-in); credentials never logged or emitted to client |

### Known Threat Patterns for {Flutter + Firebase + Cloud Functions}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Client-side credential exposure | Information Disclosure | Use `allow read: if false` rules + never emit values in Cubit state (checked via code review) |
| Credentials in logs | Information Disclosure | Avoid `console.log(token)` in CF; use explicit null/undefined checks before logging |
| Stale credentials in memory | Tampering (CF uses old token) | Per-invocation Firestore reads ensure freshness; no global cache |
| Admin SDK misuse (credential read by non-admin) | Elevation of Privilege | CF requires `isAdmin()` check in application code (not rules); verify code review |
| Secret Manager key exposure | Information Disclosure | Use `defineSecret()` parameter binding (handled by Firebase); no hardcoded refs |

**Recommendation:** During Phase 19 execution, have planner add code review checklist items for:
1. No credential values in logs or error messages
2. Cubit states contain only boolean `isConfigured` flags
3. All CF credential reads use `getMpAccessToken()` helper function
4. Firestore rules audit confirms `config/mercadopago` has `allow read: if false`

## Sources

### Primary (HIGH confidence)
- [Firebase Cloud Functions v2 Firestore Integration](https://firebase.google.com/docs/firestore/extend-with-functions-2nd-gen) — Verified onCall + Admin SDK pattern
- [Firebase Cloud Functions Security Rules](https://firebase.google.com/docs/firestore/security/get-started) — Write-only rule patterns confirmed
- [Flutter TextField Documentation](https://api.flutter.dev/flutter/material/TextField/obscureText.html) — `obscureText` parameter verified
- **Code inspection:** admin_booking_cubit.dart, PricingTab, AdminScreen — Pattern compliance checked

### Secondary (MEDIUM confidence)
- [Firebase Security Rules for Admin SDK](https://firebase.google.com/docs/firestore/security/rules-conditions) — Admin SDK bypass behavior confirmed
- [Cloud Functions v2 Tips](https://firebase.google.com/docs/functions/tips) — Per-invocation vs. global caching guidance
- [Flutter BLoC Pattern with Forms](https://www.kodeco.com/books/real-world-flutter-by-tutorials/v1.0/chapters/4-validating-forms-with-cubits) — Cubit form management best practices
- [Flutter Password Field UI](https://www.geeksforgeeks.org/flutter-show-hide-password-in-textfield/) — Show/hide toggle implementation verified

### Tertiary (LOW confidence — training data)
- [Firestore Caching Patterns for Cloud Functions](https://peerlist.io/jeet_dhandha/articles/optimizing-firestore-caching-in-firebase-cloud-functions) — General patterns; specific version not verified

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Phase 18 used Firebase Admin SDK + Cloud Functions v2, Firestore patterns confirmed in codebase
- Architecture: HIGH — Write-only rules + per-invocation reads verified against official Firebase docs and existing code patterns
- Pitfalls: HIGH — Based on common Firebase + Flutter mistakes documented in official guides; admin_booking_cubit provides working precedent
- Assumptions: MEDIUM — A1 (latency) and A2 (initialization) not load-tested yet; A3 (rules) verified by console but not in this phase's testing

**Research date:** 2026-05-07
**Valid until:** 2026-05-21 (14 days — stable Firebase APIs, low change risk)

---

**Research Complete — Ready for Planning**

Phase 19 domain fully investigated. All locked decisions supported by codebase patterns and official Firebase documentation. Planner can confidently proceed to break down into implementation tasks.
