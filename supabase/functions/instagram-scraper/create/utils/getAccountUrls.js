import { supabaseClient } from "../../../_shared/supabaseClient.js";

export async function getAccountUrls() {
  try {
    const { data: accounts, error } = await supabaseClient
      .from("instagram_account_db")
      .select("account_url")
      .eq("active", true);

    if (error) throw error;
    if (!accounts || !Array.isArray(accounts)) {
      throw new Error("Invalid response from database");
    }

    return accounts.map((account) => account.account_url);
  } catch (error) {
    throw new Error(
      `Failed to fetch account URLs: ${
        error instanceof Error ? error.message : "Unknown error"
      }`
    );
  }
}
