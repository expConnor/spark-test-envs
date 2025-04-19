import { apifyApiRequest } from "../../../_shared/apify.js";

const APIFY_CONFIG = {
  dojo_profile_scraper: {
    baseUrl:
      "https://api.apify.com/v2/actor-tasks/unleash~dojo-instagram-profile-scraper/runs",
    memory: 512,
    method: "POST",
  },
  apify_post_scraper: {
    baseUrl:
      "https://api.apify.com/v2/actor-tasks/unleash~apify-instagram-post-scraper/runs",
    memory: 2048,
    method: "POST",
  },
};

export const callScrapers = async (accountUrls = [], postUrls = []) => {
  try {
    let profileScraperResponse = null;
    let postScraperResponse = null;

    // Call dojo scraper for accounts
    if (accountUrls && accountUrls.length > 0) {
      // Calculate the date 31 days ago
      const dateFrom31DaysAgo = new Date();
      dateFrom31DaysAgo.setDate(dateFrom31DaysAgo.getDate() - 31);
      const formattedDate = dateFrom31DaysAgo.toISOString().split("T")[0];

      profileScraperResponse = await apifyApiRequest({
        baseUrl: APIFY_CONFIG.dojo_profile_scraper.baseUrl,
        memory: APIFY_CONFIG.dojo_profile_scraper.memory,
        method: APIFY_CONFIG.dojo_profile_scraper.method,
        body: { startUrls: accountUrls, until: formattedDate },
      });
    }

    // Call post scraper for posts
    if (postUrls && postUrls.length > 0) {
      postScraperResponse = await apifyApiRequest({
        baseUrl: APIFY_CONFIG.apify_post_scraper.baseUrl,
        memory: APIFY_CONFIG.apify_post_scraper.memory,
        method: APIFY_CONFIG.apify_post_scraper.method,
        body: { username: postUrls },
      });
    }

    return {
      success: true,
      data: {
        profileScraperResponse,
        postScraperResponse,
      },
      error: null,
    };
  } catch (error) {
    console.error("Error in callInstagramScrapers:", error);
    return {
      success: false,
      data: null,
      error: {
        message: error instanceof Error ? error.message : "Unknown error",
        stack: error instanceof Error ? error.stack : undefined,
      },
    };
  }
};
