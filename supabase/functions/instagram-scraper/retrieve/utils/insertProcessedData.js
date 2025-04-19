import { supabaseAdmin } from "../../../_shared/supabaseAdmin.js";

export const insertProcessedData = async (data) => {
  try {
    // Format timestamps and ensure string IDs
    const formatData = (items = [], idFields = [], dateFields = []) =>
      items?.map((item) => ({
        ...item,
        ...Object.fromEntries(
          idFields.map((field) => [field, String(item[field])])
        ),
        ...Object.fromEntries(
          dateFields.map((field) => [
            field,
            new Date(item[field]).toISOString(),
          ])
        ),
      })) || []; // Handle undefined input

    // Validate required data
    if (!data.accountImages || data.accountImages.length === 0) {
      throw new Error("No account images provided");
    }

    // Prepare the data payload
    const payload = {
      account_images: formatData(data.accountImages, ["account_id"]),
      account_stats: formatData(
        data.accountStats,
        ["account_id"],
        ["timestamp"]
      ),
      post_details: formatData(
        data.postDetails,
        ["post_id", "account_id"],
        ["created_at"]
      ),
      post_stats: formatData(data.postStats, ["post_id"], ["timestamp"]),
    };

    console.log("Data payload:", payload);

    const { data: result, error } = await supabaseAdmin.rpc(
      "insert_instagram_data",
      payload
    );

    if (error) throw error;

    return {
      success: true,
      result: result,
    };
  } catch (error) {
    console.error("Insert error:", error);
    return {
      success: false,
      error: {
        message: error.message,
        details: error.stack,
      },
    };
  }
};
