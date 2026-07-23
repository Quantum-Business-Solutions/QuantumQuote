# QuantumQuote — build session handoff (2026‑07‑23)

Autonomous backend session. Goal: make the app more "buy‑it‑now" and, above all,
**cloneable to any dealer**. Worked backend/data lanes only (edge functions, new
files, HubSpot config, planning) so as not to collide with Lovable's live
frontend edits.

## What shipped (all committed + pushed to `quotecommand-0958c73e@main`)

| Deliverable | File | What it does |
|---|---|---|
| Dynamic compatibility rules | `supabase/functions/hubspot-get-associations` | Reads the connected portal's `product_association` object → rule list for the configurator. Resolves the object **by name** per portal (never hardcodes a type ID). Empty → clean fallback to built‑in rules. |
| **Clone engine** | `supabase/functions/cpq-provision` | One idempotent call makes a freshly‑connected portal QuantumQuote‑ready: creates the missing Deal `cpq_*` props (13), Product CPQ props (19), line‑item grouping props, and the `product_association` + `QuoteCommand` custom objects with Deal/Company associations. `dryRun` for a safe preview. **This is what makes onboarding a new dealer one step.** |
| Quotes → HubSpot | `supabase/functions/hubspot-quotecommand` | `push` a finalized quote into the `QuoteCommand` custom object (associated to Deal + Company via the v4 *default* endpoint); `list` a deal's quotes back by `source_deal_id`; `delete`. Writable props whitelisted; type ID resolved by name. |
| Service‑rate engine | `src/lib/serviceRates.ts` | Pure, tested module: 6‑group rate card, machine→group resolution (explicit `service_rate_group` tag → `cls` → environment+color → fallback), and `computeServiceMonthly()` returning revenue/cost/margin with included‑volume + overage tiers and per‑page overrides. Numerically verified. |
| Schema map (corrected) | artifact (link in chat) | Now **portal‑agnostic** — the two custom objects are shown as *provisioned per dealer portal, resolved by name*, not as hardcoded type IDs/record counts (which are per‑portal and don't belong on a canonical map). |

## Verified this session
- `bun run build` → **exit 0** (app compiles clean with all new functions present).
- `serviceRates.computeServiceMonthly` math: at‑allotment 4k mono / 3k color on an A3 color workgroup = **$179 rev / $100 cost / 44.1% margin**; overage tiers and resolution precedence all correct.
- HubSpot OAuth app **build #7 = deployed / SUCCESS** in dev portal 20682069: 23 scopes, connector redirect `https://connector-gateway.lovable.dev/...`, marketplace distribution. Dealers can install + connect.

## Key finding — two portals (this is the multi‑tenant model working, not a gap)
- **20682069 = Quantum's developer / vendor account.** The OAuth *app* lives here. It correctly has **none** of the CPQ dealer schema (verified directly: 0 CPQ custom objects, 0 `cpq_*` deal props). The PAT in this environment is scoped to this portal and to custom‑object/schema only (no products scope).
- **47404459 = the demo *dealer* portal ("Q Squared").** The actual CPQ objects, products, and rules live here, connected through the Lovable connector. The vendor PAT can't reach it — which is exactly right: dealer data never sits in the vendor account.
- Implication: the schema map's earlier hardcoded `2‑66268498 / 2‑66321846 / 6,787 records` were per‑portal facts for 47404459, unverifiable from the vendor token. The map is now portal‑agnostic, so it's correct for **any** dealer.

## Handoff to Lovable — three small frontend wires (backend is ready)
1. **Service rates** — in the configurator, per machine:
   ```ts
   import { computeServiceMonthly } from "@/lib/serviceRates";
   const svc = computeServiceMonthly(expMonoPerMo, expColorPerMo, {
     group: product.service_rate_group, cls: machine.cls, color: machine.color, env: machine.tags?.join(" "),
   });
   // svc.monthlyRevenue / svc.monthlyCost / svc.monthlyMargin → roll into monthly total + margin
   ```
2. **Dynamic rules** — feed the rules engine from the live object:
   ```ts
   const { data } = await supabase.functions.invoke("hubspot-get-associations",
     { body: { portalId, dealerId, base_sku: machine.sku } });
   // data.rules → same shape the built‑in rules use
   ```
3. **Commit a quote to HubSpot** — on "save/commit":
   ```ts
   await supabase.functions.invoke("hubspot-quotecommand",
     { body: { action: "push", portalId, dealId, companyId, quote: {/* QC fields */} } });
   // list: { action: "list", dealId } → quotes[]
   ```
4. **On new‑dealer connect** (once): `supabase.functions.invoke("cpq-provision", { body: { dealer_id } })`.

## Still open
- #25 configurator rewire (Lovable's lane — `useCatalog.ts` already pages + caps + is rules‑ready).
- #23 converge on the single HubSpot deal (retire localStorage deals store) — do after Lovable finishes the Documents tab.
- Demo‑dealer (47404459) data‑quality pass (rate‑group tagging, base‑machine/spec cleanup) — needs a products‑scoped token for that portal.
