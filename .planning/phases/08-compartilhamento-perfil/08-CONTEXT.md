---
phase: 8
slug: compartilhamento-perfil
created: 2026-03-25
status: ready
---

# Phase 8 — Context & Decisions

## Phase Goal

Usuários podem compartilhar reservas via WhatsApp e atualizar o número de telefone no cadastro e no perfil.

**Requirements:** SOCIAL-03, PROF-01

---

## Area 1: WhatsApp Share (SOCIAL-03)

### Decision: Button Location
**Chosen:** BookingCard only (tela "Minhas Reservas")
- Botão de compartilhar aparece no `BookingCard`, ao lado do ícone de editar participantes e do botão Cancelar
- Nenhuma tela de confirmação nova; sem bottomSheet adicional

### Decision: Message Format
**Template (hardcoded):**
```
🏐 Reserva confirmada para {nome} — Academia Vida Ativa

📅 {data}, às {horario}
👥 {participantes}

Nos vemos na quadra! 🌴
```
- `{nome}` → `booking.clientName` (ou `UserModel.displayName` do usuário logado se `clientName` for null)
- `{data}` → data formatada em português, ex: "Quarta, 26 de março"
- `{horario}` → `booking.startTime`, ex: "08:00"
- `{participantes}` → `booking.participants`
- Se `booking.participants` for null ou vazio, a linha `👥 {participantes}` é **omitida** (incluindo o emoji)
- Mensagem URL-encoded via `Uri.encodeComponent()` e aberta com `url_launcher`: `https://wa.me/?text=...`

### Decision: Button Visibility
**Shown for:** status `confirmed` e `pending` apenas
- Não exibir para `cancelled` ou `rejected`
- Condição: `!booking.isCancelled && booking.status != 'rejected'`

### Decision: Dependency
Usar `url_launcher` — verificar se já está no `pubspec.yaml`. Se não estiver, adicionar.

---

## Area 2: Telefone no Cadastro (PROF-01)

### Decision: Campo obrigatório/opcional
**Opcional** — sem validação de presença; usuário pode deixar em branco

### Decision: Validação e máscara
**Custom `InputFormatter`** — sem pacote externo
- Máscara: `(XX) XXXXX-XXXX` (celular com DDD)
- Implementar como classe `PhoneInputFormatter extends TextInputFormatter` em `lib/core/utils/phone_input_formatter.dart`
- `keyboardType: TextInputType.phone`
- Não bloquear salvamento se vazio (campo opcional)

### Decision: Posição no RegisterScreen
**Último campo** — após "Confirmar senha"
- Mantém campos obrigatórios primeiro; telefone é opcional e fica no final
- Placeholder/hint: `(11) 99999-9999`

### Decision: Persistência
- `AuthCubit.registerWithEmailPassword()` recebe `phone: String?` opcional
- Se vazio após trim, passa `null`
- `UserModel` já tem `phone: String?` com `toFirestore`/`fromFirestore` prontos — sem alteração no modelo

---

## Area 3: Edição de Perfil (PROF-02)

### Decision: Campo editável
**Somente telefone** — nome e email não são editáveis nesta fase

### Decision: UX trigger
**BottomSheet** na `ProfileScreen`
- Botão "Editar telefone" (ou ícone de editar ao lado do telefone) na `ProfileScreen`
- BottomSheet contém: campo telefone com `PhoneInputFormatter`, botão Salvar
- Reutiliza o mesmo `PhoneInputFormatter` de PROF-01
- Pré-preenche com `UserModel.phone` atual
- Salvar: `AuthCubit.updatePhone(phone: String?)` → `Firestore /users/{uid}` update

### Decision: Feedback
SnackBar de sucesso ("Telefone salvo") — padrão já usado em outras telas do app

---

## Code Context

### Arquivos a modificar
| File | Change |
|------|--------|
| `lib/core/utils/phone_input_formatter.dart` | **CRIAR** — `PhoneInputFormatter` |
| `lib/features/auth/ui/register_screen.dart` | Adicionar campo telefone (último, opcional) |
| `lib/features/auth/cubit/auth_cubit.dart` | `registerWithEmailPassword` + `updatePhone()` |
| `lib/features/auth/ui/profile_screen.dart` | Botão editar telefone + BottomSheet |
| `lib/features/booking/ui/booking_card.dart` | Botão compartilhar WhatsApp |
| `pubspec.yaml` | Verificar/adicionar `url_launcher` |

### Padrões existentes relevantes
- `BookingCard._showEditParticipantsDialog()` → modelo para BottomSheet de edição simples
- `UserModel.phone` já existe com `fromFirestore`/`toFirestore` completo
- `BookingCubit.updateParticipants()` usa `FieldValue.delete()` para null — mesmo padrão para `updatePhone()`
- `AuthCubit.registerWithEmailPassword()` em `lib/features/auth/cubit/auth_cubit.dart` → adicionar parâmetro `phone`
- `booking.isCancelled` getter já existe no `BookingModel`
