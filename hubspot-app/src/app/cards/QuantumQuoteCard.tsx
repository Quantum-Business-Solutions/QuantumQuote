import React from "react";
import { hubspot, Flex } from "@hubspot/ui-extensions";
import { Iframe } from "@hubspot/ui-extensions/experimental";

/*
  QuantumQuote card — embeds the configurator on the Deal record. The iframe
  host MUST be listed in app-hsmeta.json permittedUrls.iframe. The app reads
  portalId + dealId from the URL (see the web app's useHubSpot readHubSpotParams).

  NOTE ON AUTH: QuoteCommand authenticates app users through Lovable's App User
  Connector. When embedded here, confirm the iframe session carries that
  connection (the standalone "Connect HubSpot" login) — otherwise the card may
  prompt the rep to connect once inside the frame.
*/

const APP_BASE = "https://REPLACE_WITH_QUANTUMQUOTE_LOVABLE_APP.lovable.app";

hubspot.extend(({ context }) => <QuantumQuoteCard context={context} />);

function QuantumQuoteCard({ context }: { context: any }) {
  const portalId = context?.portal?.id ?? "";
  const dealId = context?.crm?.objectId ?? "";
  const src =
    `${APP_BASE}/configurator` +
    `?portalId=${encodeURIComponent(String(portalId))}` +
    `&dealId=${encodeURIComponent(String(dealId))}` +
    `&objectType=deals`;

  return (
    <Flex direction="column" gap="sm">
      <Iframe src={src} width="100%" height="lg" />
    </Flex>
  );
}
