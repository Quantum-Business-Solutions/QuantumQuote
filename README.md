# QuantumQuote

A HubSpot-native **copier / office-equipment CPQ** — QBS's own configure-price-quote engine (an alternative to KeyPoint's Quote IQ) so we control the quoting process and keep the recurring revenue.

> **Principle:** HubSpot is the system of record; the app is the engine.
> The catalog and the signed deal live natively in HubSpot; the compatibility
> rules, pricing, leasing math, and proposal generation live in the app.

## v1 scope

One job: **configure a copier deal → price it → push it to HubSpot as a Deal with line items → get it signed.** Current-state / renewal / ERP-ingestion (installed base, leases, competitive takeout) is deliberately **phase 2**.

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
