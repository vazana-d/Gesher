# Supabase — schema, security, and tests

This folder holds the database layer for Lantern (Step 2). Nothing here needs to
run on your PC — it runs inside your Supabase project.

## Files

| File | What it is |
|---|---|
| `migrations/0001_init.sql` | The 5 tables, indexes, helper functions, triggers, and **all RLS policies**. |
| `tests/rls_cross_user_test.sql` | Proves a student can't read another pairing's rows. Self-cleaning (rolls back). |
| `promote_admin.sql` | Promotes one existing auth user to `admin`. Edit the email first. |

## How to apply (after the Supabase project exists)

1. In the Supabase dashboard, open **SQL Editor**.
2. Paste the contents of `migrations/0001_init.sql` and **Run**. (Creates tables + RLS.)
3. Paste `tests/rls_cross_user_test.sql` and **Run**. Success ends with
   `ALL RLS TESTS PASSED`; any leak raises an exception. It rolls back, leaving no data.
4. Create your admin auth user (Dashboard → Authentication → Users → Add user),
   set the email in `promote_admin.sql`, paste it, and **Run**.

## The security model (enforced by RLS)

- **No discovery** — a student/tutor can read only rows tied to their own match;
  profiles are visible only to self, your matched partner, and admins.
- **Consent first** — a `BEFORE` trigger forces new profiles to `pending` and
  blocks anyone but an admin from changing `role` / `status` / `parental_consent_at`.
- **Admin sees all** — every table has an admin-override policy for oversight.
- **One active pairing per person** — partial unique indexes on `matches`.

Storage (private homework bucket + signed URLs) is added in Step 7.
