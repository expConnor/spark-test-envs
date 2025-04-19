import { apifyApiRequest } from "../../../_shared/apify.js";

const APIFY_CONFIG = {
  profile_scraper_dataset: {
    baseUrl: "https://api.apify.com/v2/datasets/",
    method: "GET",
  },
  post_scraper_dataset: {
    baseUrl: "https://api.apify.com/v2/datasets/",
    method: "GET",
  },
};

export const retrieveDatasetResults = async (
  profileDatasetId,
  postDatasetId
) => {
  try {
    let profileScraperData = null;
    let postScraperData = null;
    // Retrieve profile scraper results if dataset ID exists
    if (profileDatasetId) {
      profileScraperData = await apifyApiRequest({
        baseUrl: `${APIFY_CONFIG.profile_scraper_dataset.baseUrl}${profileDatasetId}/items`,
        method: APIFY_CONFIG.profile_scraper_dataset.method,
      });
    }
    // Retrieve post scraper results if dataset ID exists
    if (postDatasetId) {
      postScraperData = await apifyApiRequest({
        baseUrl: `${APIFY_CONFIG.post_scraper_dataset.baseUrl}${postDatasetId}/items`,
        method: APIFY_CONFIG.post_scraper_dataset.method,
      });
    }
    return {
      success: true,
      data: {
        profileScraperData,
        postScraperData,
      },
      error: null,
    };
  } catch (error) {
    console.error("Error in retrieveDatasetResults:", error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : "Unknown error occurred",
    };
  }
};
