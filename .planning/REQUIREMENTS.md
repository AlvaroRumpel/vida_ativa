# Requirements — v6.0 Arena Esportivo — Redesign Visual

## Milestone Goal

Implementar a nova identidade visual esportiva em todas as telas do app, eliminando o "ar de IA" atual e aplicando o design system Arena Esportivo aprovado via claude.ai/design.

---

## Design System Foundation

- [ ] **DS-01**: AppTheme implementa paleta sport completa (sand, ink, orange, court, sun, line, lineHair, concrete) substituindo paleta verde/dourado atual
- [ ] **DS-02**: AppTheme configura tipografia com 3 famílias: Anton (display/horários), Manrope (UI), JetBrains Mono (eyebrows/preços/labels mono)
- [ ] **DS-03**: AppTheme expõe helpers estáticos `display()`, `ui()`, `mono()` para uso consistente em widgets
- [ ] **DS-04**: Tema material (colorScheme, tabBarTheme, navigationBarTheme, cardTheme, filledButtonTheme, inputDecorationTheme, switchTheme, snackBarTheme, FAB) atualizado com novos tokens

## Navegação

- [ ] **NAV-01**: Bottom navigation bar exibe ícones e labels em estilo sport (cor orange para selecionado, concrete para idle, fonte mono uppercase)
- [ ] **NAV-02**: Bottom navigation bar usa fundo sand com borda superior hairline (sem elevação/sombra)

## Tela de Agenda (Cliente)

- [ ] **SCHED-04**: Day selector substituído por tira horizontal com colunas (abreviação mono + número Anton), ativo marcado com underline laranja 2px
- [ ] **SCHED-05**: Slot rows usam layout hairline (sem Card): horário em Anton 42px, faixa lateral laranja 3px para "minha reserva", opacity 0.45 para reservado por outro
- [ ] **SCHED-06**: Cabeçalho da agenda exibe wordmark "VIDA ATIVA" (Anton + pílula laranja) e eyebrow mono com data do dia selecionado

## Tela de Confirmação de Reserva

- [ ] **BOOK-07**: Hora do slot exibida em Anton 88px como elemento principal (sem bloco preto/hero card sólido)
- [ ] **BOOK-08**: Linha lateral laranja 2px substitui banner/box de aviso de aprovação manual
- [ ] **BOOK-09**: Botões "Pagar com Pix" e "Pagar na hora" em SportBtn (Anton uppercase, rounded, sem quebra de texto)

## Tela Minhas Reservas

- [ ] **BOOK-10**: Seção "Próximo" exibe horário em Anton 72px com eyebrow laranja "Próximo · hoje" (sem hero block preto)
- [ ] **BOOK-11**: Demais reservas em rows hairline: data como Anton 30px + eyebrow mono, horário em Anton 26px, status como pill quiet
- [ ] **BOOK-12**: Section headers em JetBrains Mono uppercase tracked (Em seguida / Histórico)

## Painel Admin — Estrutura

- [ ] **ADMN-13**: AdminScreen TabBar usa underline laranja 2px (sem fundo colorido), labels em JetBrains Mono uppercase, fundo sand
- [ ] **ADMN-14**: AdminScreen header exibe wordmark + eyebrow "Painel admin" + link "cliente →" em mono laranja
- [ ] **ADMN-15**: Notification banner usa faixa lateral laranja 2px (sem container colorido de fundo)

## Painel Admin — Aba Slots

- [ ] **ADMN-16**: Slot rows em layout hairline: horário em Anton 32px (laranja se reservado), nome do reservante em Manrope, switch sport para toggle ativo/inativo
- [ ] **ADMN-17**: Day selector da aba Slots usa mesmo padrão underline laranja com navegação ← →

## Painel Admin — Aba Reservas

- [ ] **ADMN-18**: Booking rows exibem horário em Anton 36px, nome + participantes em Manrope, status em mono uppercase colorido
- [ ] **ADMN-19**: Ações "Confirmar/Recusar" como pills ink/quiet (sem botões com fundo colorido)

## Painel Admin — Aba Usuários

- [ ] **ADMN-20**: Avatar circular: laranja para admin, ink para usuário comum (sem gradiente/múltiplas cores)
- [ ] **ADMN-21**: Rows hairline com nome em Manrope bold, email em mono, contador de reservas em mono

## Painel Admin — Aba Preços

- [ ] **ADMN-22**: Faixas de preço em layout hairline: horário em Anton 30px, timeline como barra 3px laranja sobre fundo lineHair, preço em Anton 44px
- [ ] **ADMN-23**: Botão "Salvar tabela" em SportBtn ink fixado no rodapé

## Painel Admin — Aba Ajustes

- [ ] **ADMN-24**: Toggle Pix em Switch sport (laranja/cinza), labels em mono uppercase
- [ ] **ADMN-25**: Campos de credencial Mercado Pago como underline fields em mono com ícone de olho

## Painel Admin — Dashboard

- [ ] **ADMN-26**: KPI cards em grid 2×N com hairlines (sem cards com sombra): valor em Anton 32px, delta em mono colorido (court/orangeDk), sparkline SVG
- [ ] **ADMN-27**: Gráfico de barras de receita: barras simples sem bordas arredondadas, labels em mono
- [ ] **ADMN-28**: Heatmap de ocupação usa escala de intensidade laranja (`rgba(255,77,23, α)`) em vez de calendário
- [ ] **ADMN-29**: Receita por esporte: barra de progresso hairline 3px laranja, valores em Anton + mono

---

## Future Requirements (deferred)

- Tela de Login redesenhada (wordmark sport, inputs underline) — v7+
- Tela de Perfil redesenhada — v7+
- Dark mode (ink como fundo, paper como superfície) — v7+
- Animações de transição entre telas — v7+

## Out of Scope

- Mudança de funcionalidade ou lógica de negócio — apenas visual
- Redesign do fluxo de pagamento Pix (PixPaymentScreen) — mantém layout atual
- Novos componentes de UI não presentes no design aprovado
- Alteração de modelos de dados ou Cloud Functions

---

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| DS-01..04 | — | pending |
| NAV-01..02 | — | pending |
| SCHED-04..06 | — | pending |
| BOOK-07..12 | — | pending |
| ADMN-13..29 | — | pending |
