# Feature Landscape

**Domain:** Single-venue sports court time-slot booking PWA
**Project:** Vida Ativa — beach volleyball / futevôlei court
**Researched:** 2026-03-19
**Confidence:** MEDIUM (training-data based; external research tools unavailable during this session)

---

## Context

This is a **replacement for WhatsApp-list booking** at a single venue. The competitive bar is therefore "better than a WhatsApp message chain", not "better than Playtomic". That lowers the table-stakes bar considerably: users just need correctness, clarity, and mobile-first UX. Features that matter on multi-venue SaaS products (waitlists, payment, memberships, multi-court) are noise here.

---

## Table Stakes

Features users expect. Missing = product feels broken or untrustworthy vs WhatsApp.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Login (Google or Phone)** | Auth gate prevents double-booking chaos; WhatsApp already knows who you are | Low-Med | Firebase Auth makes this straightforward. Phone OTP is the harder path — Google Sign-In alone covers most Brazilian Android users. |
| **Weekly schedule view** | User's first question: "what's available this week?" | Med | Must show slots by day, with clear available / booked / blocked states. A simple list-per-day or grid is sufficient. Full calendar widget is overkill. |
| **Slot availability at a glance** | Color/label distinguishes available, my booking, full, blocked | Low | Failure here means users call on WhatsApp anyway. |
| **Reserve a slot (tap-to-book)** | Core action — must be one-tap from the schedule view | Low-Med | Confirmation dialog to prevent accidents. Should show price and time before confirming. |
| **View my bookings** | Users forget what they booked | Low | A "my bookings" tab or section. Shows upcoming + past. |
| **Cancel my own booking** | Life happens | Low | Must enforce a cancellation window (e.g., minimum 2h before slot) to prevent last-minute drops. Policy is configurable by admin. |
| **Conflict prevention (double-booking guard)** | Single court = only one booking per slot | Low | Firestore transaction on write. Non-negotiable correctness requirement. |
| **Admin: view all bookings** | Admin must know who has what slot | Low | A simple list/table filtered by date. Compact view for mobile use by the gym owner. |
| **Admin: confirm or reject bookings** | Replaces the WhatsApp "ok, confirmed" message | Low | Only needed if approval mode is on. Must show user name + slot clearly. |
| **Admin: create recurring slots** | Court schedule is weekly-recurring | Med | Define day-of-week + start time + duration + price. These become the repeating template. |
| **Admin: block specific dates** | Holidays, rain, maintenance | Low | Simple date picker + optional reason note. Blocked dates suppress slots for that day. |
| **PWA install prompt** | App must be installable to home screen for repeat use | Low | Requires proper manifest.json + service worker. Flutter Web handles most of this out of the box. |
| **Offline-friendly loading states** | Mobile users have intermittent connections | Low | Show skeleton/loading UI; don't crash silently on slow Firestore reads. |

---

## Differentiators

Features that go beyond "better than WhatsApp" — competitive advantage for user retention and admin confidence.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Booking status timeline** | User sees: Pending → Confirmed → Cancelled with timestamps | Low | Replaces the "did they see my message?" anxiety from WhatsApp. One-field status enum on the booking document. |
| **Configurable approval mode** | Admin can switch between auto-confirm and manual-approve without a deploy | Low | A single Firestore config doc (`/config/booking`) with `requireApproval: bool`. Admin toggles it in the panel. High value for trust-building during launch. |
| **Cancellation policy enforcement** | Prevents last-minute no-shows | Low | `cancelBefore: int` (hours) stored in config. UI shows the deadline; write blocked after cutoff. |
| **Slot price display** | Shows cost upfront, avoids "how much?" WhatsApp messages | Low | Price is per-slot in the recurring slot definition. Display only — payment stays offline. |
| **Admin: booking history per user** | Identify frequent customers, spot no-show patterns | Med | Filter `/bookings` by userId. Useful for trust/relationship; not critical for v1. |
| **"My next booking" home card** | First thing user sees after login = their next upcoming slot | Low | Single Firestore query. Reduces navigation friction for repeat users. |
| **Share slot link** | User can share a "book this slot" deep link with a friend | Med | Requires URL routing with slot parameters. Nice-to-have for referrals. |

---

## Anti-Features

Features to explicitly NOT build in v1. Each has a clear reason.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Online payment** | Out of scope per project requirements; adds PCI complexity, Stripe/PagSeguro integration, refund logic | Keep payment offline; show price in UI only |
| **Push notifications** | Out of scope for v1; requires FCM token management, permission flows, notification composer in admin | WhatsApp or SMS for v1 reminders; add in v2 |
| **Waitlist** | Single court, limited demand; adds queue-management complexity | If slot is full, just show "unavailable" |
| **Recurring personal reservations** | "Book every Monday 8h for me forever" — risky for small venue (locks out others) | Admin controls recurring slots; users book individual instances |
| **User-to-user chat** | Out of scope; entire value prop is removing unstructured WhatsApp communication | Admin contact info in footer if users need to reach the gym |
| **Multi-court support** | Single court venue; premature abstraction | One court in data model; easy to extend later if needed |
| **Membership / subscription tiers** | No membership system at this gym currently | Flat per-booking price; memberships = v3+ |
| **Court photos / media gallery** | Nice for marketing but not for booking | Static info on a landing section or about page is sufficient |
| **Social login beyond Google** | Phone OTP + Google covers >95% of Brazilian Android users | Don't add Facebook/Apple login complexity for v1 |
| **Email notifications** | Most users in this context interact via mobile/WhatsApp, not email | Skip email; focus on in-app status visibility |
| **Complex reporting / analytics** | Small single-venue operation doesn't need dashboards | Simple booking list is sufficient for admin |
| **User profile editing** | Display name and photo come from Google; no other profile data needed | Read-only profile from Firebase Auth; no edit flow |

---

## Feature Dependencies

```
Google Sign-In ──────────────────────────┐
Phone OTP Sign-In ───────────────────────┤
                                          ↓
                                  Auth Session
                                          │
                    ┌─────────────────────┼──────────────────────┐
                    ↓                     ↓                      ↓
           Weekly Schedule View    My Bookings View       Admin Panel
                    │                     │                      │
                    ↓                     │           ┌──────────┼──────────┐
           Reserve a Slot ←──────────────┘           ↓          ↓          ↓
                    │                        Manage Slots  View Bookings  Block Dates
                    ↓                                           │
           Conflict Prevention (Firestore tx)                   ↓
                    │                                  Confirm / Reject
                    ↓
           Booking Status (pending → confirmed → cancelled)
                    │
                    ↓
           Cancel My Booking ── (enforces cancellation window from config)

Configurable Approval Mode ──→ affects Reserve a Slot (auto-confirm vs pending)
Cancellation Policy Config ──→ affects Cancel My Booking (cutoff enforcement)
```

Key hard dependencies:
- **Auth must exist before any booking action** — unauthenticated users can view schedule (read-only) but cannot book
- **Recurring slot templates must exist before users can book** — admin creates slots first
- **Booking status model must be defined before both "Reserve" and "Confirm/Reject" flows** — shared state machine

---

## MVP Recommendation

Prioritize in this order:

1. **Auth (Google Sign-In)** — gates everything; Phone OTP is second pass
2. **Weekly schedule view (read-only)** — first screen a user sees; must work before booking does
3. **Admin: create recurring slots + block dates** — no slots = nothing to book; admin setup comes before user flow
4. **Reserve a slot** — core user action; include conflict prevention from day one
5. **View my bookings + cancel** — users need to see and manage what they booked
6. **Admin: view all bookings + confirm/reject** — closes the loop; replaces WhatsApp confirmation
7. **Configurable approval mode** — lets admin start in manual mode for trust, switch to auto later
8. **PWA install** — manifest + service worker; do this at project setup, not at the end

Defer to v2:
- **Phone OTP auth** — Google covers the majority; adds OTP complexity (Firebase Phone Auth has SMS costs and reCAPTCHA requirements on web)
- **Push notifications** — requires FCM; significant scope for limited v1 gain
- **Booking history per user (admin view)** — useful but not blocking
- **"My next booking" home card** — polish; build after core flow is solid
- **Share slot link** — requires URL router setup; worth doing when deep linking is needed

---

## Domain Notes (Confidence Flags)

- **Table stakes list: MEDIUM confidence** — Based on analysis of Playtomic, CourtReserve, Clubspark, and similar platforms from training data (cutoff Aug 2025). Core booking UX patterns are stable and unlikely to have shifted.
- **Anti-features list: HIGH confidence** — Directly grounded in PROJECT.md "Out of Scope" section and standard single-venue app scope constraints.
- **Differentiators list: MEDIUM confidence** — Based on common patterns in sports booking UX; "configurable approval mode" is specific to this project's stated requirements and HIGH confidence for this use case.
- **Brazilian market context: LOW confidence** — Phone OTP preference vs Google Sign-In in Brazilian gym demographics not verified. Assumption based on general Android market share in Brazil (>90%). Recommend validating with actual users before deprioritizing Phone OTP.

---

## Sources

- PROJECT.md requirements and out-of-scope decisions (HIGH confidence — primary source)
- Training knowledge of Playtomic, CourtReserve, Smashlocker, Clubspark, PlayByPoint feature sets (MEDIUM confidence — unverified against current docs, external tools unavailable)
- Firebase Auth platform capability knowledge for Google Sign-In and Phone OTP on Flutter Web (MEDIUM confidence — verify Phone OTP web support before building)
