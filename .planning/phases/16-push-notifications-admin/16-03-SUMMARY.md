---
phase: 16-push-notifications-admin
plan: "03"
subsystem: infra
tags: [firebase, cloud-functions, fcm, push-notifications, flutter-web, hosting, staging]

requires:
  - phase: 16-01
    provides: Cloud Function source code (functions/index.js), service worker generator script
  - phase: 16-02
    provides: AdminFcmCubit, Flutter FCM integration wired into AdminScreen

provides:
  - Flutter web app with staging-config service worker deployed to https://vida-ativa-staging.web.app
  - Cloud Function notifyAdminNewBooking (PENDING — staging Blaze upgrade required)

affects: [production-deploy]

tech-stack:
  added: []
  patterns: [generate-sw-before-build, firebase-use-alias-deploy]

key-files:
  created: []
  modified:
    - web/firebase-messaging-sw.js (generated, gitignored — regenerated for staging with projectId vida-ativa-staging)

key-decisions:
  - "flutter build web without VAPID key — String.fromEnvironment defaults to empty, getToken(vapidKey: null) works for basic FCM"
  - "Staging Cloud Functions blocked by Blaze plan requirement — hosting deployed separately as partial step"

requirements-completed: []

duration: ~5 min
completed: 2026-04-05
---

# Phase 16 Plan 03: Staging Deployment & End-to-End Verification Summary

**Flutter web app with staging service worker deployed to vida-ativa-staging.web.app; Cloud Function deployment blocked by Blaze plan upgrade required on staging project.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-04-05T14:01:09Z
- **Completed:** 2026-04-05T14:06:50Z
- **Tasks:** 0 of 1 fully complete (hosting deployed, functions blocked)
- **Files modified:** 0 (service worker is gitignored generated artifact)

## Accomplishments

- Generated `web/firebase-messaging-sw.js` with `projectId: 'vida-ativa-staging'` via `node scripts/generate-sw.js staging`
- Built Flutter web app for staging (`flutter build web --dart-define=ENV=staging` — exit 0)
- Deployed hosting to https://vida-ativa-staging.web.app (37 files, deploy complete)
- Confirmed `firebase.json` already has `"functions": { "source": "functions", "runtime": "nodejs20" }` — no changes needed

## Task Commits

No new commits — all changes are either generated (gitignored) or already-committed source files.

## Files Created/Modified

- `web/firebase-messaging-sw.js` — Regenerated for staging (gitignored, not committed)

## Decisions Made

- Build proceeded without VAPID key (empty default via `String.fromEnvironment`) — FCM token retrieval works without VAPID for basic push
- Switched Firebase back to `default` alias after partial deploy to avoid accidental staging deploys

## Deviations from Plan

### Blocking Issue

**[Rule 4 - Architectural / Billing Gate] Cloud Functions deployment blocked by Spark plan**

- **Found during:** Task 1 (Deploy Cloud Functions and web app to staging)
- **Issue:** `vida-ativa-staging` project is on Spark (free) plan. `cloudbuild.googleapis.com` cannot be enabled until the project is upgraded to Blaze (pay-as-you-go).
- **Error:** `Your project vida-ativa-staging must be on the Blaze (pay-as-you-go) plan to complete this command`
- **Upgrade URL:** https://console.firebase.google.com/project/vida-ativa-staging/usage/details
- **What was completed:** Hosting deployed successfully (staging web app live)
- **What is blocked:** `firebase deploy --only functions` — requires Blaze plan

**Impact:** End-to-end notification test cannot be completed until Cloud Function is deployed. The full NOTF-01 verification (admin receives notification when client books) is pending.

---

**Total deviations:** 1 blocking (billing gate — human action required)

## Issues Encountered

Cloud Functions deploy blocked by Firebase project billing plan. Staging project (`vida-ativa-staging`) must be upgraded to Blaze plan before `notifyAdminNewBooking` can be deployed.

**Resolution steps for user:**
1. Visit https://console.firebase.google.com/project/vida-ativa-staging/usage/details
2. Click "Upgrade" → select Blaze (pay-as-you-go)
3. After upgrade, re-run: `firebase use staging && firebase deploy --only functions`
4. Verify: `firebase functions:list --project vida-ativa-staging | grep notifyAdminNewBooking`

## Next Phase Readiness

- Staging web app is live at https://vida-ativa-staging.web.app with correct staging service worker
- Cloud Function deployment requires Blaze plan upgrade on staging project
- After functions deploy, end-to-end test can proceed (see checkpoint verification steps in 16-03-PLAN.md)
- Production deploy (default project, vida-ativa-94ba0) may already be on Blaze — could be used as fallback if staging upgrade is undesirable

---
*Phase: 16-push-notifications-admin*
*Completed: 2026-04-05 (partial — pending Blaze upgrade)*

## Self-Check: PASSED

- SUMMARY.md file: created at `.planning/phases/16-push-notifications-admin/16-03-SUMMARY.md`
- Hosting deployed: https://vida-ativa-staging.web.app (confirmed in deploy output)
- No task commits expected (service worker is gitignored)
