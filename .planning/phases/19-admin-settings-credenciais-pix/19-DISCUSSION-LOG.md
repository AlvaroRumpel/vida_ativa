# Phase 19: Admin Settings + Credenciais Pix - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-07
**Phase:** 19-admin-settings-credenciais-pix
**Mode:** --auto (all decisions auto-selected)
**Areas discussed:** Settings Location, Credential Fields, Security UX, Kill Switch, CF Credentials Source, Firestore Rules

---

## Settings Location

| Option | Description | Selected |
|--------|-------------|----------|
| Nova aba "Config" no AdminScreen | Consistente com padrão de tabs existente; 5→6 tabs | ✓ |
| Tela separada (nova rota) | Mais espaço, mas quebra o padrão de navegação do admin | |

**Auto-selected:** Nova aba "Config" no AdminScreen
**Notes:** Mantém consistência com padrão existente de tabs no admin.

---

## Credential Fields

| Option | Description | Selected |
|--------|-------------|----------|
| Apenas accessToken | Simples, mas sem webhook secret o app não valida pagamentos | |
| accessToken + webhookSecret | Ambos necessários para Pix funcionar end-to-end | ✓ |

**Auto-selected:** accessToken + webhookSecret
**Notes:** Ambos campos necessários para funcionamento completo.

---

## Security UX

| Option | Description | Selected |
|--------|-------------|----------|
| Campo de texto normal | Token visível — inseguro em tela compartilhada | |
| Campo mascarado + show/hide + sem leitura de volta | Token nunca retorna ao client; placeholder "••••••••" se já definido | ✓ |

**Auto-selected:** Campo mascarado + show/hide + sem leitura de volta
**Notes:** Máxima segurança: cliente Flutter nunca recebe o token de volta do Firestore.

---

## Kill Switch Integration

| Option | Description | Selected |
|--------|-------------|----------|
| Manter em Reservas tab | Sem mudança — menor impacto | |
| Mover para Config tab | Agrupa toda config Pix num lugar lógico | ✓ |

**Auto-selected:** Mover para Config tab
**Notes:** Lógico agrupar pixEnabled com as credenciais MP.

---

## CF Credentials Source

| Option | Description | Selected |
|--------|-------------|----------|
| Apenas Firestore | Quebra quem já tem Secret Manager configurado | |
| Firestore primário + Secret Manager fallback | Compatibilidade retroativa + nova UX | ✓ |
| Apenas Secret Manager | Não resolve o problema original | |

**Auto-selected:** Firestore primário + Secret Manager fallback
**Notes:** Admin pode configurar via UI; quem já tem Secret Manager continua funcionando.

---

## Claude's Discretion

- Layout visual da aba Config
- Nome exato: "Config" vs "Configurações"
- Cubit/state design da aba de configurações

## Deferred Ideas

- Validação do token contra API MP antes de salvar
- Multi-tenant / múltiplas academias
- Audit log de alterações de credenciais
