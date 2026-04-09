# Requirements: v4.0 — Pagamento Pix

**Active milestone:** v4.0
**Defined:** 2026-04-06
**Full requirements:** `.planning/milestones/v4.0-REQUIREMENTS.md`
**Core Value:** Clientes pagam a reserva diretamente via Pix no app, sem depender de confirmação manual de pagamento.

---

## v4.0 Requirements

### Pagamento Pix

- [x] **PIX-01**: Na confirmação de reserva, app exibe QR code Pix + código copia-e-cola gerado pelo gateway (Mercado Pago)
- [x] **PIX-02**: Reserva criada fica em status `pending_payment`; slot permanece bloqueado durante janela de pagamento (30 min)
- [ ] **PIX-03**: App exibe timer de expiração do QR code; após expirar, exibe botão para regenerar novo QR sem precisar refazer a reserva
- [x] **PIX-04**: Cloud Function recebe webhook do Mercado Pago, verifica assinatura, processa de forma idempotente e atualiza status da reserva para `confirmed` ou `expired` — pagamento confirmado implica reserva confirmada independentemente do modo de aprovação configurado pelo admin
- [ ] **PIX-05**: Cliente vê status de pagamento em tempo real em "Minhas Reservas" — atualiza automaticamente quando pagamento é confirmado
- [x] **PIX-06**: Admin vê status de pagamento na listagem de reservas e no detalhe (bottomsheet); pode confirmar manualmente em caso de falha no webhook
- [x] **PIX-07**: Reservas com pagamento expirado são automaticamente marcadas como `expired` por Cloud Function após 45 min; slot liberado para nova reserva

---

## v5.0+ (Fora do escopo atual)

- Feature toggles / modularização por academia — complexidade de plugin system; defer para quando houver segundo cliente real
- Cartão de crédito/débito
- Pix Parcelado (lançamento BCB junho 2026)
- Relatório de pagamentos por período

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| Feature toggles v4.0 | Arquitetura Lego real é semanas de trabalho; defer para v5+ |
| Cartão de crédito/débito | Pix é suficiente para o mercado BR agora |
| Pagamento no approve admin | Quebra o fluxo UX; pagamento deve ser imediato |
| Pix Parcelado | Muito novo (BCB junho 2026); defer |

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PIX-01 | Phase 17 | Complete |
| PIX-02 | Phase 17 | Complete |
| PIX-03 | Phase 18 | Pending |
| PIX-04 | Phase 18 | Complete |
| PIX-05 | Phase 18 | Pending |
| PIX-06 | Phase 18 | Complete |
| PIX-07 | Phase 18 | Complete |

**Coverage:**
- v4.0 requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-06*
*Traceability updated: 2026-04-06 (roadmap created)*
