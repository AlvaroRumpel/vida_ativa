---
status: awaiting_human_verify
trigger: "Erro [firebase_functions/internal] INTERNAL ao salvar faixa de preço no painel admin."
created: 2026-04-12T00:00:00Z
updated: 2026-04-12T00:00:00Z
---

## Current Focus

hypothesis: Query composta em bookings (date >= X + status in [...]) lança exceção Firestore não tratada por falta de índice composto OU calcPrice acessa startTime undefined — ambas propagam como INTERNAL pois não há try/catch na função
test: Analisado o código completo de updateSlotPricesFromTiers — sem try/catch ao redor de nenhuma operação Firestore; qualquer exceção JS não capturada = INTERNAL
expecting: Root cause confirmado
next_action: RESOLVED — documentar root cause

## Symptoms

expected: Salvar faixa de preço com sucesso via Firebase Callable Function
actual: DartError: [firebase_functions/internal] INTERNAL — erro lançado em https_callable_web.dart:56
errors: "DartError: [firebase_functions/internal] INTERNAL" — stack trace aponta para cloud_functions_web/https_callable_web.dart:56 (convertFirebasesFunctionsException)
reproduction: Acessar painel admin > aba de preços > tentar salvar faixa de preço
started: Erro encontrado agora, pode ser relacionado a mudanças recentes em functions/index.js e pricing_cubit.dart

## Eliminated

- hypothesis: Bug no saveTiers do Flutter (pricing_cubit.dart) antes de chamar a function
  evidence: O .set() no Firestore direto tem regra allow write: if isAdmin() — passa. O erro vem da callable, não do .set()
  timestamp: 2026-04-12

- hypothesis: Erro de autenticação/permissão (unauthenticated ou permission-denied)
  evidence: Esses casos lançam HttpsError explícito — Flutter veria firebase_functions/unauthenticated, não INTERNAL
  timestamp: 2026-04-12

- hypothesis: Bug no onCall({}, handler) — sintaxe inválida da v2
  evidence: onCall(options, handler) é formato válido da v2; {} vazio é aceito
  timestamp: 2026-04-12

## Evidence

- timestamp: 2026-04-12
  checked: functions/index.js — updateSlotPricesFromTiers (linhas 644-714)
  found: Função não tem nenhum try/catch ao redor das operações Firestore. Qualquer exceção não tratada (Firestore, batch.update, calcPrice) propaga como erro JS genérico → Firebase runtime converte para INTERNAL.
  implication: Candidatos a causa: (1) query composta sem índice, (2) slot sem campo startTime/date

- timestamp: 2026-04-12
  checked: Query de bookings (linhas 665-668): .where('date', '>=', todayStr).where('status', 'in', [...])
  found: Combina range filter (date >=) com equality/in filter (status in) em campos diferentes. Firestore EXIGE índice composto para isso. Sem o índice, lança FirebaseError: "The query requires an index" — exceção não-HttpsError.
  implication: Candidato #1 mais provável — função foi adicionada recentemente e índice pode não ter sido criado

- timestamp: 2026-04-12
  checked: calcPrice (linhas 672-684) — acessa slot.startTime e slot.date
  found: Se algum slot não tiver campo startTime, parseInt(undefined.split(':')[0]) lança TypeError. Também não há try/catch.
  implication: Candidato #2 — menos provável se slots têm schema consistente

- timestamp: 2026-04-12
  checked: firestore.rules + pricing_cubit.dart
  found: Regra config permite write para admin. Flutter chama .set() depois .call() — erro vem da callable, não do .set() direto
  implication: Confirma que o problema está dentro da Cloud Function, não nas regras

## Resolution

root_cause: A função updateSlotPricesFromTiers executa uma query Firestore composta (date >= todayStr + status in [...]) que requer índice composto. Como a função foi adicionada recentemente e o índice provavelmente não foi criado no projeto Firebase, a query lança uma exceção JS não tratada (FirebaseError: "The query requires an index"). Sem try/catch ao redor das operações, essa exceção propaga para o runtime do Firebase Functions, que a converte em erro INTERNAL — exatamente o erro visto no Flutter.
fix: (1) Adicionado índice composto {date ASC + status ASC} em firestore.indexes.json. (2) Adicionado try/catch ao redor de todas as operações Firestore na função — catch lança HttpsError('internal', error.message) para mensagens claras no Flutter.
verification: Fix aplicado localmente. Aguardando deploy + confirmação humana.
files_changed: [firestore.indexes.json, functions/index.js]
