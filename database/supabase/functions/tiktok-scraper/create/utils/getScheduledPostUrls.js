import { supabaseClient } from "../../../_shared/supabaseClient.js";
import {
  FunctionsHttpError,
  FunctionsRelayError,
  FunctionsFetchError,
} from "https://esm.sh/@supabase/supabase-js@2.39.0";

export async function getScheduledPostUrls() {
  try {
    const today = new Date();
    const targetDates = [];
    // Target dates based on rules
    const rules = [
      { start: 30, end: 60, step: 3 },
      { start: 60, end: 90, step: 7 },
      { start: 90, end: 180, step: 30 },
      { start: 180, end: 730, step: 60 },
    ];
    rules.forEach(({ start, end, step }) => {
      for (let daysAgo = start; daysAgo < end; daysAgo += step) {
        const date = new Date(today);
        date.setDate(today.getDate() - daysAgo);
        targetDates.push(date.toISOString().split("T")[0]);
      }
    });

    const { data: postUrlObjects, error } = await supabaseClient
      .from("tiktok_post_db")
      .select("post_url")
      .eq("active", true)
      .not("post_url", "is", null)
      .in("created_at", targetDates);

    if (error) throw error;
    if (!postUrlObjects || !Array.isArray(postUrlObjects)) {
      throw new Error("Invalid response from database");
    }
    return postUrlObjects.map((obj) => obj.post_url);
  } catch (error) {
    console.error("Error in getScheduledPostUrls:", error);

    if (error instanceof FunctionsHttpError) {
      const errorMessage = await error.context.json();
      console.error("Function returned an error:", errorMessage);
    } else if (error instanceof FunctionsRelayError) {
      console.error("Relay error:", error.message);
    } else if (error instanceof FunctionsFetchError) {
      console.error("Fetch error:", error.message);
    }

    return [];
  }
}
