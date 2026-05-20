# Requirements: Vida Ativa

**Defined:** 2026-05-19
**Core Value:** Clientes conseguem reservar um horário de quadra em segundos, sem depender de mensagens no WhatsApp.

## v5.0 Requirements

### Dashboard — Métricas Core

- [ ] **DASH-01**: Admin vê taxa de ocupação (% slots reservados) com toggle de período semana/mês/ano
- [ ] **DASH-02**: Admin vê receita total confirmada e split Pix vs presencial por período selecionado
- [ ] **DASH-03**: Admin vê ticket médio por reserva e taxa de conversão (reserva criada → pagamento confirmado) por período
- [ ] **DASH-04**: Admin vê no-show rate de reservas com pagamento on_arrival por período

### Dashboard — Visualizações

- [ ] **DASH-05**: Admin vê gráfico de linha ou barra com evolução de receita ao longo do período selecionado
- [ ] **DASH-06**: Admin vê heatmap hora×dia mostrando volume de reservas por combinação de horário e dia da semana
- [ ] **DASH-07**: Admin vê gráfico pizza com breakdown de reservas por status (confirmadas, canceladas, expiradas, recusadas)
- [ ] **DASH-08**: Admin vê gráfico donut com distribuição de reservas por esporte (exibido quando campo de esporte tem dados)

### Dashboard — Clientes

- [ ] **DASH-09**: Admin vê total de clientes únicos ativos e novos no período selecionado
- [ ] **DASH-10**: Admin vê top 5 clientes mais frequentes com nome e número de reservas no período
- [ ] **DASH-11**: Admin vê taxa de retorno (% clientes que reservaram mais de uma vez no período)
- [ ] **DASH-12**: Admin vê receita gerada por esporte no período selecionado

### Campo de Esporte na Reserva

- [x] **SPORT-01**: Cliente pode selecionar esporte opcional ao criar reserva via dropdown
- [ ] **SPORT-02**: Admin pode gerenciar lista de esportes nas configurações (adicionar, remover, reordenar)
- [x] **SPORT-03**: Sistema inicializa lista de esportes com padrão: Vôlei, Beach Tênis, Futevôlei
- [x] **SPORT-04**: Reservas existentes sem campo de esporte continuam funcionando normalmente (campo nullable, sem quebra)

## Futuro (v6.0+)

### Dashboard Avançado

- **DASH-F01**: Admin pode exportar dados de dashboard em CSV
- **DASH-F02**: Dashboard com atualização em tempo real via FCM listener
- **DASH-F03**: Filtros avançados por esporte, cliente específico, faixa de preço

### Notificações de Cliente

- **NOTF-F01**: Cliente recebe push notification quando reserva confirmada ou recusada
- **NOTF-F02**: Cliente recebe lembrete automático antes do horário reservado

## Out of Scope

| Feature | Reason |
|---------|--------|
| Previsão/ML de demanda | Prematura para volume atual; dados insuficientes |
| Dashboard por cliente (self-service) | Complexidade; admin suficiente por ora |
| Relatório de auditoria de pagamentos | Mercado Pago tem dashboard próprio |
| Múltiplos preços por esporte | Requer refactor de SlotModel; v6+ |
| Cores configuráveis por esporte | Baixa prioridade; padrão suficiente |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DASH-01 | Phase 21 | Pending |
| DASH-02 | Phase 21 | Pending |
| DASH-03 | Phase 21 | Pending |
| DASH-04 | Phase 21 | Pending |
| DASH-05 | Phase 22 | Pending |
| DASH-06 | Phase 22 | Pending |
| DASH-07 | Phase 22 | Pending |
| DASH-08 | Phase 22 | Pending |
| DASH-09 | Phase 21 | Pending |
| DASH-10 | Phase 21 | Pending |
| DASH-11 | Phase 21 | Pending |
| DASH-12 | Phase 21 | Pending |
| SPORT-01 | Phase 20 | Complete |
| SPORT-02 | Phase 20 | Pending |
| SPORT-03 | Phase 20 | Complete |
| SPORT-04 | Phase 20 | Complete |

**Coverage:**
- v5.0 requirements: 16 total
- Mapped to phases: 16 ✓
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-19*
*Last updated: 2026-05-19 after roadmap v5.0 created*
