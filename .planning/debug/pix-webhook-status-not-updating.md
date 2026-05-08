---
status: diagnosed
trigger: "Pagamento Pix confirmado no Mercado Pago (R$0.02, transação 153751601939), mas status da reserva no app continua 'Aguardando Pix' (pending_payment) em vez de mudar para 'confirmed'."
created: 2026-04-12T00:00:00Z
updated: 2026-04-13T00:00:00Z
---

## Current Focus

hypothesis: CONFIRMADO — Webhook do MP nunca chegou à função. Causa raiz: mismatch entre tipo de evento webhook configurado no MP e o que a função espera, combinado com possível URL errada/não-configurada. CAUSA SECUNDÁRIA: duas versões incompatíveis da função foram deployadas (Payment API vs Orders API).
test: Verificado via logs do Firebase — zero execuções de handlePixWebhook em toda a história
expecting: N/A — root cause identificado
next_action: Usuário deve verificar configuração do webhook no painel MP e confirmar URL + tipo de evento

## Symptoms

expected: Após pagamento Pix aprovado, booking status muda para "confirmed" automaticamente via webhook do Mercado Pago
actual: Status permanece "Aguardando Pix" (pending_payment) mesmo após pagamento confirmado no Mercado Pago
errors: Nenhum erro visível no app. Pagamento aparece no painel MP como "Venda de produtos +R$0,02" com transação 153751601939
reproduction: 1) Criar reserva, 2) Pagar via Pix, 3) MP confirma pagamento, 4) Status não atualiza
started: Fase 18 implementou webhook handler. Pode nunca ter funcionado em staging ou parou de funcionar.

## Eliminated

(nenhum ainda)

## Evidence

- timestamp: 2026-04-12T00:00:00Z
  checked: functions/index.js — handlePixWebhook completo (versão em disco)
  found: |
    Versão em disco usa Orders API (type=order, orderStatus=processed).
    Versão commitada (d85b428) usa Payment API (action=payment.updated, mpStatus=approved).
    Diferença crítica: arquivo em disco tem mudanças não-commitadas que mudaram completamente a lógica.
  implication: Duas versões da função com lógica incompatível existiram durante os deploys.

- timestamp: 2026-04-12T00:00:00Z
  checked: firestore.rules — regras para /bookings/{bookingId}/payment/{paymentId}
  found: "allow write: if false;" — payment subcollection é write-only via Admin SDK (server-side)
  implication: Regras OK para servidor — Admin SDK bypassa regras do Firestore. Não é o problema.

- timestamp: 2026-04-13T00:00:00Z
  checked: Histórico de deploys via firebase functions:log --project vida-ativa-staging
  found: |
    4 deploys da função handlePixWebhook:
    - 2026-04-09: criação inicial (hash a9cc966c — Payment API, sem MP_ACCESS_TOKEN secret)
    - 2026-04-09 21:05: update falhou — MP_ACCESS_TOKEN/versions/6 estava DESTROYED
    - 2026-04-09 21:07: update com v7 do secret (hash a3b38879 — Payment API)
    - 2026-04-10: update (hash c7b77f6d — Payment API, MP_ACCESS_TOKEN v8)
    - 2026-04-13 00:24: update (hash 790e11c8 — Orders API, MP_ACCESS_TOKEN v8) — VERSÃO ATUAL
  implication: Versão atual deployada hoje às 00:24 usa Orders API. Versão anterior usava Payment API.

- timestamp: 2026-04-13T00:00:00Z
  checked: Logs de execução runtime do handlePixWebhook via firebase functions:log
  found: ZERO execuções reais do handlePixWebhook em toda a história do projeto. Apenas AuditLogs de deploy.
  implication: CONFIRMADO — O webhook do Mercado Pago nunca chegou à função. A função nunca foi invocada.

- timestamp: 2026-04-13T00:00:00Z
  checked: Histórico de commits — git log -- functions/index.js
  found: |
    Commit d85b428 (fix createPixPayment) mudou Payment→Order API no createPixPayment.
    Esse commit NÃO estava versionado com uma mudança correspondente no handlePixWebhook.
    As mudanças do handlePixWebhook (Payment→Order) existem apenas no arquivo em disco, não commitadas.
  implication: |
    A versão deployada em 2026-04-13 (Orders API no handlePixWebhook) veio de mudanças não-commitadas.
    Isso significa a mudança foi feita localmente e deployada sem commit.

- timestamp: 2026-04-13T00:00:00Z
  checked: Lógica do handlePixWebhook atual (Orders API) — análise de bugs
  found: |
    BUG POTENCIAL na verificação de assinatura:
    Linha 339: String(dataId).toLowerCase()
    Para Orders API, o data.id é o orderId (numérico). Lowercasing um número não muda nada.
    MAS: MP pode enviar data.id no query param E no body simultaneamente. A função lê:
      req.query['data.id'] || req.body?.data?.id
    O query param pode ser string "153751601939", body também. Isso deve estar OK.
    
    BUG POTENCIAL no idempotency check:
    paymentRef = bookingRef.collection('payment').doc(String(paymentId || dataId))
    Aqui dataId = orderId, paymentId = transactions.payments[0].id.
    PaymentRecord foi salvo com txId = paymentResult.id (payment ID dentro da order).
    Se orderData.transactions?.payments?.[0]?.id retorna undefined, paymentRef usa orderId como chave.
    Mas o doc foi salvo com payment ID. Mismatch!
    No entanto, isso apenas afeta o idempotency check — a transação Firestore ainda confirma o booking.
    
    CONCLUSÃO: A lógica interna é razoavelmente correta, MAS nunca é executada pois webhook não chega.
  implication: O problema primário é entrega do webhook, não bugs na função.

## Resolution

root_cause: |
  O webhook do Mercado Pago nunca chegou à Cloud Function handlePixWebhook.
  Evidência conclusiva: zero execuções na história completa da função nos logs do Firebase.
  
  CAUSA MAIS PROVÁVEL (Hipótese A): URL do webhook não está configurada no painel do Mercado Pago,
  ou está configurada com URL errada/desatualizada.
  A URL correta é: https://us-central1-vida-ativa-staging.cloudfunctions.net/handlePixWebhook
  
  CAUSA SECUNDÁRIA (Hipótese B): Mesmo que URL esteja configurada, a versão deployada antes de hoje
  (até 2026-04-13 00:24) usava Payment API e filtrava por action=payment.updated. Mas createPixPayment
  usava Orders API — então o MP enviaria webhooks de tipo "order", não "payment.updated".
  A função rejeitaria todos esses webhooks na linha:
    if (action !== 'payment.updated' && action !== 'payment.created') return;
  
  HISTÓRICO: Múltiplos deploys com versões incompatíveis:
  - createPixPayment mudou de Payment API → Orders API (commit d85b428 + mudanças não-commitadas)
  - handlePixWebhook continuou esperando eventos de Payment API por muito tempo
  - Apenas hoje (04-13 00:24) a versão com Orders API foi deployada para o webhook handler
fix:
verification:
files_changed: []
