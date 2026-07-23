import React from "react";
import { hubspot, Flex } from "@hubspot/ui-extensions";
import { Iframe } from "@hubspot/ui-extensions/experimental";

/*
  QuantumQuote CRM card — embeds the configurator (the Lovable/Vite app) on the
  Deal record, passing the portal + deal ids the app reads from its URL params
  (see the web app's useHubSpot readHubSpotParams: portalId, dealId, objectType).
  The iframe host MUST be listed in app-hsmeta.json permittedUrls.iframe.
*/

const APP_BASE = "https://REPLACE_WITH_QUANTUMQUOTE_LOVABLE_APP.lovable.app";

hubspot.extend(({ context }) => <QuantumQuoteCard context={context} />);

function QuantumQuoteCard({ context }) {
  const portalId = context?.portal?.id ?? "";
  const dealId = context?.crm?.objectId ?? "";
  const src =
    `${APP_BASE}/configurator` +
    `?portalId=${encodeURIComponent(String(portalId))}` +
    `&dealId=${encodeURIComponent(String(dealId))}` +
    `&objectType=deals`;

  return (
    <Flex direction="column" gap="sm">
      <Iframe src={src} height="lg" />
    </Flex>
  );
}
