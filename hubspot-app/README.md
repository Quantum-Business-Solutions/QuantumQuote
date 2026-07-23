# QuantumQuote — HubSpot public app (new-platform project)

The deployable HubSpot **developer app** for QuantumQuote, modeled on Marko's
`QuantumLeasingHub` / `DocCommand` app config. This is the OAuth app dealers
install so the configurator can read/write their real HubSpot deal.

> **Why this is separate from the web app.** The configurator UI + Supabase
> edge functions live in the Lovable repo (`quotecommand-0958c73e`). This
> project is only the HubSpot *app definition* (OAuth config + the CRM card
> that iframes to the web app). Same split Marko uses.

## Layout
```
hsproject.json                              platformVersion 2025.2
src/app/quantumquote-app-hsmeta.json        OAuth config: scopes, redirect, permittedUrls
src/app/app-logo.png                        (add a logo)
src/app/cards/quantumquote-card-hsmeta.json card: Deal record tab
src/app/cards/QuantumQuoteCard.tsx          React UI extension → Iframe to the app
```

## Fill in three blanks first
1. **`REPLACE_WITH_QUANTUMQUOTE_SUPABASE_REF`** (3 spots in the app config) —
   QuantumQuote's Supabase project ref (Supabase → Project Settings → API →
   Project URL). This makes the redirect URL
   `https://<ref>.supabase.co/functions/v1/hubspot-oauth-callback`.
2. **`REPLACE_WITH_QUANTUMQUOTE_LOVABLE_APP`** (app config `permittedUrls.iframe`
   and `QuantumQuoteCard.tsx`) — the published Lovable URL for `quotecommand`.
3. After the app is created, put its **Client ID / Secret** into that Supabase
   project's env as `HUBSPOT_CLIENT_ID` / `HUBSPOT_CLIENT_SECRET`.

## Deploy (the CLI step — needs your developer-account login)
The safest route, since the exact 2025.2 project/card conventions must match
what your account already accepts: **copy your proven Sierra (or
QuantumLeasingHub) project folder, drop these QuantumQuote files in, adjust the
iframe URL, and upload.** That guarantees the shell format is one your account
has already deployed.

```sh
# one-time, on your/Marko's machine (opens a browser to auth the dev account)
npm i -g @hubspot/cli
hs init                       # mints a personal access key for the dev account

# from the project folder
hs project upload             # or: hs project dev  (live preview while editing)
```

Then in the developer account: grab the **Client ID/Secret** → set them in the
QuantumQuote Supabase env, and use the app's **install link** to connect the
demo portal (47404459). After that the configurator round-trips against the
real deal.

## Scopes — why each
- `e-commerce` — read the Products price book (the catalog). *(This is the one
  Marko's leasing app didn't need; the configurator does.)*
- `crm.objects.deals.read/write` + `crm.schemas.deals.read/write` — read the
  deal, write line items/rollups, and create the `cpq_*` deal properties.
- `crm.objects.line_items.read/write` — the grouped quote line items.
- `crm.objects.custom.read/write` + `crm.schemas.custom.read/write` — the
  `product_association` rules object (create + read/write rules).
- `crm.objects.contacts.read`, `crm.objects.companies.read`,
  `crm.objects.owners.read` — deal context + approval-task assignment + analytics.
- `settings.users.read` — the roles manager.
- `files` (optional) — attaching documents / uploading product images later.

Changing scopes after dealers install forces them to re-authorize, so lock
this list before sharing the install link.

## Demo portal (47404459) — already provisioned via PAT
Data model is live and demo-ready: 13 `cpq_*` deal properties, 8 product
properties (`rep_floor_cost`, `manufacturer`, `model`, `product_category`, CPQ
flags), 109 products, and the `product_association` object (`2-66268498`) with
25 compatibility rules.
