# Roadmap: Vida Ativa

## Milestones

- ✅ **v1.0 MVP** — Phases 1–6 (shipped 2026-03-23)
- 🔄 **v2.0 Funcionalidades Sociais & Admin** — Phases 7–12 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1–6) — SHIPPED 2026-03-23</summary>

- [x] **Phase 1: Foundation** - Data models, Firebase wiring, PWA manifest, Firestore security rules bootstrap, go_router + BLoC structural setup (completed 2026-03-19)
- [x] **Phase 2: Auth** - Google Sign-In and email/password auth, route scaffold with role-based guards, persistent session (completed 2026-03-20)
- [x] **Phase 3: Schedule** - Read-only weekly slot display with available/booked/blocked states and price display (completed 2026-03-20)
- [x] **Phase 4: Booking** - Reserve a slot (atomic transaction), cancel own booking, view my bookings (completed 2026-03-20)
- [x] **Phase 5: Admin** - Slot CRUD, blocked dates, booking list with confirm/reject, configurable approval mode (completed 2026-03-23)
- [x] **Phase 6: PWA Hardening** - Final security rules deploy, service worker update strategy, iOS install banner, production deployment (completed 2026-03-23)

Full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

### v2.0 Funcionalidades Sociais & Admin

- [x] **Phase 7: Visibilidade Social** - Reservas visíveis na agenda para todos os usuários; campo de participantes; admin vê participantes na listagem (completed 2026-03-25)
- [ ] **Phase 8: Compartilhamento & Perfil** - Compartilhar reserva via WhatsApp; campo de telefone no cadastro e edição de perfil
- [ ] **Phase 9: Gestão de Usuários Admin** - Toggle admin/cliente sem troca de conta; promoção de usuários a admin pelo painel
- [ ] **Phase 10: Monitoramento de Erros** - Captura e registro de erros em produção via ferramenta de monitoramento
- [ ] **Phase 11: Melhorias Visuais** - Agenda com layout Google Calendar; ajustes gerais de UI (espaçamentos, tipografia, consistência)
- [ ] **Phase 12: Rebrand Visual** - Logo e paleta de cores do cliente aplicados em todas as telas *(BLOQUEADO — aguardando assets do cliente)*

## Phase Details

### Phase 7: Visibilidade Social
**Goal**: Usuários podem ver quem reservou cada horário e informar com quem vão jogar
**Depends on**: Phase 6 (regras de segurança do Firestore precisam ser atualizadas para permitir leitura de bookings por usuários autenticados)
**Requirements**: SOCIAL-01, SOCIAL-02, ADMN-09
**Success Criteria** (what must be TRUE):
  1. Cliente que abre a agenda vê o nome do reservante em cada slot ocupado, sem precisar ser admin
  2. Ao confirmar uma reserva, cliente pode opcionalmente adicionar um campo de texto listando participantes (ex: "João, Maria, Pedro")
  3. Admin que abre a listagem de reservas vê nome do cliente e participantes diretamente na linha, sem precisar abrir cada item
  4. Regras de segurança do Firestore permitem leitura de bookings por qualquer usuário autenticado (não apenas admin)
**Plans:** 2/2 plans complete
Plans:
- [ ] 07-01-PLAN.md — Data layer (BookingModel participants + SlotViewModel bookerName) + schedule display (SOCIAL-01)
- [ ] 07-02-PLAN.md — UI wiring: participants input in booking sheet, edit in MyBookings, admin display (SOCIAL-02, ADMN-09)

### Phase 8: Compartilhamento & Perfil
**Goal**: Usuários podem compartilhar reservas via WhatsApp e manter dados de contato atualizados no perfil
**Depends on**: Phase 7 (compartilhamento usa dados da reserva; SOCIAL-02 adiciona participantes que aparecem na mensagem)
**Requirements**: SOCIAL-03, PROF-01, PROF-02
**Success Criteria** (what must be TRUE):
  1. Após reserva confirmada, cliente vê botão "Compartilhar" que abre WhatsApp com mensagem pré-formatada contendo data, horário e quadra
  2. Durante o cadastro com email/senha, cliente pode inserir número de celular (campo opcional)
  3. Na tela de Perfil, cliente pode abrir um BottomSheet para editar nome e telefone e salvar as alterações
**Plans:** 2 plans
Plans:
- [ ] 08-01-PLAN.md — PhoneInputFormatter + AuthCubit phone support + RegisterScreen phone field (PROF-01, PROF-02)
- [ ] 08-02-PLAN.md — WhatsApp share in BookingCard + ProfileScreen phone edit BottomSheet (SOCIAL-03, PROF-02)

### Phase 9: Gestão de Usuários Admin
**Goal**: Admin pode operar em contexto de cliente sem sair da conta e promover outros usuários no painel
**Depends on**: Phase 7 (toggle depende de roteamento por role; promoção de usuário requer leitura da coleção /users)
**Requirements**: ADMN-07, ADMN-08
**Success Criteria** (what must be TRUE):
  1. Admin logado vê toggle "Visão Cliente / Visão Admin" na tela de Perfil e pode alternar entre os dois modos sem fazer logout
  2. No modo cliente, admin enxerga exatamente o que um cliente vê — sem acesso ao painel admin
  3. No painel admin, existe tela para buscar usuário cadastrado por nome ou email e promovê-lo a administrador com um clique
**Plans**: TBD

### Phase 10: Monitoramento de Erros
**Goal**: Erros em produção são capturados automaticamente e ficam acessíveis para diagnóstico
**Depends on**: Nothing (pode ser implementado em qualquer fase; nenhuma dependência de feature)
**Requirements**: OPS-01
**Success Criteria** (what must be TRUE):
  1. Quando uma exceção não tratada ocorre no app em produção, ela aparece registrada no painel de monitoramento (Firebase Crashlytics ou Sentry)
  2. Erros incluem contexto suficiente (stack trace, plataforma, versão do app) para diagnóstico sem reprodução manual
**Plans**: TBD

### Phase 11: Melhorias Visuais
**Goal**: Agenda tem layout baseado em Google Calendar e a UI geral está visualmente consistente
**Depends on**: Phase 7, Phase 8 (agenda exibe dados sociais; ajustes de UI cobrem telas adicionadas nas fases anteriores)
**Requirements**: UI-02, UI-03
**Success Criteria** (what must be TRUE):
  1. A tela de agenda exibe slots em colunas verticais por hora no estilo Google Calendar, com navegação por dias visível
  2. Todas as telas do app usam espaçamentos, tipografia e componentes visuais consistentes entre si
  3. Nenhuma tela apresenta overflow, texto cortado ou botões fora de alinhamento em telas mobile comuns (375px e 390px de largura)
**Plans**: TBD

### Phase 12: Rebrand Visual
**Goal**: App exibe identidade visual oficial do cliente (logo + paleta de cores) de forma consistente em todas as telas
**Depends on**: Phase 11 (ajustes de UI devem estar concluídos antes de aplicar nova paleta; evita retrabalho duplo)
**Requirements**: UI-01
**Success Criteria** (what must be TRUE):
  1. O logo fornecido pelo cliente aparece na splash screen, no app bar e na tela de login
  2. A paleta de cores do cliente substitui os tokens de cor atuais (AppTheme) em todas as telas sem regressão visual
  3. App instalado como PWA exibe o ícone correto (logo do cliente) na tela inicial do dispositivo

**⚠️ BLOQUEADO** — aguardando assets do cliente (logo + paleta de cores). Esta fase não pode ser iniciada até o cliente fornecer os arquivos.
**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | 2/2 | Complete | 2026-03-19 |
| 2. Auth | v1.0 | 3/3 | Complete | 2026-03-20 |
| 3. Schedule | v1.0 | 2/2 | Complete | 2026-03-20 |
| 4. Booking | v1.0 | 2/2 | Complete | 2026-03-20 |
| 5. Admin | v1.0 | 2/2 | Complete | 2026-03-23 |
| 6. PWA Hardening | v1.0 | 2/2 | Complete | 2026-03-23 |
| 7. Visibilidade Social | 2/2 | Complete   | 2026-03-25 | - |
| 8. Compartilhamento & Perfil | v2.0 | 0/2 | Not started | - |
| 9. Gestão de Usuários Admin | v2.0 | 0/? | Not started | - |
| 10. Monitoramento de Erros | v2.0 | 0/? | Not started | - |
| 11. Melhorias Visuais | v2.0 | 0/? | Not started | - |
| 12. Rebrand Visual | v2.0 | 0/? | BLOCKED | - |
