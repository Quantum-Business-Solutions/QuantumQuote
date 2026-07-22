#!/usr/bin/env bash
# Provision a HubSpot portal with the QuantumQuote v1 data model:
#   - custom Product properties (cpq_* flags, costs, manufacturer/model, category)
#   - custom Line Item grouping properties (line_role, machine_group)
#   - the product_association custom object
#   - seed products + compatibility rule records
#
# Auth: private-app token via env var. NEVER hard-code a token in this file.
#   export HUBSPOT_TOKEN="pat-xxxxxxxx"
#   ./scripts/provision-portal.sh
#
# Requires: bash, curl, jq. Idempotency: property/object creates 409 if they
# already exist — safe to re-run; those steps just report the conflict.
set -uo pipefail
: "${HUBSPOT_TOKEN:?Set HUBSPOT_TOKEN (a HubSpot private-app token) before running}"
API="https://api.hubapi.com"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AUTH=(-H "Authorization: Bearer ${HUBSPOT_TOKEN}" -H "Content-Type: application/json")

echo "==> 1/5 Product properties"
jq -c --arg g "productinformation" '.properties[] | . + {groupName:$g}' "$ROOT/hubspot/properties/product.properties.json" |
while read -r p; do
  name=$(jq -r .name <<<"$p")
  code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/crm/v3/properties/products" "${AUTH[@]}" -d "$p")
  echo "   products.$name -> $code"
done

echo "==> 2/5 Line item grouping properties"
jq -c --arg g "lineiteminformation" '.properties[] | del(._note) | . + {groupName:$g}' "$ROOT/hubspot/properties/line_item.properties.json" |
while read -r p; do
  name=$(jq -r .name <<<"$p")
  code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/crm/v3/properties/line_items" "${AUTH[@]}" -d "$p")
  echo "   line_items.$name -> $code"
done

echo "==> 3/5 product_association custom object"
curl -s -X POST "$API/crm/v3/schemas" "${AUTH[@]}" -d @"$ROOT/hubspot/schemas/product_association.schema.json" \
  | jq -r '.objectTypeId // .message // "unknown"' | sed 's/^/   objectTypeId: /'
OBJ=$(curl -s "$API/crm/v3/schemas" "${AUTH[@]}" | jq -r '.results[]|select(.name=="product_association")|.objectTypeId')
echo "   using object: $OBJ"

echo "==> 4/5 Seed products"
curl -s -X POST "$API/crm/v3/objects/products/batch/create" "${AUTH[@]}" -d @"$ROOT/hubspot/seed/products.json" > /tmp/qq_products.json
jq -r '"   created " + ((.results|length)|tostring) + " products (" + (.status // "?") + ")"' /tmp/qq_products.json
jq '[.results[] | {(.properties.hs_sku): .id}] | add' /tmp/qq_products.json > /tmp/qq_skumap.json

echo "==> 5/5 Compatibility rules"
jq -c '.rules[]' "$ROOT/hubspot/seed/product-associations.rules.json" |
while read -r r; do
  bs=$(jq -r .base_sku <<<"$r"); rs=$(jq -r .related_sku <<<"$r")
  bid=$(jq -r --arg k "$bs" '.[$k] // ""' /tmp/qq_skumap.json)
  rid=$(jq -r --arg k "$rs" '.[$k] // ""' /tmp/qq_skumap.json)
  body=$(jq -nc --argjson r "$r" --arg bid "$bid" --arg rid "$rid" \
    '{properties:{association_label:$r.label, base_sku:$r.base_sku, base_product_id:$bid, related_sku:$r.related_sku, related_product_id:$rid, rule_type:$r.rule_type, group_id:$r.group_id, min_qty:($r.min_qty|tostring), max_qty:($r.max_qty|tostring)}}')
  echo "$body"
done | jq -sc '{inputs:.}' > /tmp/qq_assoc.json
curl -s -X POST "$API/crm/v3/objects/$OBJ/batch/create" "${AUTH[@]}" -d @/tmp/qq_assoc.json \
  | jq -r '"   created " + ((.results|length)|tostring) + " rules (" + (.status // "?") + ")"'

echo "Done."
