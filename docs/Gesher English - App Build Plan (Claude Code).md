# Gesher English — App Build Plan (Custom, with Claude Code)

*Companion to the Pilot Plan. June 2026.*

You picked the custom build. This is the spec, the stack, the build order, and the prompts to paste into Claude Code. Build it as a **mobile web app (PWA)** first — it runs on any phone, uses the camera, and does video calls in the browser, with no app store. Go native later only if you need it.

---

## 1. What you're building

Three roles:

- **Student** (Israel) — photographs homework, joins the call.
- **Tutor** (US volunteer) — sees the homework, runs the call.
- **Coordinator/Admin** (an adult — you and/or a partner-org supervisor) — approves users, records consent, makes the matches, oversees safety.

The core loop:

1. Admin approves a student and a tutor and **pairs them** (no one browses or searches for each other).
2. Student **snaps a photo** of their homework → it uploads and is visible to their tutor.
3. At session time, both tap **Join call** → a private video room (recorded for oversight) with the homework shown alongside.
4. Admin can review recordings and handle any **reported concern**.

---

## 2. Architecture & stack

| Layer | Choice | Why |
|---|---|---|
| App | **Next.js (App Router) + TypeScript + Tailwind**, mobile-first PWA | One codebase, runs on any phone, camera + video in-browser |
| Auth + data + files | **Supabase** (Postgres, Auth, Storage, Row-Level Security) | Handles the hard/secure parts so you don't build them |
| Video calls | **Daily.co** (embedded, with cloud recording) | Never build WebRTC yourself; rooms are minted per session |
| Hosting | **Vercel** (app + serverless routes) | Free, deploys from GitHub automatically |
| Secrets | Env vars on Vercel/Supabase | Daily API key & Supabase service key stay **server-side only** |

**Golden rule:** the Daily room tokens and any service keys are minted **server-side** (a Next.js route handler or Supabase Edge Function). Never put a service key in the browser.

---

## 3. Data model (tables)

- **profiles** — `id` (→ auth user), `role` (student | tutor | admin), `full_name`, `country`, `school`, `status` (pending | active), `parental_consent_at`, `created_by`
- **matches** — `id`, `student_id`, `tutor_id`, `status`, `created_by` (admin), `created_at`
- **sessions** — `id`, `match_id`, `scheduled_at`, `status` (scheduled | live | done), `daily_room_url`, `recording_url`
- **homework** — `id`, `match_id`, `student_id`, `storage_path`, `note`, `created_at`
- **reports** — `id`, `reporter_id`, `match_id`, `message`, `created_at`

**Row-Level Security (the security heart):** a student or tutor can read/write **only rows tied to their own match**. No user can query other users. Only `admin` can see everything (for oversight). Homework is readable only by the matched pair + admin. Get these policies right — they're what protect the kids' data and prevent stranger contact.

---

## 4. Safeguarding by design (non-negotiable — both sides are minors)

Bake these into the build, not as an afterthought:

- **No discovery.** Matches are admin-created. Students and tutors only ever see their one assigned partner. No search, no browsing, no friend requests.
- **Consent first.** A student or tutor is `pending` until parental consent is recorded; only then can they be matched.
- **Recorded, private calls.** Rooms are minted per session, joinable only by the pair (+admin). Recording on; recordings retained for review.
- **No private contact.** No exchange of phone numbers, emails, or socials. If you add chat, keep it in-app and logged (skip chat for the MVP if you can).
- **Report a concern** button → goes to the admin.
- **Data minimization.** Store the least PII possible; lock it with RLS; publish a short privacy policy.

> **Two real-world obligations to respect:** recording minors and storing their homework/PII triggers parental-consent and data-protection duties (COPPA/GDPR-K-type rules). Get genuine parental consent, keep data minimal, and — strongly recommended — run the whole thing **under a partner org's child-protection framework with an adult supervisor** (Israel Connect / Skilled Volunteers for Israel). Build the app; let the adults own the safety layer.

---

## 5. MVP scope (resist scope creep)

**Build first:** email login + roles, admin approves users + records consent + creates matches, homework photo upload + view, a recorded video call between the pair, a simple "Join call" session flow, and a Report button.

**Defer:** fancy scheduling/calendars, in-app chat, push notifications, native app-store apps, document auto-crop/OCR, analytics dashboards, payments. None of these are needed to prove the concept.

---

## 6. Set these up before you start (free tiers)

1. **Node.js** (LTS) + **VS Code** + **Git** installed.
2. **GitHub** account (the repo).
3. **Vercel** account (connect to GitHub).
4. **Supabase** account → create a project (save the URL + keys).
5. **Daily.co** account (save the API key; check current free-tier limits — *recording may require a paid plan*).
6. **Claude Code** installed in your terminal.

---

## 7. Build order (drive Claude Code one step at a time)

1. Scaffold Next.js + Tailwind + Supabase client; deploy a blank page to Vercel (prove the pipeline works end-to-end first).
2. Create the Supabase tables + **RLS policies**; seed one admin account.
3. Auth + role-gated dashboards (student / tutor / admin).
4. Admin screens: approve users, record consent, create matches.
5. Homework: camera upload + the tutor's view of it.
6. Daily: server route that mints a room + token for a session; the join screen; turn on recording.
7. Session flow: "Join call" that shows the homework next to the video.
8. Report button, PWA manifest, basic polish.
9. **Safety pass:** test with fake accounts, verify RLS blocks cross-user access, write the privacy policy.

Commit after every step. Test each feature before moving on.

---

## 8. How to drive Claude Code well

- One feature per prompt — don't ask for the whole app at once.
- Paste the **kickoff prompt** below first so it has full context, then give it the step prompts.
- Keep secrets in `.env.local`; never commit them.
- Ask it to **explain before running** anything that deletes data or changes the database.
- For the RLS policies, tell it to write them explicitly and then **test that a student cannot read another match's data** — this is security-critical, don't take it on faith.

---

## 9. Kickoff prompt (paste this into Claude Code first)

> You're helping me build a tutoring web app called **Gesher English**. I'm a high-school student; explain your steps and go one feature at a time.
>
> **What it does:** American high-school volunteers tutor war-disrupted Israeli students in English. A student photographs their homework; their matched tutor sees it and they do a live, recorded video call to work through it. An adult admin approves users, records parental consent, and creates the matches.
>
> **Stack:** Next.js (App Router) + TypeScript + Tailwind, mobile-first PWA. Supabase for auth, Postgres, storage, and Row-Level Security. Daily.co for embedded, recorded video calls, with room tokens minted server-side only. Deploy to Vercel. Keep all secrets server-side in env vars.
>
> **Roles:** student, tutor, admin. **Three core rules that must hold:**
> 1. No discovery — students and tutors only ever see their one admin-created match; no search or browsing of other users.
> 2. A user is `pending` until parental consent is recorded by the admin; only `active` users can be matched.
> 3. All calls are private to the matched pair (+admin) and recorded for oversight.
>
> **Tables:** profiles, matches, sessions, homework, reports (I'll paste the field list). Write **explicit RLS policies** so a student or tutor can only access rows tied to their own match, and only admin can see everything. After writing them, show me how to test that a student cannot read another match's data.
>
> **MVP scope only:** auth + roles; admin approves users, records consent, creates matches; homework photo upload + tutor view; a recorded Daily call between the pair; a "Join call" session flow; a Report-a-concern button. Defer chat, scheduling, notifications, native apps, OCR.
>
> **Start now with Step 1:** scaffold the Next.js + Tailwind + Supabase project, set up the Supabase client, and get a blank page deploying to Vercel from GitHub. Walk me through any accounts/keys I need and where to put them. Then stop and wait for me before Step 2.

## 10. Step prompts (give these one at a time, after Step 1)

- **Step 2:** "Create the Supabase schema for profiles, matches, sessions, homework, reports with the fields I'll paste, plus RLS policies enforcing the three rules. Give me the SQL and the exact test to confirm a student can't read another match's rows."
- **Step 3:** "Add Supabase email auth and role-gated layouts: separate student, tutor, and admin dashboards. Redirect by role."
- **Step 4:** "Build the admin screens: approve a pending user, record parental consent (timestamp), and create a student↔tutor match."
- **Step 5:** "Add homework upload using the phone camera (`<input capture>`), store the image in Supabase Storage, and show it on the tutor's match page. Enforce that only the matched pair + admin can view it."
- **Step 6:** "Add a server route that creates a Daily room and a join token for a given session, restricted to the matched pair. Enable cloud recording. Never expose the Daily API key client-side."
- **Step 7:** "Build the session 'Join call' screen showing the Daily call with the homework image beside it."
- **Step 8:** "Add a Report-a-concern button that writes to the reports table and notifies the admin. Add a PWA manifest so it installs on a phone."
- **Step 9:** "Help me test the whole flow with fake student/tutor/admin accounts and verify the RLS policies block cross-user access."

---

## Reality check (worth keeping in mind)

This is a real, buildable project — and a strong portfolio piece. Two honest reminders from the evaluation: existing programs (Israel Connect, Skilled Volunteers for Israel) already run "tutor + student on a recorded call," so your genuinely novel piece is the **homework-scan-to-tutor flow** and the **teen-volunteer pipeline** — lead with those. And because you're connecting minors on video, the safety layer isn't optional polish; it's the core of whether schools, parents, and partners will trust it. Build the app, but run it under an adult/partner safety umbrella.
