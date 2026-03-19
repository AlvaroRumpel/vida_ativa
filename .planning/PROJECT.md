# Vida Ativa

## What This Is

PWA de agendamento de quadra de areia (futevôlei/vôlei de praia) para a Academia Vida Ativa. Substitui o gerenciamento de reservas feito por listas no WhatsApp, permitindo que clientes vejam horários disponíveis e reservem pelo celular, enquanto admins controlam a agenda e confirmam reservas.

## Core Value

Clientes conseguem reservar um horário de quadra em segundos, sem depender de mensagens no WhatsApp.

## Requirements

### Validated

- ✓ Projeto Flutter Web criado com suporte a PWA — existente
- ✓ Firebase inicializado (firebase_options.dart gerado) — existente
- ✓ Dependências instaladas: firebase_core, firebase_auth, cloud_firestore — existente
- ✓ main.dart inicializa Firebase corretamente — existente

### Active

- [ ] Usuário pode fazer login com Google ou número de telefone
- [ ] Usuário pode visualizar horários disponíveis para reserva na semana
- [ ] Usuário pode reservar um horário disponível
- [ ] Usuário pode cancelar sua própria reserva
- [ ] Sistema impede dupla reserva no mesmo slot/dia
- [ ] Admin pode criar e gerenciar slots recorrentes (dia da semana + horário + preço)
- [ ] Admin pode bloquear datas específicas (feriados, manutenção, etc.)
- [ ] Admin pode visualizar todas as reservas
- [ ] Admin pode confirmar ou recusar reservas pendentes
- [ ] Fluxo de confirmação de reserva é configurável (automático ou requer aprovação do admin)
- [ ] App é instalável como PWA no celular

### Out of Scope

- Pagamento online — pagamento é presencial; app gerencia só o agendamento
- Múltiplas academias — v1 é exclusivo para a Academia Vida Ativa
- Notificações push — pode entrar em v2
- App nativo (iOS/Android) — PWA é suficiente para v1
- Chat ou mensagens entre usuários e admins

## Context

- Stack: Flutter Web, Firebase Auth (Google + Phone), Cloud Firestore, Firebase Hosting
- Modelo de dados já definido: `/users`, `/slots`, `/bookings`, `/blockedDates`
- Slots são recorrentes (ex: toda segunda às 08h); bookings são instâncias para uma data específica
- Perfis: `client` (reserva) e `admin` (gerencia)
- Estrutura de pastas planejada: `lib/features/{auth,schedule,booking,admin}` + `lib/core/{models,services}`
- FlutterFire já configurado com `firebase_options.dart` gerado

## Constraints

- **Stack**: Flutter Web / Firebase — já decidido e configurado
- **Plataforma**: PWA only para v1 — web-first, mobile via browser/instalação
- **Pagamento**: Fora do escopo — só agendamento

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flutter Web como PWA | Academia já usa dispositivos variados; PWA evita app store | — Pending |
| Firebase Auth com Google + Phone | Clientes têm Google; Phone Auth como fallback sem email | — Pending |
| Confirmação de reserva configurável | Academia pode querer aprovação manual no início, depois automatizar | — Pending |
| Slots recorrentes + bookings por data | Separa a configuração do horário da instância de reserva | — Pending |

---
*Last updated: 2026-03-19 after initialization*
