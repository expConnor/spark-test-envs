import { supabaseClient } from "../../_shared/supabaseClient.js";
import { getAccountUrls } from "./utils/getAccountUrls.js";
import { getScheduledPostUrls } from "./utils/getScheduledPostUrls.js";
import { callScrapers } from "./utils/callScraperApis.js";
import { insertDatasetIds } from "./utils/insertDatasetIds.js";

export async function createStandardScrape() {
  try {
    //#1: Get Account URLs and account IDs
    const accountUrls = await getAccountUrls(supabaseClient);

    //#2: Get scheduled Post URLs and post IDs
    const scheduledPostUrls = await getScheduledPostUrls(supabaseClient);

    // EARLY EXIT: If no accounts and no scheduled posts, exit function immediately
    if (accountUrls.length === 0 && scheduledPostUrls.length === 0) {
      return {
        success: false,
        data: { message: "No Instagram accounts or scheduled posts found" },
        error: null,
      };
    }

    // Call Scraper APIs
    const scraperResult = await callScrapers(accountUrls, scheduledPostUrls);
    if (!scraperResult.success) {
      return scraperResult;
    }

    // Insert defaultDatasetIDs into supabase table
    await insertDatasetIds(
      "instagram-scraper",
      "standard",
      scraperResult.data.profileScraperResponse,
      scraperResult.data.postScraperResponse
    );

    return {
      success: true,
      data: {
        accountUrls,
        scheduledPostUrls,
        datasetIds: {
          profileScraper:
            scraperResult.data.profileScraperResponse?.data?.defaultDatasetId ||
            null,
          postScraper:
            scraperResult.data.postScraperResponse?.data?.defaultDatasetId ||
            null,
        },
      },
      error: null,
    };
  } catch (error) {
    console.error("Error in createStandardScrape:", error);

    // Get the actual error message
    let errorMessage = "An unknown error occurred";
    if (error instanceof Error) {
      errorMessage = error.message;
    } else if (typeof error === "string") {
      errorMessage = error;
    } else if (error && typeof error === "object" && "message" in error) {
      errorMessage = error.message;
    }

    return {
      success: false,
      data: null,
      error: {
        message: errorMessage,
        details: error instanceof Error ? error.stack : undefined,
        raw: error,
      },
    };
  }
}
