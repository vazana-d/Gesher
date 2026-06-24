# Lantern — Start Here (Day 1)

*Working name: **Lantern** (easy to change later). Today's only goal: install your tools and get a blank page live on the internet. That's a real win — don't build features yet.*

---

## A. Install your tools (Windows)

1. **Node.js (LTS)** — https://nodejs.org → download the **LTS** version, install with the defaults. (Runs the project.)
2. **Git for Windows** — https://git-scm.com/downloads/win → install with defaults. (Claude Code uses it.)
3. **VS Code** — https://code.visualstudio.com → install. (Where you'll work.)
4. **Claude Code** — open **PowerShell** (search "PowerShell" in the Start menu) and paste:
   ```
   irm https://claude.ai/install.ps1 | iex
   ```
   *Prefer no terminal? Download the Claude Code desktop app instead: https://claude.com/download*
5. **Check it worked:** in PowerShell type `claude --version`. If it shows a version number, you're set. (If it says "not recognized," close PowerShell, reopen it, and try again.)

## B. Accounts

- **GitHub** — https://github.com → sign up (this stores your code).
- **Vercel** — finish the signup you already started: choose **Hobby** ("personal projects"), name it (e.g. `lantern`), and connect it to GitHub when asked.
- *Supabase, Daily, and Resend come later — only at the step that needs them.*

## C. Start Claude Code

1. Make a folder for the project, e.g. `Documents\lantern`.
2. Open that folder in **VS Code** → open a terminal (top menu: **Terminal → New Terminal**).
3. Type `claude` and press Enter. Log in with your **Claude Pro** account in the window that opens.

## D. Paste this first (Step 1 — get a blank page live)

```
You're helping me build a tutoring web app, working name Lantern. I'm a
high-school student — explain each step simply and do ONE step at a time,
stopping after each.

Context: American Jewish high-school volunteers tutor war-disrupted Israeli
students in English. A student photographs their homework; their matched
tutor sees it and they do a live video call to work through it. An adult
admin approves users, records parental consent, and creates the matches.

Stack (all free tiers): Next.js (App Router) + TypeScript + Tailwind,
mobile-first PWA, with full Hebrew right-to-left support. Supabase for auth,
database, storage, and Row-Level Security. Daily.co for video later. Resend
for email later. Deploy to Vercel. All secret keys stay server-side in env
vars; set up .gitignore so nothing secret is ever committed.

Do STEP 1 ONLY now: scaffold the Next.js + TypeScript + Tailwind project as a
PWA, initialize git, push it to a new GitHub repo, and deploy a blank
placeholder page to Vercel so I have a live URL. Walk me through any account
connections or keys you need and exactly where to paste them. Then STOP and
wait for me before Step 2. Do not build features yet.
```

## E. Then come back here

When the blank page is live (Vercel gives you a `…vercel.app` link), **paste me the link** — or paste any **error** you hit — and we'll do **Step 2 (the database + security)** together. One step at a time.

---

*Source for the Claude Code install command: Anthropic's official Claude Code docs (code.claude.com/docs/en/setup).*
