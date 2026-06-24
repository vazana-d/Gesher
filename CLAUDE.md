# Lantern (project "Gesher") — Claude Code guide

@AGENTS.md

> ⚠️ This scaffold uses a Next.js version with **breaking changes** vs. older training data.
> Before writing any Next.js code, read the relevant guide in `node_modules/next/dist/docs/`.

Full plans live in [`docs/`](./docs/): the Complete Build Plan, the App Build Plan, and the Day‑1 Start Here.

---

## What we're building

**Lantern** — an English‑tutoring web app for **war‑disrupted Israeli students**. American Jewish high‑school volunteers tutor Israeli high‑school students in English. A student photographs their homework; their matched tutor sees it, and they work through it on a live, private video call. An adult **admin/coordinator** approves users, records parental consent, and creates the matches.

**Both tutors and students are minors** — the safeguarding layer below is the core of the project, not polish.

**Three roles:** `student` (Israel), `tutor` (US volunteer), `admin` (adult coordinator).

**The core loop:** admin pairs an active student + tutor → student snaps a homework photo (private) → at session time both Join a private video call with the homework shown alongside → admin oversees and handles any reported concern.

Build it **mobile‑first as a PWA**, with full **Hebrew right‑to‑left (RTL)** support built in from the start.

---

## The free‑tier stack (only paid tool is Claude Pro)

| Layer | Tool | Tier |
|---|---|---|
| App | **Next.js** (App Router) + React + TypeScript + Tailwind, mobile‑first PWA | free / OSS |
| Auth + DB + files | **Supabase** (Postgres, Auth, Storage, Row‑Level Security) | free |
| Video calls | **Daily** (embedded; rooms minted per session) | free* |
| Email | **Resend** ("you've been matched" email) | free (3,000/mo) |
| Hosting | **Vercel** (app + serverless routes, deploys from GitHub) | free Hobby |

*Daily's free tier may not include recording. Fallback for oversight: an adult coordinator able to join any call (or Jitsi Meet as a no‑account alternative).

Free‑tier facts: Supabase pauses a project after ~1 week idle (use it weekly to keep it awake); Vercel Hobby is non‑commercial (fine for a free passion project).

---

## Safeguarding rules (non‑negotiable — both sides are minors)

- **RLS on every table.** A student or tutor can read/write **only the rows tied to their own pairing**; only an **admin** can see everything. This is the security heart — write policies explicitly and test them.
- **No discovery.** Matches are admin‑created. Students and tutors only ever see their **one** assigned partner. No search, browsing, or friend requests.
- **Consent first.** A new user stays **Pending** until an admin records **parental consent** (timestamp). Only **Active** users can be paired.
- **Private file storage.** Homework photos live in a **private** Supabase bucket and are shown only through short‑lived **signed URLs** to the matched pair (+admin) — never a public link.
- **Private calls.** Rooms are minted per session, joinable only by the pair (+admin). Recording for oversight where available; otherwise an adult coordinator can join any call.
- **Secrets stay server‑side.** Supabase *service role* key, Daily key, and Resend key live **only** in env vars used by server code (route handlers / Edge Functions). The browser only ever gets the public *anon* key. **Never commit secrets.**
- **HTTPS everywhere** (automatic on Vercel).
- **Data minimization.** Collect the least PII possible: first name + last initial, grade, language, email. Nothing more.
- **No private contact** exchanged in‑app (no phone numbers, emails, socials). Skip chat for the MVP.
- **Report a concern** button → reaches the admin.
- **Adult oversight.** Run the whole thing under a partner org's child‑protection framework (Israel Connect / Skilled Volunteers for Israel) with a real adult supervisor. The software enforces the rules; the adults own the safety.
- **Privacy policy** published; a parent can request deletion.

---

## The 10‑step build order (one numbered step at a time)

1. **Skeleton + go live.** Scaffold the Next.js + TypeScript + Tailwind PWA, set up the Supabase client and `.env.local` with `.gitignore`, and deploy a blank page to Vercel from GitHub. *Goal: a live URL on day one.*
2. **Database + security.** Create the five tables with RLS policies so users see only their own pairing's rows and only admin sees all. Produce the SQL **and a test proving a student can't read another pairing's data.** Seed one admin account.
3. **Login + roles + language.** Supabase email login, role‑based dashboards (student / tutor / admin), and a Hebrew/English toggle with full RTL support.
4. **Sign‑up profile.** On sign‑up collect role, first name + last initial, grade, and language; new accounts start **Pending**.
5. **Admin approval + consent.** Admin screens to approve a Pending user, record parental consent (timestamp), and set them **Active**.
6. **Pairing + notification.** Admin proposes a pairing; the tutor accepts/declines (tutors never browse students); enforce **one active pairing per person**; allow **Drop → Ended**; on **Active**, send the student an in‑app message + a **Resend** email.
7. **Homework upload.** Student photographs homework with the phone camera, store it in a **private** Supabase bucket, and show it to the matched tutor via a **signed URL only**.
8. **Video call.** Server route that mints a Daily room + join token for a session, limited to the matched pair + admin; build the Join screen showing the homework beside the call.
9. **Safety + polish.** Add the Report‑a‑concern button, the PWA manifest, and make every screen responsive; test on a phone.
10. **Launch checks.** Test the full flow with fake student/tutor/admin accounts, verify RLS blocks cross‑user access, and write a short privacy policy. Then add the real env keys in Vercel and go live.

**Data model (5 tables):** `profiles` (role, first name + last initial, grade, language, status pending/active, parental_consent_at), `matches` (student, tutor, status), `sessions` (match, scheduled time, video room, status, recording), `homework` (match, student, storage path, note), `reports` (reporter, match, message).

---

## WORKING AGREEMENT (follow it)

- Run forward through the build order on your own. Do all coding, config, commands, and testing yourself.
- STOP and ASK ME only when you need me to: (a) create an account or sign in (GitHub, Vercel, Supabase, Daily, Resend), (b) paste an API key or secret, (c) authorize something in a browser, (d) make a product/design decision, or (e) do anything irreversible.
- Never commit secrets; put keys in .env.local only (.gitignore must cover .env*).
- After each step, give me a 2-3 line summary of what you did and what's next, then commit to git.
- Work one numbered step at a time.
