import { getDatasetIds } from "./utils/getDatasetIds.js";
import { supabaseClient } from "../../_shared/supabaseClient.js";
import { retrieveDatasetResults } from "./utils/callScraperApis.js";
import { processPostData } from "./utils/processPostData.js";
import { insertProcessedData } from "./utils/insertProcessedData.js";

export async function retrieveCampaignScrape() {
  // #1: Get Apify Dataset IDs and timestamp from apify_datasets table
  const datasetIds = await getDatasetIds("instagram-scraper", "campaign");

  // **EARLY EXIT: If no dataset IDs exist, stop execution**
  if (!datasetIds.postScraper) {
    // Only check for postScraper
    return {
      success: false,
      data: { message: "No dataset IDs found" },
      error: null,
    };
  }

  // #2: Call APIs to retrieve dataItems from Datasets
  const results = await retrieveDatasetResults(
    null, // No profile scraper needed
    datasetIds.postScraper
  );

  // #3: Process the scraper data
  let apifyPostStats;

  if (results.data?.postScraperData) {
    apifyPostStats = processPostData(
      results.data.postScraperData,
      datasetIds.createdAt
    );
    console.log("Processed post stats:", apifyPostStats);
  }

  // #4: Insert the processed data
  if (apifyPostStats && apifyPostStats.length > 0) {
    const processedData = {
      accountImages: [], // Empty as we don't process account data
      accountStats: [], // Empty as we don't process account stats
      postDetails: [], // Empty as we don't process post details
      postStats: apifyPostStats,
    };

    // Insert data
    const insertResult = await insertProcessedData(
      processedData,
      datasetIds.createdAt
    );

    if (!insertResult.success) {
      throw new Error(
        `Failed to insert data: ${
          insertResult.error?.message || "Unknown error"
        }`
      );
    }
  }

  // #5: Update last_scrape_successful to true in apify_datasets table
  const { error } = await supabaseClient
    .from("apify_datasets")
    .update({ successful_retrieval: true })
    .eq("id", datasetIds.id);

  if (error) throw error;

  return {
    success: true,
    data: {
      apifyStats: apifyPostStats?.length || 0,
    },
  };
}
