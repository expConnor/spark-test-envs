import { supabaseClient } from "../../../_shared/supabaseClient.js";

export const insertDatasetIds = async (
  functionName,
  target,
  profileScraperResponse,
  postScraperResponse
) => {
  try {
    const datasetData = [
      {
        function_name: functionName,
        target,
        dataset_ids: {
          profile_scraper:
            profileScraperResponse?.data?.defaultDatasetId || null,
          post_scraper: postScraperResponse?.data?.defaultDatasetId || null,
        },
        created_at: new Date().toISOString(),
      },
    ];

    const { error } = await supabaseClient

      .from("apify_datasets")
      .insert(datasetData)
      .select();

    if (error) throw error;

    // Return only essential information
    return {
      datasetIds: {
        profileScraper: profileScraperResponse?.data?.defaultDatasetId || null,
        postScraper: postScraperResponse?.data?.defaultDatasetId || null,
      },
    };
  } catch (error) {
    console.error("Error in insertDatasetIds:", error);
    throw error;
  }
};
