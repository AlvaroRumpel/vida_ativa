# 30-CHECKLIST.md — UAT Manual: Screenshot Comparison

## How to use

Abrir app em staging. Navegar para cada tela. Tirar screenshot. Conferir cada item contra o que está descrito abaixo.

---

## 1. Booking Confirmation Sheet

**Visual reference:** Sheet modal com hero de horário dominante em Anton 88px sobre fundo areia (AppTheme.sand). Sem Card elevado — fundo plano. Banner de aprovação manual como faixa laranja 2px à esquerda, sem bloco colorido de fundo. Botões SportBtn com cantos arredondados (borderRadius 999).

### Checklist

- [ ] Drag handle visível: retângulo 40×4px cinza (AppTheme.line) centrado no topo da sheet
- [ ] Eyebrow acima do horário: data em formato "QUA, 28 MAI" — fonte JetBrains Mono 11px, cor AppTheme.concrete (cinza)
- [ ] Horário em Anton 88px como elemento visualmente dominante (ex: "18:00") — cor AppTheme.ink (near-black)
- [ ] Preço abaixo do horário em JetBrains Mono 16px, cor AppTheme.concrete (ex: "R$ 90,00")
- [ ] Hairline divisor AppTheme.lineHair (0.5px) separando hero do restante da sheet
- [ ] Banner de aprovação manual (quando ativo): faixa laranja 2px na borda esquerda — NENHUM fundo colorido no restante da área
- [ ] Texto do banner: "Esta reserva será confirmada após aprovação do estabelecimento." em Manrope 13px AppTheme.ink
- [ ] Toggle "Reservar semanalmente" com Switch ao lado — sem cor personalizada no estado off
- [ ] Campo de texto "QUEM VAI JOGAR?" com borda underline (não outlined, não filled)
- [ ] Botão "PAGAR COM PIX": SportBtn filled laranja (AppTheme.orange), texto Anton uppercase
- [ ] Botão "PAGAR NA HORA": SportBtn outlined com borda AppTheme.ink, texto Anton uppercase
- [ ] Ambos os botões com borderRadius arredondado (pill shape — não quadrado)
- [ ] Quando Pix desativado: botão único "CONFIRMAR RESERVA" filled laranja

---

## 2. Pix QR Screen

**Visual reference:** Tela full com countdown urgente em laranja, QR code centralizado, código Pix em fonte mono, botão copiar outline laranja.

### Checklist

- [ ] Countdown/timer exibido em laranja (AppTheme.orange) — NÃO vermelho
- [ ] Título ou label do tempo restante em JetBrains Mono uppercase
- [ ] QR code centralizado na tela em container com fundo AppTheme.paper (creme claro)
- [ ] Código Pix copia-e-cola em JetBrains Mono — fundo paper, sem bordas arredondadas excessivas
- [ ] Botão "COPIAR CÓDIGO" em outline laranja (AppTheme.orange) com texto Anton uppercase
- [ ] Botão "CANCELAR" ou equivalente: variant quieto/concreto, sem destaque
- [ ] Fundo geral da tela: AppTheme.sand (areia — #F4EFE2) ou AppTheme.paper — não branco puro

---

## 3. Minhas Reservas (MyBookings)

**Visual reference:** Header com wordmark Arena. Primeira reserva futura como hero com Anton 72px. Eyebrow "PRÓXIMO · HOJE" em mono laranja. Demais reservas como hairline rows (sem Card elevado).

### Checklist

- [ ] Header: "VIDA" em Anton 18px ink + "ATIVA" em Anton 18px paper sobre fundo laranja — wordmark Arena correto
- [ ] Lado direito do header: "MINHAS RESERVAS" em JetBrains Mono 11px AppTheme.concrete
- [ ] Eyebrow da próxima reserva: "PRÓXIMO · HOJE" (ou "PRÓXIMO · AMANHÃ" / "PRÓXIMO · QUA") em JetBrains Mono 11px AppTheme.orange
- [ ] Horário da próxima reserva em Anton 72px AppTheme.ink como elemento dominante
- [ ] Data da próxima reserva (ex: "QUA, 28 MAI") em JetBrains Mono 11px AppTheme.concrete abaixo do horário
- [ ] Separador hairline AppTheme.lineHair (0.5px) após bloco hero
- [ ] Seção "EM SEGUIDA" quando há mais reservas: label em JetBrains Mono 10px AppTheme.concrete com hairline abaixo
- [ ] Reservas adicionais como rows finos — SEM Card elevado, SEM sombra, fundo plano
- [ ] Seção "HISTÓRICO" com label em JetBrains Mono 10px AppTheme.concrete
- [ ] Reservas passadas em rows hairline com visual dimido (sem destaque)
- [ ] Estado vazio: ícone + "Nenhuma reserva" centralizado + botão "VER AGENDA" outlined

---

## 4. Admin Frame (header + TabBar)

**Visual reference:** Wordmark Arena no canto superior esquerdo. "PAINEL ADMIN" em mono concreto. "cliente →" em mono laranja. TabBar com labels uppercase mono, indicador underline laranja 2px — sem pílulas ou fundo colorido nas tabs.

### Checklist

- [ ] Wordmark: "VIDA" em Anton 18px ink + "ATIVA" em Anton 18px paper sobre retângulo laranja (AppTheme.orange)
- [ ] Lado direito do header: "cliente →" em JetBrains Mono 11px AppTheme.orange — toque navega para tela cliente
- [ ] Segunda linha abaixo da wordmark: "PAINEL ADMIN" em JetBrains Mono 10px AppTheme.concrete
- [ ] TabBar: labels em UPPERCASE — "DASHBOARD", "SLOTS", "BLOQUEIOS", "RESERVAS", "USUÁRIOS", "PREÇOS", "AJUSTES"
- [ ] Tab ativa: indicador underline laranja 2px na base — SEM fundo colorido, SEM pílula
- [ ] Tab inativa: texto AppTheme.concrete (cinza), sem sublinhado
- [ ] TabBar scrollável horizontalmente (tabs não caem em duas linhas)
- [ ] Divisor da TabBar: hairline AppTheme.lineHair
- [ ] Banner de nova reserva (quando aparece): faixa laranja 2px esquerda + texto Manrope 13px ink + botão "Ver" mono — SEM fundo colorido de bloco
- [ ] Banner de permissão de notificação: mesmo padrão — faixa laranja 2px, sem fundo colorido

---

## 5. Admin — Aba Slots

**Visual reference:** Day selector com 7 dias + flechas de navegação. Dia selecionado com underline laranja 2px. Slot rows em grid 3 colunas: tempo Anton 32px | info central | toggle/chevron. Horário reservado em laranja. FAB laranja no canto inferior direito.

### Checklist

- [ ] Day selector: row com seta esquerda + 7 dias (SEG–DOM) + seta direita
- [ ] Dia selecionado: abreviação 3 letras (ex: "QUI") em JetBrains Mono 8px ink + data em Anton 18px ink + underline laranja 2px
- [ ] Dias não selecionados: abreviação e data em AppTheme.concrete (cinza), sem underline
- [ ] Divisor full-width AppTheme.line abaixo do day selector
- [ ] Slot row — coluna esquerda: horário em Anton 32px, cor laranja (AppTheme.orange) se reservado, ink se livre
- [ ] Slot inativo: row inteira com opacidade 0.4
- [ ] Slot reservado — coluna central: nome do cliente em Manrope 13px bold + "RESERVADO" em JetBrains Mono 10px laranja uppercase
- [ ] Slot livre — coluna central: preço em Anton ou Manrope, cor AppTheme.concrete
- [ ] Slot reservado — coluna direita: chevron ">" indicando que é tappable
- [ ] Slot livre — coluna direita: toggle Switch (ativo = laranja, inativo = AppTheme.line)
- [ ] Separador entre slots: hairline AppTheme.lineHair (0.5px)
- [ ] FAB no canto inferior direito: círculo laranja (AppTheme.orange) 52×52px com ícone "+" paper
- [ ] FAB sem sombra excessiva (esportivo limpo, não Material shadow chunky)

---

## 6. Admin — Aba Reservas

**Visual reference:** Date selector com seta + nome do dia em mono + data em Anton 24px. Toggle "Confirmar automaticamente". Booking rows com Anton 36px para horário, nome Manrope 15px bold, status em mono uppercase colorido, pills Confirmar/Recusar apenas em pendentes.

### Checklist

- [ ] Date selector: seta esquerda + dia da semana em JetBrains Mono 9.5px uppercase (ex: "QUINTA") + data em Anton 24px (ex: "13 de março") + seta direita
- [ ] Toggle "Confirmar automaticamente" com label Manrope 14px bold + subtexto "Aprovação manual ligada" em Manrope 12px concrete
- [ ] Switch do toggle: quando desligado — fundo AppTheme.line (cinza), NÃO laranja
- [ ] Divisor AppTheme.line entre toggle e lista de reservas
- [ ] Booking row — horário em Anton 36px AppTheme.ink (não laranja nesta tela)
- [ ] Booking row — nome do cliente em Manrope 15px bold, sem truncar
- [ ] Booking row — participantes (quando presentes) em Manrope 12px AppTheme.concrete abaixo do nome
- [ ] Booking row — preço alinhado à direita: "R$" em JetBrains Mono concrete + valor em Anton 22px ink
- [ ] Status "AGUARDANDO" em JetBrains Mono 10px uppercase — cor laranja (AppTheme.orange)
- [ ] Status "PIX PAGO" em JetBrains Mono 10px uppercase — cor AppTheme.court (verde)
- [ ] Status "PAGAR NA HORA" em JetBrains Mono 10px uppercase — cor AppTheme.concrete (cinza)
- [ ] Status "AGUARDANDO PIX" em JetBrains Mono 10px uppercase — cor AppTheme.orange
- [ ] Pills de ação: apenas em reservas com status "pending" (aguardando confirmação manual)
- [ ] Pill "CONFIRMAR": fundo ink sólido + texto paper — pill arredondada (radius 999)
- [ ] Pill "RECUSAR": outline AppTheme.line + texto AppTheme.concrete — pill quieta
- [ ] Separador entre rows: hairline AppTheme.lineHair (0.5px), sem Card elevado

---

## 7. Admin — Aba Usuários

**Visual reference:** Campo de busca outline arredondado. User rows em grid 3 colunas: avatar circular | nome+email | badge admin ou pill promover. Avatar laranja para admin, ink para usuário comum. Inicial do nome em Anton.

### Checklist

- [ ] Campo de busca: border outline AppTheme.line, radius 999 (pill), ícone lupa + "Buscar nome ou email" em Manrope 13px concrete
- [ ] Divisor AppTheme.line abaixo do campo de busca
- [ ] Avatar usuário comum: círculo 40×40px fundo AppTheme.ink (near-black) + inicial Anton 20px AppTheme.paper (branco)
- [ ] Avatar admin: círculo 40×40px fundo AppTheme.orange (laranja) + inicial Anton 20px AppTheme.paper (branco)
- [ ] Nome do usuário: Manrope 14px bold, truncado com "..." se muito longo
- [ ] Email: JetBrains Mono 10.5px AppTheme.concrete abaixo do nome
- [ ] Contador de reservas (quando > 0): "· N" em JetBrains Mono 10px ink ao lado do email
- [ ] Admin badge: "ADMIN" em JetBrains Mono 10px uppercase AppTheme.orange — sem fundo colorido
- [ ] Usuário comum: pill "Promover" quiet (outline AppTheme.line, texto concrete)
- [ ] Separador entre rows: hairline AppTheme.lineHair (0.5px), sem Card elevado
- [ ] Header da aba: título "USUÁRIOS" em Anton 40px + count em JetBrains Mono 11px concrete ("07")

---

## 8. Admin — Aba Preços

**Visual reference:** Lista de faixas de preço. Cada faixa: label mono concreto + horários Anton 30px com "→" entre eles + preço Anton 44px alinhado à direita + timeline bar laranja (AppTheme.orange) de 3px sobre fundo lineHair indicando período do dia. Botão "SALVAR TABELA" ink sólido no rodapé fixo.

### Checklist

- [ ] Texto descritivo no topo: "Faixas por período. Aplica automático no lote..." em Manrope 12.5px AppTheme.concrete
- [ ] Faixa row — label topo: "FAIXA 01 · SEG–SEX" (ou similar) em JetBrains Mono 9.5px AppTheme.concrete
- [ ] Faixa row — horário inicial em Anton 30px AppTheme.ink (ex: "08:00")
- [ ] Faixa row — seta "→" em Anton 20px AppTheme.concrete entre os horários
- [ ] Faixa row — horário final em Anton 30px AppTheme.ink (ex: "17:00")
- [ ] Faixa row — preço alinhado à direita: "R$" em JetBrains Mono 14px concrete + valor em Anton 44px ink (ex: "90")
- [ ] Timeline bar abaixo do horário: barra full-width 3px de altura — fundo AppTheme.lineHair (creme) + segmento laranja (AppTheme.orange) proporcional ao período da faixa
- [ ] Separador entre faixas: hairline AppTheme.lineHair (0.5px) no topo de cada row
- [ ] Faixa é tappable — nenhum indicador visual além do comportamento de clique
- [ ] Linha "ADICIONAR FAIXA" no final da lista: ícone + texto JetBrains Mono 10.5px concrete, centralizado
- [ ] Rodapé fixo: fundo AppTheme.sand com borda topo lineHair
- [ ] Botão "SALVAR TABELA" no rodapé: SportBtn filledInk — fundo AppTheme.ink (preto), texto Anton paper uppercase
- [ ] Botão de salvar ocupa largura total do rodapé (full width)

---

## 9. Admin — Aba Ajustes

**Visual reference:** Seção PIX ATIVO com toggle Switch. Seção MERCADO PAGO com campos de credenciais em mono com ícone olho. Seção ESPORTES com lista e botão adicionar. Seção STATUS com tabela de 2 colunas.

### Checklist

- [ ] Label seção pagamento: "PAGAMENTO" em JetBrains Mono 9.5px AppTheme.concrete
- [ ] "PIX ATIVO" em Anton 26px AppTheme.ink como título dominante
- [ ] Subtexto abaixo: "Usuários podem pagar com Pix" ou "Apenas pagamento na hora" em Manrope 12.5px concrete
- [ ] Switch ao lado do "PIX ATIVO": ativo = laranja (AppTheme.orange), inativo = AppTheme.line
- [ ] Switch desabilitado (credenciais não configuradas): aparência dimida, não interativo
- [ ] Divisor AppTheme.line entre seção PIX e seção MERCADO PAGO
- [ ] Label "MERCADO PAGO" em JetBrains Mono 10px concrete
- [ ] Badge "CONECTADO" (quando configurado): ícone check + texto AppTheme.court (verde) mono 10px
- [ ] Label "ACCESS TOKEN" em JetBrains Mono 10px concrete acima do campo
- [ ] Campo ACCESS TOKEN: texto em JetBrains Mono 14px ink, borda underline (não outlined)
- [ ] Ícone olho (visibilidade) ao lado do campo ACCESS TOKEN: 14px concrete — toque revela/oculta
- [ ] Ícone check verde ao lado quando token configurado
- [ ] Campo WEBHOOK SECRET: mesmo padrão que ACCESS TOKEN
- [ ] Botão "SALVAR CREDENCIAIS": SportBtn outlined (borda ink, texto Anton uppercase)
- [ ] Seção STATUS: label "STATUS" mono concrete + tabela 2 colunas (Última verificação + Modo "PRODUÇÃO" em verde)
- [ ] Seção ESPORTES: label "ESPORTES" mono concrete + lista de esportes cadastrados
- [ ] Cada esporte na lista: Manrope 14px bold + ícone lixeira concrete + ícone drag handle concrete
- [ ] Campo adicionar esporte: input underline + ícone "+" laranja à direita
- [ ] Botão "ADICIONAR ESPORTE": SportBtn outlined
- [ ] Botão "SALVAR ESPORTES" (aparece apenas quando há mudanças não salvas): SportBtn outlined
