import { apifyApiRequest } from "../../../_shared/apify.js";

const APIFY_CONFIG = {
  dojo_profile_scraper: {
    baseUrl:
      "https://api.apify.com/v2/actor-tasks/unleash~dojo-tiktok-profile-scraper/runs",
    memory: 512,
    method: "POST",
  },
  dojo_post_scraper: {
    baseUrl:
      "https://api.apify.com/v2/actor-tasks/unleash~dojo-tiktok-post-scraper/runs",
    memory: 512,
    method: "POST",
  },
};

export const callScrapers = async ({ accountUrls = [], postUrls = [] }) => {
  try {
    let profileScraperResponse = null;
    let postScraperResponse = null;
    // Call Profile scraper for accounts
    if (accountUrls && accountUrls.length > 0) {
      // Calculate the date 31 days ago
      const dateFrom31DaysAgo = new Date();
      dateFrom31DaysAgo.setDate(dateFrom31DaysAgo.getDate() - 31);
      const formattedDate = dateFrom31DaysAgo.toISOString().split("T")[0];

      const profileConfig = {
        baseUrl: APIFY_CONFIG.dojo_profile_scraper.baseUrl,
        memory: APIFY_CONFIG.dojo_profile_scraper.memory,
        method: APIFY_CONFIG.dojo_profile_scraper.method,
        body: {
          startUrls: accountUrls,
          until: formattedDate,
        },
      };

      profileScraperResponse = await apifyApiRequest(profileConfig);
    }
    // Call Post scraper for posts
    if (postUrls && postUrls.length > 0) {
      const postConfig = {
        baseUrl: APIFY_CONFIG.dojo_post_scraper.baseUrl,
        memory: APIFY_CONFIG.dojo_post_scraper.memory,
        method: APIFY_CONFIG.dojo_post_scraper.method,
        body: {
          startUrls: postUrls,
        },
      };

      postScraperResponse = await apifyApiRequest(postConfig);
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
    console.error("Error in callTiktokScrapers:", error);
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
