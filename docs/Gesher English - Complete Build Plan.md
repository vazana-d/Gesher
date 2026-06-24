# Gesher English — Complete Build Plan

*Your only paid tool is Claude Pro. At pilot scale, everything else here — database, email, video, and hosting — runs on free tiers. Total extra cost: about $0.*

---

## 1. The toolkit (all free except Claude Pro)

| Tool | What it does | Cost |
|---|---|---|
| **Claude Code** (via your Claude Pro) | Writes and edits the whole app with you | Included in Pro |
| **VS Code** | The editor you run Claude Code in | Free |
| **Node.js (LTS)** | Runs the project on your computer | Free |
| **Git + GitHub** | Saves your code; connects to hosting | Free |
| **Next.js + React + TypeScript + Tailwind** | The app itself (one codebase, all devices) | Free / open-source |
| **Supabase** | Login, database, file storage, security rules | Free tier |
| **Daily.co** | The video calls (embedded) | Free tier* |
| **Resend** | Sends the "you've been matched" email | Free tier (3,000/mo) |
| **Vercel** | Hosts the live website | Free Hobby tier |

*Daily's free tier doesn't include recording. For oversight without paying, have an **adult coordinator able to join any call** instead (see Section 4). A fully-free, no-account alternative is **Jitsi Meet** (open-source, embeddable) if you'd rather avoid Daily.

**Three free-tier facts to know now:**
- **Claude Pro** shares a rolling ~5-hour usage window (and weekly caps) across all Claude apps — so build in focused sessions; if you hit a limit, you pause and continue when it resets.
- **Supabase free** pauses a project after ~1 week of no activity — just log in/use it weekly to keep it awake.
- **Vercel Hobby** is for non-commercial/personal use — a free passion project qualifies; you'd only need a paid plan if it ever became a commercial product.

---

## 2. How the pieces fit

A phone or laptop opens your **Next.js site on Vercel**. The site talks to **Supabase** for login, data, and the homework photos. When it's session time, the site opens a **Daily** video room. When a pairing is made, a **Resend** email goes to the student. Anything sensitive (video tokens, sending email, admin actions) runs on the **server side**, never in the browser, so secret keys are never exposed.

---

## 3. Set these up first (one-time)

1. Install **Node.js (LTS)**, **VS Code**, and **Git**.
2. Create a **GitHub** account and a new empty repo.
3. Create a **Vercel** account and connect it to GitHub.
4. Create a **Supabase** project — save the Project URL and the two keys (anon + service role). The service role key is secret.
5. Create a **Daily.co** account — save the API key (secret).
6. Create a **Resend** account — save the API key (secret).
7. Open VS Code, open a terminal, and start **Claude Code** (log in with your Claude Pro account).

You'll paste the secret keys into a file called `.env.local` (and into Vercel's settings later). They must **never** be committed to GitHub — Claude Code will set up `.gitignore` to prevent that.

---

## 4. Storing data safely (read this before building)

Your app holds minors' data, so this section is the real project — don't let any AI tool "vibe" past it.

- **Row-Level Security (RLS) on every table.** This is the core. Supabase lets you write rules so a student or tutor can read/write **only the rows tied to their own pairing**, and only an **admin** can see everything. Without RLS, anyone could read everyone's data.
- **Private file storage.** Homework photos go in a **private** Supabase bucket. The app shows them through short-lived **signed URLs** to the matched pair only — never a public link.
- **Secrets stay server-side.** The Supabase *service role* key, Daily key, and Resend key live only in environment variables used by server code (Next.js route handlers / Supabase Edge Functions). The browser only ever gets the public *anon* key.
- **HTTPS everywhere.** Automatic on Vercel — data is encrypted in transit.
- **Collect the minimum.** First name + last initial, grade, language, email. Nothing you don't need. Less data = less risk.
- **Consent before activity.** A new user stays **Pending** until an admin records parental consent; only then can they be paired.
- **Adult oversight.** The coordinator can join any call; sessions are scheduled and logged; a **Report a concern** button reaches the admin. No private contact info is ever exchanged in-app.
- **A short privacy policy** explaining what you store and why, plus a way for a parent to ask for deletion.

> Both tutors and students are minors. Build the app, but run it under a partner org's child-protection framework (Israel Connect / Skilled Volunteers for Israel) with a real adult supervisor. The software enforces the rules; the adults own the safety.

---

## 5. Works on every device

- **Mobile-first** design with Tailwind's responsive breakpoints, so it reflows from phone to laptop automatically. Most kids will use phones — design for that first.
- **PWA**: add a web-app manifest so it can be "installed" on a phone home screen and feels like an app.
- **Hebrew = right-to-left.** The layout flips direction when the language is Hebrew (`dir="rtl"`). Build this in from the start; it's painful to retrofit.
- **Test matrix:** your own phone, a laptop, and Chrome's device-emulator. Check the camera upload and a video call on an actual phone before launch.

---

## 6. Data model & pairing rules

**Tables:** `profiles` (role, first name + last initial, grade, language, status pending/active, consent timestamp), `matches` (student, tutor, status), `sessions` (match, time, video room, status), `homework` (match, student, file path, note), `reports` (reporter, match, message).

**Pairing rules to enforce in code + RLS:**
- Only **Active** users can be paired.
- Admin **proposes** a pairing; the **tutor accepts or declines** (tutors never browse students).
- **One active pairing per person** (strict 1:1).
- If a student quits, the tutor/admin can **Drop** it → status `Ended`, which frees both to be re-paired.
- When a pairing goes **Active**, the student gets an **in-app message + Resend email**.

---

## 7. Build it step by step (drive Claude Code one step at a time)

Paste your kickoff prompt first (you have it), then go step by step. Commit to GitHub after each step. Test before moving on.

1. **Skeleton + go live.** "Scaffold a Next.js + TypeScript + Tailwind PWA, set up the Supabase client and `.env.local` with `.gitignore`, and deploy a blank page to Vercel from GitHub." *Goal: a live URL on day one.*
2. **Database + security.** "Create the five tables above with RLS policies so users see only their own pairing's rows and only admin sees all. Give me the SQL and a test proving a student can't read another pairing's data."
3. **Login + roles + language.** "Add Supabase email login, role-based dashboards (student/tutor/admin), and a Hebrew/English toggle with full RTL support."
4. **Sign-up profile.** "On sign-up, collect role, first name + last initial, grade, and language; new accounts start as Pending."
5. **Admin approval + consent.** "Build admin screens to approve a Pending user, record parental consent (timestamp), and set them Active."
6. **Pairing + notification.** "Admin proposes a pairing; the tutor accepts/declines; enforce one active pairing per person; allow Drop → Ended; on Active, send the student an in-app message + a Resend email."
7. **Homework upload.** "Let a student photograph homework with the phone camera, store it in a private Supabase bucket, and show it to the matched tutor via a signed URL only."
8. **Video call.** "Add a server route that mints a Daily room + join token for a session, limited to the matched pair + admin; build the Join screen showing the homework beside the call."
9. **Safety + polish.** "Add the Report-a-concern button, the PWA manifest, and make every screen responsive; test on a phone."
10. **Launch checks.** "Help me test the full flow with fake student/tutor/admin accounts, verify RLS blocks cross-user access, and write a short privacy policy." Then add your real env keys in Vercel and go live.

---

## 8. Safe-data checklist (tick before a real kid logs in)

- [ ] RLS on every table, tested with fake accounts (a student cannot see another pair's data).
- [ ] Homework bucket is private; access only via signed URLs.
- [ ] No secret keys in the browser or in GitHub; all in env vars.
- [ ] Parental consent recorded before any user is Active.
- [ ] Calls limited to the matched pair (+admin); adult can join; Report button works.
- [ ] Privacy policy published; data kept minimal; deletion path exists.
- [ ] Tested on a real phone (camera + video) and a laptop.

---

## 9. Reality checks

- **Claude Pro limits:** you'll build in ~5-hour bursts; if you hit a cap, save your progress (commit to GitHub) and continue after it resets. The step-by-step approach above fits this well.
- **Keep Supabase awake:** use the project at least weekly so the free tier doesn't pause it.
- **Vercel Hobby = non-commercial:** fine for a free passion project; revisit only if it ever becomes a paid product.

---

## 10. Cost summary

Everything above runs at **$0** on free tiers at pilot scale. Your **only** cost is the **Claude Pro** subscription you already have. You won't need to pay for a host until (and unless) the project outgrows the free tiers — which, for a pilot of a dozen pairs, it won't.

---

**Sources:** [Use Claude Code with Pro/Max](https://support.claude.com/en/articles/11145838-use-claude-code-with-your-pro-or-max-plan) · [Claude usage limits](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work) · [Supabase pricing](https://supabase.com/pricing) · [Vercel Hobby plan](https://vercel.com/docs/plans/hobby) · [Resend free tier](https://resend.com/pricing)
