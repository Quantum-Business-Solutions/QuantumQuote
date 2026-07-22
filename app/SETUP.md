# QuantumQuote app — standalone setup

This is a **standalone copy** of the QBS document/quoting app (Lovable + React +
Vite + Supabase), imported to build the copier **configurator** into without
touching Marko's live app or its data.

> ⚠️ **Isolation:** this copy is deliberately **not** wired to any backend.
> `.env` was removed and the Supabase `project_id` blanked. Stand up a **new**
> Supabase project — do **not** point it at Marko's project
> (`kafsqolkxnrsjddjkhyc`) or you'd be reading/writing his data.

## Option A — Lovable (fastest, gives a live app + its own Supabase)
1. In Lovable, **duplicate/remix** the source app (or connect a new Lovable project to this repo's `app/` folder).
2. Let Lovable provision a **fresh Supabase project** for it.
3. Run the migrations in `supabase/migrations/` and deploy the functions in `supabase/functions/`.
4. Confirm `VITE_SUPABASE_*` point at the new project.

## Option B — local / manual
```bash
cd app
cp .env.example .env          # fill in a NEW Supabase project's URL + anon key
npm install                   # or: bun install
# apply schema + functions to the new project:
supabase link --project-ref <NEW_REF>
supabase db push
supabase functions deploy
npm run dev
```

## What it already includes (from the source app)
HubSpot OAuth + read/write, line-item writeback (`hubspot-sync-line-items`),
quote versions/templates, leasing rate-card engine, pricing tiers, document
generation, field mappings, roles, multi-tenant `dealer_settings`.

## What we're adding (v1 configurator)
A **Build/Configure** module that reads the `product_association` rules (see
`../hubspot/`), does guided selling (per the prototype in `../prototype/`), and
writes grouped line items (`machine_group` + `line_role`) back to the deal.
