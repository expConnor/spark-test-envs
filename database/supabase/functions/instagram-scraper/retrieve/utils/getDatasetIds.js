import { supabaseClient } from "../../../_shared/supabaseClient.js";

export const getDatasetIds = async (functionName, target) => {
  try {
    const { data: datasets, error } = await supabaseClient

      .from("apify_datasets")
      .select("dataset_ids, created_at, id")
      .eq("function_name", functionName)
      .eq("target", target)
      .is("successful_retrieval", null)
      .order("created_at", { ascending: false })
      .limit(1);

    if (error) throw error;

    // Return null values if no datasets found
    if (!datasets || datasets.length === 0) {
      return {
        profileScraper: null,
        postScraper: null,
        createdAt: null,
        id: null,
      };
    }

    // Extract dataset IDs from the most recent record
    const latestDataset = datasets[0];
    return {
      profileScraper: latestDataset.dataset_ids?.profile_scraper || null,
      postScraper: latestDataset.dataset_ids?.post_scraper || null,
      createdAt: latestDataset.created_at || null,
      id: latestDataset.id || null,
    };
  } catch (error) {
    console.error("Error in getDatasetIds:", error);
    throw error;
  }
};
