import { supabaseClient } from "../../../_shared/supabaseClient.js";

export async function getAccountUrls() {
  try {
    const { data: accounts, error } = await supabaseClient
      .from("tiktok_account_db")
      .select("account_url")
      .eq("active", true);

    if (error) {
      throw new Error(error.message);
    }

    if (!accounts || !Array.isArray(accounts)) {
      throw new Error("No accounts found or invalid response");
    }

    return accounts.map((account) => account.account_url);
  } catch (error) {
    throw new Error(error.message);
  }
}
