# QuantumQuote — HubSpot public app (Developer Platform project)

The deployable HubSpot **developer app** for QuantumQuote — the OAuth app
dealers install so the configurator can read/write their real HubSpot deal.
Layout + conventions match the proven Sierra project (platform `2026.03`) and
the OAuth config matches Marko's `QuantumLeasingHub`.

> **Separate from the web app on purpose.** The configurator UI + Supabase edge
> functions live in the Lovable repo (`quotecommand-0958c73e`). This project is
> only the HubSpot *app definition* (OAuth config + the CRM card that iframes
> the web app onto the Deal).

## Layout (matches Sierra)
```
hubspot-app/
├── hsproject.json                             # name · srcDir · platformVersion 2026.03
└── src/app/
    ├── app-hsmeta.json                        # OAuth config: scopes · redirect · permittedUrls
    ├── app-logo.png                           # ADD a logo file
    └── extensions/
        ├── quantumquote-card.hsmeta.json      # card on the Deal record tab
        ├── QuantumQuoteCard.jsx               # React UI extension → Iframe to the app
        └── package.json                       # REQUIRED — see gotcha below
```

## Fill three blanks before uploading
1. **`REPLACE_WITH_QUANTUMQUOTE_SUPABASE_REF`** (3 spots in `app-hsmeta.json`) —
   QuantumQuote's Supabase project ref (Supabase → Project Settings → API →
   Project URL). Redirect becomes
   `https://<ref>.supabase.co/functions/v1/hubspot-oauth-callback`.
2. **`REPLACE_WITH_QUANTUMQUOTE_LOVABLE_APP`** (`app-hsmeta.json`
   `permittedUrls.iframe` + `QuantumQuoteCard.jsx`) — the published Lovable URL
   for `quotecommand`.
3. After first upload, copy the app's **Client ID / Secret** (Auth tab in
   project details) into that Supabase project's env as `HUBSPOT_CLIENT_ID` /
   `HUBSPOT_CLIENT_SECRET`.

## Deploy — the CLI step (your developer-account login)
```sh
npm install -g @hubspot/cli@latest      # v7.6.0+
hs account auth --pak                    # paste a Personal Access Key; name the account
hs account list                          # confirm it points at the QBS developer account

cd hubspot-app
hs project lint --install-missing-deps   # catches the missing package.json class of bug
hs project upload --forceCreate          # builds + auto-deploys
hs project info                          # shows build #, app ID, auth type
```
Then: **Client ID/Secret → Supabase env** (step 3 above), and connect a portal
via the app's **OAuth install URL** (Client ID + redirect + scopes). Authorizing
hits our `hubspot-oauth-callback` and stores the encrypted tokens — after that
the configurator round-trips against the real deal.

> **oauth vs. static (why we differ from Sierra).** Sierra used
> `auth.type: "static"` + `distribution: "private"` because its card was just an
> iframe to a public page — no backend token exchange. QuantumQuote reads/writes
> the CRM through Supabase using the **OAuth authorization-code flow**, so it
> must be `auth.type: "oauth"`. That also means you connect portals via the
> **install URL**, not `hs project install-app` (which is the static-private path).

## The gotcha that cost Sierra the most time
Every extension subfolder needs its **own `package.json`** naming its runtime
deps, or the build **silently skips the card** as "not a real component."
That's why `extensions/package.json` exists here. `hs project lint
--install-missing-deps` surfaces it before upload.

## Fallback if the native card won't surface
Sierra's remaining friction was 100% HubSpot-UI-side — getting the card to
appear via **Customize → Card library → Card types → App** on the record. If
that stalls, the guaranteed fallback is a plain Deal property holding a link to
the configurator (created in one API call), plus the in-app **"Configure Quote"**
button already in the Document Hub header. So there's always a working entry
point to the deal even before the native card is surfaced.

## Demo portal (47404459) — data model already provisioned (via PAT)
Live and demo-ready: 13 `cpq_*` deal properties, 8 product properties
(`rep_floor_cost`, `manufacturer`, `model`, `product_category`, CPQ flags), 109
products, and the `product_association` object (`2-66268498`) with 25
compatibility rules.
