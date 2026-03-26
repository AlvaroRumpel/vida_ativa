# Requirements: Vida Ativa

**Defined:** 2026-03-25
**Core Value:** Clientes conseguem reservar um horário de quadra em segundos, sem depender de mensagens no WhatsApp.

## v2 Requirements

Requirements for v2.0 milestone. Each maps to roadmap phases (starting at Phase 07).

### SOCIAL — Social & Compartilhamento

- [x] **SOCIAL-01**: Usuário pode ver o nome do cliente que reservou cada horário na agenda
- [x] **SOCIAL-02**: Usuário pode adicionar campo de texto livre com participantes ao confirmar reserva
- [ ] **SOCIAL-03**: Usuário pode compartilhar reserva confirmada via WhatsApp com mensagem pré-formatada (data, horário, quadra)

### PROF — Perfil

- [x] **PROF-01**: Usuário pode cadastrar número de celular no fluxo de registro
- [x] **PROF-02**: Usuário pode editar dados do perfil (nome, telefone) via BottomSheet dedicado

### ADMN — Admin (continua de ADMN-06 do v1.0)

- [x] **ADMN-07**: Admin pode alternar para visão de cliente sem sair da conta (toggle na tela de Perfil)
- [x] **ADMN-08**: Admin pode buscar usuário cadastrado e promovê-lo a administrador no painel admin
- [x] **ADMN-09**: Admin pode ver nome do cliente e participantes diretamente na listagem de reservas (sem abrir cada item)

### UI — Visual

- [ ] **UI-01**: App exibe logo e paleta de cores fornecidas pelo cliente de forma consistente em todas as telas *(⚠️ BLOQUEADO — aguardando assets do cliente)*
- [ ] **UI-02**: Agenda exibe horários com layout inspirado no Google Calendar
- [ ] **UI-03**: Ajustes gerais de UI — consistência visual, espaçamentos, tipografia e componentes em todas as telas

### OPS — Operações

- [x] **OPS-01**: Erros em produção são capturados e registrados em ferramenta de monitoramento (Firebase Crashlytics ou Sentry)

## v3 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Auth

- **AUTH-v3-01**: Login com número de telefone (OTP via SMS) — complexidade web reCAPTCHA; deferido de v1

### Notificações

- **NOTF-v3-01**: Notificação push quando reserva é confirmada/recusada
- **NOTF-v3-02**: Lembrete automático antes do horário reservado

### Booking

- **BOOK-v3-01**: Prazo mínimo de cancelamento configurável pelo admin

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Dashboard de métricas/relatórios de ocupação | Alta complexidade; pode ser v3+ |
| Pagamento online | Pagamento é presencial; fora do escopo geral |
| Múltiplas academias / multi-tenant | v1/v2 exclusivos para Academia Vida Ativa |
| App nativo iOS/Android | PWA é suficiente |
| Chat / mensagens entre usuário e admin | WhatsApp já cobre isso |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SOCIAL-01 | Phase 07 | Complete |
| SOCIAL-02 | Phase 07 | Complete |
| ADMN-09 | Phase 07 | Complete |
| SOCIAL-03 | Phase 08 | Pending |
| PROF-01 | Phase 08 | Complete |
| PROF-02 | Phase 08 | Complete |
| ADMN-07 | Phase 09 | Complete |
| ADMN-08 | Phase 09 | Complete |
| OPS-01 | Phase 10 | Complete |
| UI-02 | Phase 11 | Pending |
| UI-03 | Phase 11 | Pending |
| UI-01 | Phase 12 | Pending (BLOCKED) |

**Coverage:**
- v2 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-25*
*Last updated: 2026-03-25 — Traceability updated after roadmap v2.0 creation*
