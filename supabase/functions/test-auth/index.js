import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { supabaseClient } from "../_shared/supabaseClient.js";
import { supabaseAdmin } from "../_shared/supabaseAdmin.js";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  try {
    // Extract JWT from Authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("Missing Authorization header");
    }

    // Get the authenticated user
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser();
    if (userError || !user) {
      throw new Error("User not authenticated");
    }

    // Check if user has admin role
    const role = user.app_metadata?.role;
    if (role !== "admin") {
      return new Response(
        JSON.stringify({ error: "Unauthorized: Admin role required" }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse request body
    const { email } = await req.json();
    if (!email) {
      throw new Error("Email is required");
    }

    // Send invitation email
    const { data, error: inviteError } =
      await supabaseAdmin.auth.admin.inviteUserByEmail(email);

    if (inviteError) {
      throw inviteError;
    }

    // Update the invited user's app_metadata to set role to 'user'
    const invitedUserId = data.user.id;
    const { error: updateError } =
      await supabaseAdmin.auth.admin.updateUserById(invitedUserId, {
        app_metadata: { role: "user" },
      });

    if (updateError) {
      throw updateError;
    }

    return new Response(
      JSON.stringify({
        message: "Invitation sent successfully and user role set to user",
        user: data.user,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
