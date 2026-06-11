# Phase 34: Flutter Mini-App + Realtime - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-11
**Phase:** 34-flutter-mini-app-realtime
**Areas discussed:** Setup do mini-app Flutter, Escopo funcional Flutter, Prova do RLS no cliente, Avaliação Realtime

---

## Setup do Mini-App Flutter

### Estrutura do mini-app

| Option | Description | Selected |
|--------|-------------|----------|
| Projeto Flutter standalone | flutter create em /spike-supabase/flutter_app/. Roda no browser. Máxima fidelidade com produção. | ✓ |
| Dart CLI puro | main.dart sem UI, supabase-dart SDK. Mais rápido mas não testa Flutter Web real. | |
| Adicionar ao lib/ | Contradiz escopo do spike. | |

**User's choice:** Projeto Flutter standalone

### Autenticação no mini-app

| Option | Description | Selected |
|--------|-------------|----------|
| Email/password hardcoded | Contas de teste do seed. Sem UI de login. | ✓ |
| Tela de login simples | TextField + botão. Mais boilerplate sem valor para o spike. | |

**User's choice:** Email/password hardcoded

---

## Escopo Funcional Flutter

| Option | Description | Selected |
|--------|-------------|----------|
| Autenticar + ler + chamar book_slot() | Prova E2E completa. DECISION.md mais forte. | ✓ |
| Apenas autenticar + ler slots | SPIKE-08 literal. Mais conservador. | |

**User's choice:** Autenticar + ler + chamar book_slot()

---

## Prova do RLS no Cliente

| Option | Description | Selected |
|--------|-------------|----------|
| Dois usuários, dois tenants, comparar resultados | Mesmo query sem .eq(). Delta prova o filtro. | ✓ |
| Apenas um usuário, print dos resultados | Menos convincente. | |
| Interceptar network (DevTools) | Mais trabalho, pouco valor adicional. | |

**User's choice:** Dois usuários, dois tenants, comparar resultados

---

## Avaliação Realtime

### Escopo do SPIKE-09

| Option | Description | Selected |
|--------|-------------|----------|
| Isolação cross-tenant + latência | Confirmar que tenant_1 NÃO recebe evento de tenant_2. Questão crítica para DECISION.md. | ✓ |
| Apenas latência + limites free tier | Deixa sem resposta a questão crítica. | |
| Realtime fora de escopo | SPIKE-09 é requisito explícito da fase 34. | |

**User's choice:** Isolação cross-tenant + latência

### Implementação do teste Realtime

| Option | Description | Selected |
|--------|-------------|----------|
| Node.js separado (realtime-test.js) | @supabase/supabase-js. Mais fácil orquestrar 2 clientes simultâneos. | ✓ |
| Tudo no Flutter (RealtimeChannel + StreamBuilder) | Complexo para 2 clientes paralelos. | |

**User's choice:** Node.js separado

---

## Deferred Ideas

- UI de login real — não agrega valor ao spike
- Realtime sob carga (múltiplos tenants simultâneos) — SPIKE-11, pertence à fase 35
