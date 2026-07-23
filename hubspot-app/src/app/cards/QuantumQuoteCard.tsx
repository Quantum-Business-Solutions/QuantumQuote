import React from "react";
import { hubspot, Iframe } from "@hubspot/ui-extensions";

/*
  QuantumQuote CRM card — renders the configurator (the Lovable/Vite app) in an
  iframe on the Deal record, passing the portal + deal ids the app reads from
  its URL params (see useHubSpot.tsx readHubSpotParams: portalId, dealId,
  objectType). The iframe host MUST be listed in the app config's
  permittedUrls.iframe.

  NOTE: confirm the exact @hubspot/ui-extensions API + card wiring against your
  existing deployed project (Sierra / QuantumLeasingHub). This mirrors the
  standard record-iframe pattern; the surrounding project shell should come
  from a project you've already `hs project upload`-ed so the format is proven.
*/

const APP_BASE = "https://REPLACE_WITH_QUANTUMQUOTE_LOVABLE_APP.lovable.app";

hubspot.extend(({ context }) => <QuantumQuoteCard context={context} />);

function QuantumQuoteCard({ context }: { context: any }) {
  const portalId = context?.portal?.id;
  const dealId = context?.crm?.objectId;
  const src =
    `${APP_BASE}/configurator` +
    `?portalId=${encodeURIComponent(String(portalId ?? ""))}` +
    `&dealId=${encodeURIComponent(String(dealId ?? ""))}` +
    `&objectType=deals`;

  return <Iframe src={src} width="100%" height={900} />;
}
