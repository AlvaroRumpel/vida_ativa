# Requirements: Vida Ativa

**Defined:** 2026-03-19
**Core Value:** Clientes conseguem reservar um horário de quadra em segundos, sem depender do WhatsApp.

## v1 Requirements

### Authentication

- [x] **AUTH-01**: Usuário pode fazer login com conta Google
- [x] **AUTH-02**: Usuário pode fazer login com email e senha
- [x] **AUTH-03**: Usuário pode criar conta com email e senha
- [x] **AUTH-04**: Usuário pode recuperar senha via link enviado por email
- [x] **AUTH-05**: Sessão do usuário persiste entre sessões do browser

### Schedule (Agenda)

- [x] **SCHED-01**: Usuário pode visualizar horários disponíveis e ocupados organizados por semana
- [x] **SCHED-02**: Usuário pode selecionar um dia para ver os slots daquele dia
- [x] **SCHED-03**: Preço do slot é exibido na listagem de horários

### Booking (Reservas)

- [x] **BOOK-01**: Usuário pode reservar um horário disponível (transação atômica — sem double booking)
- [x] **BOOK-02**: Usuário pode cancelar sua própria reserva
- [x] **BOOK-03**: Usuário pode ver suas reservas futuras e passadas

### Admin

- [ ] **ADMN-01**: Admin pode criar e editar slots recorrentes (dia da semana + horário + preço)
- [ ] **ADMN-02**: Admin pode desativar um slot recorrente sem excluí-lo
- [ ] **ADMN-03**: Admin pode bloquear datas específicas (feriados, manutenção, eventos)
- [ ] **ADMN-04**: Admin pode ver todas as reservas filtradas por data
- [ ] **ADMN-05**: Admin pode confirmar ou recusar reservas pendentes
- [ ] **ADMN-06**: Admin pode configurar o modo de confirmação (automático ou aprovação manual)

### PWA & Infrastructure

- [x] **PWA-01**: App é instalável no celular como PWA (manifest.json, ícones, service worker)
- [x] **PWA-02**: Interface é responsiva e projetada mobile-first
- [x] **INFRA-01**: Regras de segurança do Firestore implementadas e deployadas antes de dados reais
- [x] **INFRA-02**: Modelos de dados (UserModel, SlotModel, BookingModel, BlockedDateModel) implementados com serialização Firestore

## v2 Requirements

### Authentication

- **AUTH-v2-01**: Login com número de telefone (OTP via SMS)

### Booking

- **BOOK-v2-01**: Prazo mínimo de cancelamento configurável pelo admin (ex: 2h antes)
- **BOOK-v2-02**: Confirmação de reserva por notificação push

### Admin

- **ADMN-v2-01**: Admin pode ver histórico de cancelamentos
- **ADMN-v2-02**: Relatório de ocupação por período

### Notifications

- **NOTF-v2-01**: Notificação push ao cliente quando reserva é confirmada/recusada
- **NOTF-v2-02**: Lembrete automático antes do horário reservado

## Out of Scope

| Feature | Reason |
|---------|--------|
| Pagamento online | Pagamento é presencial; fora do escopo explícito |
| Múltiplas academias / multi-tenant | v1 é exclusivo para Academia Vida Ativa |
| Chat / mensagens entre usuário e admin | WhatsApp já cobre isso; não justifica complexidade |
| App nativo iOS/Android | PWA é suficiente para v1 |
| Ver nome de outros clientes no slot | Privacidade — cliente não precisa saber quem reservou |
| Suporte offline completo | Firestore web persistence conflita com booking transactions; deferido |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INFRA-01 | Phase 1 | Complete |
| INFRA-02 | Phase 1 | Complete |
| PWA-01 | Phase 1 | Complete |
| PWA-02 | Phase 1 | Complete |
| AUTH-01 | Phase 2 | Complete |
| AUTH-02 | Phase 2 | Complete |
| AUTH-03 | Phase 2 | Complete |
| AUTH-04 | Phase 2 | Complete |
| AUTH-05 | Phase 2 | Complete |
| SCHED-01 | Phase 3 | Complete |
| SCHED-02 | Phase 3 | Complete |
| SCHED-03 | Phase 3 | Complete |
| BOOK-01 | Phase 4 | Complete |
| BOOK-02 | Phase 4 | Complete |
| BOOK-03 | Phase 4 | Complete |
| ADMN-01 | Phase 5 | Pending |
| ADMN-02 | Phase 5 | Pending |
| ADMN-03 | Phase 5 | Pending |
| ADMN-04 | Phase 5 | Pending |
| ADMN-05 | Phase 5 | Pending |
| ADMN-06 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 21 total
- Mapped to phases: 21
- Unmapped: 0 ✓
- Phase 6 (PWA Hardening) finalizes Phase 1 deliverables (INFRA-01, PWA-01) — no additional requirement ownership

---
*Requirements defined: 2026-03-19*
*Last updated: 2026-03-20 after Phase 2 completion*
