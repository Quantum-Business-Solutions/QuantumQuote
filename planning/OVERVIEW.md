# QuantumQuote

A HubSpot-native **copier / office-equipment CPQ** — QBS's own configure-price-quote engine (an alternative to KeyPoint's Quote IQ) so we control the quoting process and keep the recurring revenue.

> **Principle:** HubSpot is the system of record; the app is the engine.
> The catalog and the signed deal live natively in HubSpot; the compatibility
> rules, pricing, leasing math, and proposal generation live in the app.

## v1 scope

One job: **configure a copier deal → price it → push it to HubSpot as a Deal with line items → get it signed.** Current-state / renewal / ERP-ingestion (installed base, leases, competitive takeout) is deliberately **phase 2**.

## Shipped in the live app (as of Jul 23 2026)

The production app is **`Quantum-Business-Solutions/quotecommand-0958c73e`** (Lovable-connected). Everything below is built, build-verified, and on `main`:

- **Configurator** `/configurator`: rules engine (required / default / choose-one / dependencies / qty limits / excludes), real margins from `rep_floor_cost` with sell-price lift lever, payment-first quoting ("quote to a payment"), live lease rate cards (funder + program + amount band), trade-up buyout (Tascosa formula chain), fleet templates + CSV fleet import + duplicate machine, per-machine locations, volume duty-cycle warnings, auto fleet discounts (2/4/6% @ 5/10/25 units), tiered overage bands, partial pooling groups, service term independent of lease, machine comparison, config-validity gate, demo mode, first-run tour, tablet-friendly.
- **Round-trip**: live HubSpot price book in; grouped line items out (`machine_group` + `line_role`); deal writeback (`amount`, `cpq_lease_monthly_payment`, `cpq_service_monthly_total`, `cpq_blended_margin`, `cpq_approval_status`, buyout inputs).
- **Guardrails**: blended margin < 20% or below-floor → `hubspot-approval-task` creates an owner-assigned HubSpot task and flags the deal pending.
- **Renewal pipeline**: every pushed lease seeds the future upgrade deal (lease-end − 6 mo) via `hubspot-renewal-seed`, idempotent.
- **Proposals**: branded customer PDF (margin structurally excluded), good/better/best option snapshots, editable exec summary, lease-vs-cash comparison, 30-day validity.
- **Drafts & versions**: `quote-versions`-backed save/restore with resume-draft prompt; every push/approval auto-snapshots.
- **Admin** `/admin/cpq` + `/admin/onboarding`: rules editor, lift-% pricing (rep floor = dealer cost × (1 + lift)), discount authority by role, rate-sheet management, guided dealer onboarding checklist.
- **Analytics** `/analytics`: margin KPIs + histogram, by-rep table, win/loss with reasons, renewals radar, quote audit feed.

This planning repo remains the design source (schemas, seeds, provisioning script, pricing one-pager in `business/`).

## What's in this repo

```
prototype/configurator.html      Interactive prototype — the target UX (open in a browser)
docs/data-model.html             Data model, flow, and "what's where" across portals
docs/engineering-review.html     Review brief (design decisions + open questions)
hubspot/
  properties/product.properties.json      cpq_* flags, costs, manufacturer/model, category
  properties/line_item.properties.json    line_role + machine_group (grouping)
  schemas/product_association.schema.json  the rules custom object
  seed/products.json                       real Canon catalog seed
  seed/product-associations.rules.json     compatibility rules (requires/excludes/one_of/default)
scripts/provision-portal.sh       Stands the whole data model up in a portal via PAT
```

## Data model (the four objects that matter)

| Object | Where | Role |
|---|---|---|
| `product` | HubSpot native | Price book + `cpq_*` control flags + `rep_floor_cost` |
| `product_association` | HubSpot custom object | Compatibility **rules** (`rule_type`, `group_id`, qty) — synced to the app for evaluation |
| `quote_configurations` | App (Supabase) | The live build + commercial terms (JSONB) |
| `line_item` | HubSpot native | Resolved output, **grouped by machine** via `machine_group` + `line_role` |

## Key finding (verified live in a demo portal)

**HubSpot allows no programmatic line-item → line-item association.** Native
Parent/Child types are read-only (reserved for its bundle feature) and custom
labels are disallowed between line items (`allowsCustomLabels=false`). So the
machine → options tree is expressed with a **grouping property**
(`machine_group` + `line_role`), *not* an association. This is what the app's
writeback sets.

Also: newly-created HubSpot properties take ~a couple minutes to propagate
before writes stick — relevant for any provisioning/writeback code.

## Provision a portal

```bash
export HUBSPOT_TOKEN="pat-..."      # a HubSpot private-app token (never commit this)
./scripts/provision-portal.sh
```

Creates the properties, the `product_association` object, seeds the Canon
catalog, and loads the compatibility rules. Idempotent-ish (existing objects
409 and are skipped).

## Build path

- **Already built** (in the existing QBS document app): HubSpot OAuth + read/write, line-item writeback, quote versions/templates, leasing rate-card engine, pricing tiers, document generation, field mappings, roles, multi-tenant settings.
- **Extend:** standardize `cpq_*` flags + rep/dealer cost; add dynamic pricing rules.
- **Net-new:** rule fields on `product_association` + the guided-selling **configurator UI** and its rules-evaluation engine (see `prototype/configurator.html`).

## The configurator interface

The UX lives as a module inside the existing QBS app (Lovable + React + Supabase,
embedded on the HubSpot deal via OAuth) — not a separate new app. The
`prototype/configurator.html` here is the design reference for that module.
