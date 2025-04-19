import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createStandardScrape } from "./create/createStandard.js";
import { createCampaignScrape } from "./create/createCampaign.js";
import { retrieveStandardScrape } from "./retrieve/retrieveStandard.js";
import { retrieveCampaignScrape } from "./retrieve/retrieveCampaign.js";

serve(async (req) => {
  try {
    const body = await req.json();

    let result;
    switch (body.method) {
      case "create":
        result =
          body.target === "standard"
            ? await createStandardScrape()
            : await createCampaignScrape();
        break;
      case "retrieve":
        result =
          body.target === "standard"
            ? await retrieveStandardScrape()
            : await retrieveCampaignScrape();
        break;
      default:
        throw new Error(`Unsupported method: ${body.method}`);
    }

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        data: null,
        error: {
          message:
            error instanceof Error ? error.message : "Unknown error occurred",
          details: error instanceof Error ? error.stack : undefined,
          raw: error,
        },
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
