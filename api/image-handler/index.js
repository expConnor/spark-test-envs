import fetch from "node-fetch";
import convert from "heic-convert";
import supabase from "../../lib/supabase";

const BATCH_SIZE = 3;
const LOCK_TIMEOUT_MS = 60 * 60 * 1000; // 1 hour

export default async function imageHandler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  try {
    console.log("Request body:", JSON.stringify(req.body, null, 2));

    const { schema, tables } = req.body;

    if (!schema || !tables || !Array.isArray(tables)) {
      console.log("Invalid request body:", { schema, tables });
      return res
        .status(400)
        .json({ error: "Invalid request body. Need schema and tables array." });
    }

    // Test Supabase connection
    try {
      const { data, error } = await supabase
        .from("creator_db")
        .select("*")
        .limit(1);
      if (error) {
        console.error("Supabase connection test failed:", error);
        throw error;
      }
      console.log("Supabase connection successful");
    } catch (error) {
      console.error("Supabase connection error:", error);
      throw error;
    }

    const results = [];
    let totalProcessed = 0;

    // Process each table until we reach the total batch size
    for (const target of tables) {
      if (totalProcessed >= BATCH_SIZE) break;

      const idField = target === "creator_db" ? "creator_id" : "post_id";
      console.log(`Processing table: ${target} with idField: ${idField}`);

      // Reset stale locks
      try {
        const { error: resetError } = await supabase
          .from(target)
          .update({ image_url: null })
          .like("image_url", "processing_%")
          .lt(
            "image_url",
            `processing_${new Date(Date.now() - LOCK_TIMEOUT_MS).toISOString()}`
          );

        if (resetError) {
          console.error(
            `Error resetting stale locks for ${target}:`,
            resetError
          );
          throw resetError;
        }
      } catch (error) {
        console.error(`Error in reset stale locks for ${target}:`, error);
        results.push({ table: target, error: error.message });
        continue;
      }

      // Calculate how many more images we can process
      const remainingBatchSize = BATCH_SIZE - totalProcessed;

      // Fetch and lock new rows
      try {
        const { data: pendingImages, error: fetchError } = await supabase
          .from(target)
          .select(`image_url_cdn, ${idField}::text`)
          .is("image_url", null)
          .not("image_url_cdn", "is", null)
          .limit(remainingBatchSize);

        if (fetchError) {
          console.error(
            `Error fetching pending images for ${target}:`,
            fetchError
          );
          results.push({ table: target, error: fetchError.message });
          continue;
        }

        console.log(
          `Found ${pendingImages?.length || 0} pending images for ${target}`
        );

        if (!pendingImages?.length) {
          results.push({ table: target, status: "No images to process" });
          continue;
        }

        // Lock rows
        const lockTimestamp = new Date().toISOString();
        const processingValue = `processing_${lockTimestamp}`;

        const { error: lockError } = await supabase
          .from(target)
          .update({ image_url: processingValue })
          .in(
            idField,
            pendingImages.map((img) => img[idField])
          )
          .is("image_url", null);

        if (lockError) {
          results.push({ table: target, error: lockError.message });
          continue;
        }

        let processed = 0;
        let failed = 0;

        // Process each locked image
        for (const image of pendingImages) {
          try {
            if (!image.image_url_cdn) {
              throw new Error("URL missing");
            }

            const response = await fetch(image.image_url_cdn);
            if (!response.ok)
              throw new Error(`Failed to fetch image: ${response.status}`);

            const contentType = response.headers.get("content-type");
            let buffer = Buffer.from(await response.arrayBuffer());

            if (
              contentType?.includes("heic") ||
              image.image_url_cdn.toLowerCase().endsWith(".heic")
            ) {
              buffer = await convert({ buffer, format: "JPEG", quality: 1 });
            }

            // Store image in table-specific folder
            const filePath = `${target}/${target}_${image[idField]}.jpg`;

            const { error: uploadError } = await supabase.storage
              .from("images")
              .upload(filePath, buffer, {
                contentType: "image/jpeg",
                upsert: true,
              });

            if (uploadError) throw uploadError;

            const {
              data: { publicUrl },
            } = supabase.storage.from("images").getPublicUrl(filePath);

            await supabase
              .from(target)
              .update({ image_url: publicUrl })
              .eq(idField, image[idField]);

            processed++;
            totalProcessed++;
          } catch (error) {
            console.error(`Failed to process image: ${error.message}`);
            await supabase
              .from(target)
              .update({ image_url: null })
              .eq(idField, image[idField]);
            failed++;
          }
        }

        results.push({
          table: target,
          processed,
          failed,
          total: pendingImages.length,
        });
      } catch (error) {
        console.error(`Error processing table ${target}:`, error);
        results.push({ table: target, error: error.message });
      }
    }

    res.json({
      results,
      totalProcessed,
      totalFailed: results.reduce((sum, r) => sum + (r.failed || 0), 0),
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}
