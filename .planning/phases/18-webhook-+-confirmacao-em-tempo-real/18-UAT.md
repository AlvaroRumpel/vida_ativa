---
status: complete
phase: 18-webhook-confirmacao-em-tempo-real
source: [18-01-SUMMARY.md, 18-02-SUMMARY.md, 18-03-SUMMARY.md]
started: 2026-04-09T00:00:00Z
updated: 2026-04-09T00:00:00Z
---

## Current Test

number: 1
name: Countdown timer visível no PixPaymentScreen
expected: |
  Abrir PixPaymentScreen após gerar QR code.
  Abaixo da imagem QR aparece texto "MM:SS restantes" com contagem regressiva ativa.
awaiting: user response

## Tests

### 1. Countdown timer visível no PixPaymentScreen
expected: Abaixo da imagem QR aparece texto "MM:SS restantes" com contagem regressiva ativa.
result: pass

### 2. Countdown fica vermelho abaixo de 2 minutos
expected: Quando o contador chega abaixo de 2:00, o texto "MM:SS restantes" muda para vermelho.
result: pass

### 3. Estado expirado — overlay cinza + botão Gerar novo QR
expected: Quando o countdown chega em 00:00, a imagem QR fica coberta com overlay cinza semi-transparente e aparece botão "Gerar novo QR" abaixo.
result: pass

### 4. Gerar novo QR reinicia countdown
expected: Tocar "Gerar novo QR" chama CF novamente, gera novo QR code, remove overlay cinza, e reinicia countdown com novo tempo.
result: pass

### 5. Confirmação em tempo real — navegação automática
expected: Quando booking é confirmado (via webhook ou admin manual), PixPaymentScreen navega automaticamente para /bookings e mostra snackbar de sucesso. Sem precisar recarregar.
result: pass

### 6. Admin badge — Aguardando Pix
expected: No painel admin, booking com status pending_payment e paymentMethod pix mostra badge "Aguardando Pix" em âmbar no AdminBookingCard.
result: pass

### 7. Admin badge — Pix pago
expected: Booking confirmado via Pix mostra badge "Pix pago" em verde no AdminBookingCard.
result: pass

### 8. Admin botão confirmar pagamento manual
expected: Abrir detalhe de booking pending_payment no admin. Botão "Confirmar pagamento manual" aparece acima das ações normais.
result: pass

### 9. Admin fluxo confirmar manual
expected: Tocar "Confirmar pagamento manual" abre diálogo de confirmação. Confirmar atualiza status do booking, mostra snackbar e fecha o sheet.
result: pass

### 10. Backend — funções exportadas (verificação de código)
expected: Em functions/index.js existem 4 exports: notifyAdminNewBooking, createPixPayment, handlePixWebhook, expireUnpaidBookings. Comando `node -e "const f = require('./index.js'); console.log(Object.keys(f))"` na pasta functions/ lista os 4.
result: pass

## Summary

total: 13
passed: 13
issues: 0
pending: 0
skipped: 0

## Fixes desta sessão (v4.0 post-phase)

### 11. Nome correto no Mercado Pago
expected: Dashboard MP mostra nome real do pagador, não email duplicado.
result: pass

### 12. Sem booking ao falhar QR
expected: Falha no CF de pagamento → booking NÃO persiste, sheet mostra erro, retry disponível.
result: pass
note: Design clarificado 2026-05-08 — booking PERSISTE em pending_payment quando CF falha; expira automaticamente em 45min via expireUnpaidBookings. Comportamento intencional. Teste original tinha expectativa errada.

### 13. Cancelar reserva Pix pendente cancela MP order
expected: Cancelar booking pending_payment+pix → QR inválido, MP order cancelada, Firestore status=cancelled.
result: pass

## Gaps

[none yet]
