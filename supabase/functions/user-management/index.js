import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { supabaseClient } from "../_shared/supabaseClient.js";
import { supabaseAdmin } from "../_shared/supabaseAdmin.js";
import { actions } from "./actions.js";
import {
  sendResponse,
  sendError,
  ALLOWED_ACTIONS,
  corsHeaders,
} from "./utils.js";

serve(async (req) => {
  //1. Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  //2. Only handle POST requests
  if (req.method !== "POST") {
    return sendError("Method not allowed", 405);
  }

  try {
    //3. Extract JWT from Authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("Missing Authorization header");
    }
    const token = authHeader.replace("Bearer ", "");

    //4. Get the authenticated user
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser(token);
    if (userError || !user) {
      throw new Error("User not authenticated");
    }

    //5. Check if user has admin role
    if (user.app_metadata?.role !== "admin") {
      throw new Error("Unauthorized: Admin role required");
    }

    //6. Parse request body
    const body = await req.json();
    const { action, ...data } = body;

    //7. Validate action
    if (!action || !ALLOWED_ACTIONS.includes(action)) {
      throw new Error("Invalid or missing action");
    }

    //8. Execute the action
    const actionFunction = actions[action];
    const result = await actionFunction(supabaseAdmin, data);

    return sendResponse(result);
  } catch (error) {
    console.error("Error:", error);
    return sendError(
      error.message,
      error.message.includes("Unauthorized") ? 403 : 400
    );
  }
});
