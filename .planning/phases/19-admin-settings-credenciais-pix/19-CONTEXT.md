# Phase 19: Admin Settings + Credenciais Pix - Context

**Gathered:** 2026-05-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Tela de configurações no painel admin com gerenciamento de credenciais Mercado Pago (Access Token + Webhook Secret) armazenadas no Firestore de forma segura. Cloud Functions atualizam para ler credenciais do Firestore como fonte primária. Kill switch Pix migrado para a aba de configurações.

</domain>

<decisions>
## Implementation Decisions

### Settings Location
- **D-01:** Nova aba "Config" (ou "Configurações") adicionada ao TabBar existente no AdminScreen — padrão de tabs já estabelecido nas fases anteriores. Total: 6 tabs.
- **D-02:** Kill switch `pixEnabled` movido da aba "Reservas" para a aba "Config" — agrupamento lógico de toda configuração Pix num só lugar.

### Campos de Credenciais
- **D-03:** Dois campos na UI: `accessToken` (MP Access Token de produção) e `webhookSecret` (MP Webhook Secret). Ambos necessários para Pix funcionar end-to-end.
- **D-04:** Campos opcionais individualmente — admin pode salvar sem preencher os dois. Status de "configurado" exibido por campo (ex: checkmark verde se já definido).

### Segurança de Credenciais — UX
- **D-05:** Campos renderizados como `obscureText: true` (password field) com botão show/hide.
- **D-06:** Ao carregar a tela, se credencial já está definida no Firestore, campo mostra placeholder "••••••••" e não retorna o valor real ao cliente. O admin digita novo valor apenas para atualizar.
- **D-07:** Botão "Salvar" separado por seção. Ao salvar, cubit escreve no Firestore — nunca lê de volta o token para o estado Flutter.

### Firestore — Estrutura e Regras
- **D-08:** Documento: `config/mercadopago` com campos `{ accessToken: string, webhookSecret: string, updatedAt: timestamp }`.
- **D-09:** Regras de segurança: `allow read: if false` para todos os clients (incluindo admin via Flutter). `allow write: if isAdmin()` para admin escrever. Cloud Functions usam admin SDK — regras não se aplicam.
- **D-10:** Campo separado `config/settings` (já existente com `pixEnabled`, `confirmationMode`) permanece intacto. Credenciais ficam em documento separado para isolamento.

### Cloud Functions — Fonte de Credenciais
- **D-11:** CFs leem de `config/mercadopago` no Firestore como fonte **primária** (via admin SDK). Se o campo estiver vazio ou o documento não existir, fazem fallback para `defineSecret('MP_ACCESS_TOKEN')` / `defineSecret('MP_WEBHOOK_SECRET')`.
- **D-12:** Funções afetadas: `createPixPayment`, `handlePixWebhook`, `expireUnpaidBookings`.
- **D-13:** Se nem Firestore nem Secret Manager tiver o token, a função retorna erro claro: `MP_ACCESS_TOKEN not configured`.

### Claude's Discretion
- Ordem e layout visual da aba Config (seções, espaçamentos, ícones).
- Nome exato da aba: "Config" vs "Configurações" (usar o que couber melhor no TabBar).
- Loading state da aba enquanto verifica se credenciais já estão definidas.
- Cubit/state design para a aba de configurações.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Firestore Config Existente
- `lib/features/admin/cubit/admin_booking_cubit.dart` — config/settings doc atual (pixEnabled, confirmationMode)
- `lib/features/admin/ui/booking_management_tab.dart` — kill switch pixEnabled atual (mover para Settings tab)

### Cloud Functions
- `functions/index.js` — createPixPayment, handlePixWebhook, expireUnpaidBookings; padrão defineSecret atual

### Admin UI Pattern
- `lib/features/admin/ui/admin_screen.dart` — TabBar com 5 tabs; adicionar 6ª aba
- `lib/features/admin/ui/pricing_tab.dart` — padrão de form tab com save button

### Segurança
- `firestore.rules` (raiz do projeto) — regras atuais; adicionar regra para config/mercadopago

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AdminScreen` TabBar: adicionar `Tab(text: 'Config')` e `SettingsTab()` no TabBarView
- `PricingTab` pattern: form em ListView com FilledButton salvar — reusar para SettingsTab
- `SnackHelper.success/error`: feedback visual já padronizado
- `AppTheme.primaryGreen`, `AppSpacing`: tema e espaçamentos consistentes
- `admin_booking_cubit.dart`: padrão de leitura/escrita em `config/settings` — replicar para `config/mercadopago`

### Established Patterns
- BLoC/Cubit: cada tab tem seu cubit fornecido via `BlocProvider`
- Firestore writes: `SetOptions(merge: true)` para atualizações parciais
- Loading states: switch/pattern match em BlocBuilder (Initial → Loading → Loaded/Error)

### Integration Points
- `admin_screen.dart` linha 30: `TabController(length: 5, ...)` → mudar para 6
- `admin_screen.dart` linha 86–95: lista de `Tab()` → adicionar Tab Config
- `admin_screen.dart` linha 124–130: lista de TabBarView children → adicionar SettingsTab
- `functions/index.js` linhas 214, 374, 563, 651: substitutos de `mpAccessToken.value()` → helper que lê Firestore primeiro

</code_context>

<specifics>
## Specific Ideas

- Admin digita token → salva → Firestore guarda → próxima chamada Pix funciona sem redeploy de CF
- Tela deve deixar claro que credencial foi salva sem revelar o valor (UX segura)
- Status visual: se `accessToken` já está definido no Firestore, mostrar indicador "Configurado" ao carregar a tela (sem retornar o valor ao client)
- O fallback para Secret Manager mantém compatibilidade para quem já fez o deploy anterior

</specifics>

<deferred>
## Deferred Ideas

- Validar token MP contra a API antes de salvar (call de teste) — complexidade extra, defer para v5
- Múltiplas academias / multi-tenant com credenciais diferentes por tenant — v5+
- Histórico de alterações de credenciais (audit log) — v5+

</deferred>

---

*Phase: 19-admin-settings-credenciais-pix*
*Context gathered: 2026-05-07*
