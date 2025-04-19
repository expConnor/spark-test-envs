import { getDatasetIds } from "./utils/getDatasetIds.js";
import { supabaseClient } from "../../_shared/supabaseClient.js";
import { retrieveDatasetResults } from "./utils/callScraperApis.js";
import { processProfileData } from "./utils/processProfileData.js";
import { processPostData } from "./utils/processPostData.js";
import { insertProcessedData } from "./utils/insertProcessedData.js";

export async function retrieveStandardScrape() {
  // #1: Get Apify Dataset IDs and timestamp from apify_datasets table
  const datasetIds = await getDatasetIds("instagram-scraper", "standard");

  // **EARLY EXIT: If no dataset IDs exist, stop execution**
  if (!datasetIds.profileScraper && !datasetIds.postScraper) {
    return {
      success: false,
      data: { message: "No dataset IDs found" },
      error: null,
    };
  }

  // #2: Call APIs to retrieve dataItems from Datasets
  const results = await retrieveDatasetResults(
    datasetIds.profileScraper,
    datasetIds.postScraper
  );

  // #3: Process the scraper data
  let processedProfileData;
  let processedPostData;

  if (results.data?.profileScraperData) {
    processedProfileData = await processProfileData(
      results.data.profileScraperData,
      datasetIds.createdAt
    );
  }

  if (results.data?.postScraperData) {
    processedPostData = processPostData(
      results.data.postScraperData,
      datasetIds.createdAt
    );
  }

  // #4: Combine and insert the processed data
  if (processedProfileData?.success && processedProfileData?.data) {
    // Combine post stats from both sources
    const combinedData = {
      ...processedProfileData.data,
      postStats: [
        ...(processedProfileData.data.postStats || []),
        ...(processedPostData || []),
      ],
    };

    // Insert all data
    const insertResult = await insertProcessedData(combinedData);
    if (!insertResult.success) {
      throw new Error(`Failed to insert data: ${insertResult.error}`);
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
      profileStats: processedProfileData?.data?.postStats?.length || 0,
      postStats: processedPostData?.length || 0,
    },
  };
}
