import { supabaseClient } from "../../../_shared/supabaseClient.js";

export const getCampaignedPostUrls = async () => {
  try {
    const { data: postUrls, error } = await supabaseClient
      .from("instagram_post_db")
      .select("post_url")
      .eq("active", true)
      .not("campaign_id", "is", null)
      .not("post_url", "is", null);

    if (error) throw error;
    if (!postUrls || !Array.isArray(postUrls)) {
      throw new Error("Invalid response from database");
    }

    return postUrls.map((post) => post.post_url);
  } catch (error) {
    console.error("Error in getCampaignedPostUrls:", error);
    throw error;
  }
};
