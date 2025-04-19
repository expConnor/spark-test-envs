import { getCampaignedPostUrls } from "./utils/getCampaignedPostUrls.js";
import { callScrapers } from "./utils/callScraperApis.js";
import { insertDatasetIds } from "./utils/insertDatasetIds.js";

export async function createCampaignScrape() {
  try {
    // Get campaigned Post URLs and post IDs
    const campaignedPostUrls = await getCampaignedPostUrls();
    // EARLY EXIT: If no campaigned posts, exit function immediately
    if (!campaignedPostUrls.length) {
      return {
        success: true,
        data: {
          message: "No campaigned posts found to scrape",
          postUrls: [],
          datasetIds: {
            postScraper: null,
          },
        },
        error: null,
      };
    }
    // Call Scraper APIs
    const scraperResponse = await callScrapers({
      postUrls: campaignedPostUrls,
    });
    // Insert dataset IDs into Supabase table
    if (scraperResponse.success && scraperResponse.data) {
      const { postScraperResponse } = scraperResponse.data;
      await insertDatasetIds({
        functionName: "tiktok-scraper",
        target: "campaign",
        profileScraperResponse: null,
        postScraperResponse,
      });
    }
    return {
      success: true,
      data: {
        postUrls: campaignedPostUrls,
        datasetIds: {
          postScraper:
            scraperResponse.data?.postScraperResponse?.data?.defaultDatasetId ||
            null,
        },
      },
      error: null,
    };
  } catch (error) {
    console.error("Error in createCampaignScrape:", error);
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
