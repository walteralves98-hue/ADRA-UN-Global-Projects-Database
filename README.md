# ADRA–UN Global Projects Database

A public, searchable ADRA–UN partnership directory (2015 onward) with Supabase-backed authenticated editors, evidence links, dashboard, filtering, CSV import/export, and GitHub/Vercel deployment.

## What is included

- Seven individually sourced **starter records**; these are **not** a comprehensive inventory. Missing budgets and project dates are intentionally not invented. A source may describe a collaboration rather than a formally awarded grant.
- Public users see **published** records only. Authenticated `editor` and `admin` roles can view drafts, add/edit/delete records, and bulk-import CSV. `viewer` users cannot edit.
- A static **preview mode** shows seven records without Supabase. Preview cannot save changes. Once Supabase is configured, the app uses database records only.
- CSV export reflects currently filtered records; CSV import validates required fields and URLs and confirms before insertion. Imports are additive, not deduplicated.

## 1. Create Supabase database

1. Create a free project at https://supabase.com.
2. Open **SQL Editor** and run `supabase/schema.sql`.
3. In SQL Editor run `supabase/seed.sql` to add the seven public, source-backed records. Only run it once; it is idempotent by source/title/year.
4. Go to **Authentication → Users → Add user**. Create your admin user, preferably with email confirmation and a temporary password.
5. Copy the user's UUID, then in **SQL Editor** run:

```sql
insert into public.staff_profiles (user_id, role)
values ('YOUR-AUTH-USER-UUID', 'admin')
on conflict (user_id) do update set role = 'admin';
```

6. For each editor, create a Supabase Auth user and assign `editor` similarly. Staff may reset passwords using the Supabase password recovery flow. This app currently offers password sign-in, not an in-app password reset form. Admin role grants database-level profile management but the app does not yet provide a user-management UI.
7. In **Project Settings → API** copy Project URL and **publishable/anon** key (never the `service_role` key).

## 2. Run locally

```bash
npm install
cp .env.example .env.local
# edit .env.local with your Supabase values
npm run dev
```

On Windows, copy `.env.example` to `.env.local` manually or use `copy .env.example .env.local`.

## 3. Deploy to GitHub + Vercel

1. Create a new GitHub repository and upload this project's **contents**, keeping `package.json` at repository root.
2. Import the GitHub repo in https://vercel.com/new.
3. Framework: **Vite**. Build command `npm run build`, output directory `dist`.
4. In Vercel Project Settings → Environment Variables, add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` using the values from Supabase. Redeploy.
5. In Supabase **Authentication → URL Configuration**, set your deployed Vercel URL as Site URL. If using email invitations or password recovery, configure redirect URLs and email delivery settings as appropriate.
6. Test the site in an incognito window: only published projects should be visible. Sign in as an editor and test create, edit, delete, and import.

## 4. CSV import

Use `supabase/starter-projects.csv` as a sample. Required columns: `title`, `country`, `office`, `agency`, `year` (>=2015), `source_url` (http/https). Other supported columns: `region`, `sector`, `status`, `relationship`, `description`, `source_title`, `verification`, `budget_usd`, `beneficiaries`, `published`.

- Set `published=true` to expose a row publicly; otherwise it is saved as draft.
- Only enter `budget_usd` when the source identifies the amount attributable to the project. Do not substitute country-level or partnership-wide totals.
- Source-backed means the record has an identified supporting source; it does **not** mean every field is independently verified.
- Add official project dates, grant identifiers, donor distinctions, and multi-agency relationships in a future schema expansion as needed.

## Data quality and completeness

This is a functional **initial release**, not an exhaustive scrape of all ADRA offices or all UN agencies. A complete historical inventory will require office-level reports, UN award data, source reconciliation, and staff validation. Public sources can substantiate a subset; records not identified must not be assumed nonexistent. Agency collaboration does not automatically imply UN funding.

## Security

Supabase RLS is the authorization boundary; UI-only controls do not grant permissions. Never commit `.env.local`. Do not put a Supabase service role key in `VITE_` variables. Only public information should be marked `published`. For production use, review staff permissions, rate limits, audit history, backup policies, and privacy before importing sensitive records.
