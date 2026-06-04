# Phase 27: Admin Slots + Reservas + Usuários - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 27-admin-slots-reservas-usu-rios
**Areas discussed:** Slot row layout, Ações de Reserva admin, Reuso vs novo widget, Avatar de usuário, UserDetailSheet

---

## Slot Row Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Hora Anton 32px + status 'DISPONÍVEL' mono | Consistente com SlotHairlineRow do cliente | |
| Hora Anton 32px apenas, sem label | Mais limpo, switch indica ativo | |
| Hora + valor + switch (como no design system) | Slot vazio: hora + preço + switch | ✓ |

**User's choice:** "Hora + valor + switch, como no design system"

| Option | Description | Selected |
|--------|-------------|----------|
| Hora laranja + nome + esporte | Anton 32px laranja, nome Manrope, esporte | ✓ |
| Hora laranja + nome apenas | Mínimo | |
| Hora laranja + nome + participantes + esporte | Máximo de info | |

**User's choice:** Hora laranja + nome + esporte (Recomendado)

| Option | Description | Selected |
|--------|-------------|----------|
| Abre SlotFormSheet existente | Já existe, sem reescrita | |
| Abre detalhe da reserva se reservado, SlotForm se vazio | Context-aware | ✓ |
| Sem tap — switch é único interativo | Row é só display | |

**User's choice:** Context-aware (detalhe se reservado, SlotFormSheet se vazio)

---

## Ações de Reserva Admin

| Option | Description | Selected |
|--------|-------------|----------|
| Só quando status = pending | Confirmar/Recusar só para pendentes | ✓ |
| Sempre visíveis em todo row | Admin pode rever qualquer reserva | |
| Aparecem ao abrir AdminBookingDetailSheet | Row é só display | |

**User's choice:** Só quando status = pending (Recomendado)

| Option | Description | Selected |
|--------|-------------|----------|
| Inline no row — à direita do status | ROADMAP especifica inline | ✓ |
| Abaixo do row — expandido quando pending | Row expande | |
| No AdminBookingDetailSheet existente | Preserva sheet existente | |

**User's choice:** Inline no row — à direita do status (Recomendado)

---

## Reuso vs Novo Widget

| Option | Description | Selected |
|--------|-------------|----------|
| Criar AdminBookingRow separado | Colunas diferentes justificam arquivo próprio | ✓ |
| Estender HairlineBookingRow com parâmetros admin | Um widget com bool isAdmin | |
| Reusar HairlineBookingRow sem modificação | Não funciona (layout diferente) | |

**User's choice:** Criar AdminBookingRow separado (Recomendado)

| Option | Description | Selected |
|--------|-------------|----------|
| Substituir completamente com novo AdminBookingRow | Mesmo padrão Phase 26 | ✓ |
| Manter AdminBookingCard e reusar parcialmente | Preserva legado | |

**User's choice:** Substituir completamente (Recomendado)

---

## Avatar de Usuário

| Option | Description | Selected |
|--------|-------------|----------|
| Inicial do nome | Ex: 'A' para Alvaro | |
| Ícone genérico (person icon) | Mais simples | |
| Foto de perfil se disponível, inicial como fallback | photoUrl Firebase Auth | ✓ |

**User's choice:** Foto de perfil se disponível, inicial como fallback

| Option | Description | Selected |
|--------|-------------|----------|
| Sem tap — ações ficam nos botões existentes | Row é só display | |
| Tap abre UserDetailSheet com ações de admin | Nova sheet | ✓ |

**User's choice:** Tap abre UserDetailSheet

---

## UserDetailSheet (Escopo expandido pelo usuário)

**Nota:** UserDetailSheet não estava no ROADMAP original. Usuário optou por incluir na Phase 27 explicitamente.

| Option | Description | Selected |
|--------|-------------|----------|
| Nome + email + foto/avatar + contagem reservas + botões Promover/Remover Admin | Consolidação de info + ações | ✓ |
| Só ações: Promover/Remover Admin | Minimalista | |
| Histórico de reservas também | Mais completo, query extra | |

**User's choice:** Nome + email + foto/avatar + contagem + botões (Recomendado)

---

## Claude's Discretion

- Padding interno dos rows
- Tamanho do Anton no day selector
- Tamanho do avatar na sheet vs no row
- Cor do contador de reservas
- Animação da UserDetailSheet

## Deferred Ideas

- Histórico de reservas por usuário na UserDetailSheet — fase futura
- Filtros/busca na aba Reservas admin — fase futura
