# Deal property map — configurator ⇄ HubSpot Deal

The configurator writes its results back to the Deal as line items (grouped by
`machine_group` + `line_role`) **plus** these deal-level properties. Input
fields for the incumbent-lease buyout replicate the model proven in the
Tascosa portal (their `buyout___*` properties and calculation chain).

## Buyout / trade-up (rep inputs)
| App field | Demo-portal property | Tascosa equivalent |
|---|---|---|
| Incumbent payment amount | `cpq_buyout_payment_amount` | `buyout_payments` |
| Payments remaining | `cpq_buyout_payments_remaining` | `buyout___payment_remaining` |
| Early termination fee | `cpq_buyout_early_termination_fee` | `buyout___early_termination_fee_` |
| Return shipping | `cpq_buyout_return_shipping` | `buyout___return_shipping_` |

**Math (mirrors Tascosa's calculated properties):**
- `total_buyout = payment_amount × payments_remaining + early_termination_fee + return_shipping`
- `lease_payment_with_buyout = (equipment_amount + total_buyout) × lease_rate_factor`
  (Tascosa keeps three rate slots — `lease_rate`, `lease_rate_2`, `lease_rate_3` —
  to compare funders/terms side by side.)

## Configurator writeback (computed, app → deal)
| App value | Demo-portal property |
|---|---|
| Committed monthly service revenue | `cpq_service_monthly_total` |
| Monthly equipment lease payment | `cpq_lease_monthly_payment` |
| Blended equipment margin % | `cpq_blended_margin` |
| Approval state (`not_required/pending/approved/rejected`) | `cpq_approval_status` |
| Deal amount (equipment total) | native `amount` |

Per-dealer portals with different property names go through the app's existing
field-mapping layer (`field-mappings-save` / dealer account settings) — the map
above is the canonical app-side vocabulary.

## Lease rate factors (already built, app-side)
`uploaded_rate_sheets` → `lease_rate_factors` (`leasing_company`,
`lease_program`, `min_amount`–`max_amount` band, `term_months`,
`rate_factor`), served by the `get-rate-factors` edge function. The
configurator's term/type selector should list live funders + programs from
this table and pick the factor by equipment-amount band, falling back to the
bundled sample factors when no sheet is uploaded.
