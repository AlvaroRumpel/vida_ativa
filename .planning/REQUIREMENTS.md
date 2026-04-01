# Requirements: v3.0 — Aprimoramentos de Reserva & Notificações

**Active milestone:** v3.0
**Full requirements:** `.planning/milestones/v3.0-REQUIREMENTS.md`

---

## v3.0 Requirements

### Phase 13: Admin Semana Contextualizada

- [x] **ADMN-10**: Admin vê label da semana atual (ex: "31 mar – 6 abr") na aba Slots e pode navegar ← → entre semanas; day chips exibem data real (ex: "Seg 01")
- [x] **ADMN-11**: Admin pode tocar em qualquer reserva (aba Reservas ou aba Slots) e abrir bottomsheet com detalhe completo: nome do cliente, status, horário, preço, participantes + ações confirmar/recusar

### Phase 14: Detalhe de Reserva (Cliente) + Aviso de Pagamento

- [x] **BOOK-04**: Cliente pode tocar em qualquer reserva em "Minhas Reservas" e abrir bottomsheet com detalhe: data, horário, preço, participantes, status — com ações cancelar e compartilhar
- [x] **BOOK-06**: Na tela de confirmação de reserva, exibir aviso explícito de que a reserva só será confirmada mediante pagamento (banner/disclaimer visual)

### Phase 15: Agendamento Recorrente

- [ ] **BOOK-05**: Cliente pode criar reserva recorrente: seleciona padrão semanal + data de término; app cria todas as reservas individualmente; conflitos (slot já reservado) são exibidos em lista e ignorados silenciosamente

### Phase 16: Push Notifications Admin

- [ ] **NOTF-01**: Admin recebe web push notification (FCM) quando uma nova reserva é criada; requer permissão do browser; funciona com app em background via service worker

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ADMN-10 | Phase 13 | Complete |
| ADMN-11 | Phase 13 | Complete |
| BOOK-04 | Phase 14 | Complete |
| BOOK-06 | Phase 14 | Complete |
| BOOK-05 | Phase 15 | Pending |
| NOTF-01 | Phase 16 | Pending |

---

*Requirements defined: 2026-03-31*
