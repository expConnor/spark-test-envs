import fetch from "node-fetch";

async function testImageHandler() {
  try {
    const response = await fetch("http://localhost:3000/api/image-handler", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        schema: "public",
        tables: ["creator_db"], // You can adjust these tables based on your needs
      }),
    });

    // Get the raw text first to see what we're getting
    const text = await response.text();
    console.log("Raw response:", text);

    // Try to parse as JSON if it looks like JSON
    if (text.trim().startsWith("{")) {
      const result = JSON.parse(text);
      console.log("Parsed JSON:", JSON.stringify(result, null, 2));
    }

    // Log the status and headers
    console.log("Status:", response.status);
    console.log("Headers:", Object.fromEntries(response.headers.entries()));
  } catch (error) {
    console.error("Error:", error);
  }
}

testImageHandler().catch(console.error);
