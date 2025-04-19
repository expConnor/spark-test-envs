import { getDatasetIds } from "./utils/getDatasetIds.js";
import { supabaseClient } from "../../_shared/supabaseClient.js";
import { retrieveDatasetResults } from "./utils/callScraperApis.js";
import { processPostData } from "./utils/processPostData.js";
import { insertProcessedData } from "./utils/insertProcessedData.js";

export async function retrieveCampaignScrape() {
  try {
    // #1: Get Apify Dataset IDs and timestamp from apify_datasets table
    const datasetIds = await getDatasetIds("tiktok-scraper", "campaign");

    // **EARLY EXIT: If no dataset IDs exist, stop execution**
    if (!datasetIds.postScraper) {
      return {
        success: false,
        data: {
          message: "No dataset IDs found",
        },
        error: null,
      };
    }

    // #2: Call APIs to retrieve dataItems from Datasets
    const results = await retrieveDatasetResults("", datasetIds.postScraper);

    // #3: Process the scraper data
    let apifyPostStats = [];
    if (results.data?.postScraperData) {
      apifyPostStats = processPostData(
        results.data.postScraperData,
        datasetIds.createdAt || new Date().toISOString()
      );
    }

    // #4: Insert the processed data
    if (apifyPostStats.length > 0) {
      const processedData = {
        accountImages: [],
        accountStats: [],
        postDetails: [],
        postStats: apifyPostStats,
      };

      // Insert data
      const insertResult = await insertProcessedData(processedData);
      if (!insertResult.success) {
        throw new Error(
          `Failed to insert data: ${insertResult.errorMessages.join(", ")}`
        );
      }
    }

    // #5: Update last_scrape_successful to true in apify_datasets table
    const { error: updateError } = await supabaseClient
      .from("apify_datasets")
      .update({ successful_retrieval: true })
      .eq("id", datasetIds.id);

    if (updateError) {
      throw new Error(
        `Failed to update dataset status: ${updateError.message}`
      );
    }

    return {
      success: true,
      data: {
        apifyStats: apifyPostStats.length,
      },
      error: null,
    };
  } catch (error) {
    console.error("Error in retrieveCampaignScrape:", error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : "Unknown error occurred",
    };
  }
}
