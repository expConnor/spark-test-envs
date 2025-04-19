export const getApifyToken = () => {
  const token = Deno.env.get("APIFY_API_TOKEN");

  if (!token) {
    console.error("APIFY_API_TOKEN is not set");
    throw new Error("Missing Apify API token");
  }

  return token;
};

export const apifyApiRequest = async ({
  baseUrl,
  memory,
  method = "GET",
  body = null,
  retryLimit = 3,
}) => {
  const token = getApifyToken();
  const apiUrl = `${baseUrl}?token=${token}${
    memory ? `&memory=${memory}` : ""
  }`;

  let response;
  let retryCount = 0;

  while (retryCount < retryLimit) {
    try {
      response = await fetch(apiUrl, {
        method,
        headers: { "Content-Type": "application/json" },
        body: body ? JSON.stringify(body) : null,
      });

      if (!response.ok) {
        const errorText = await response.text();

        if (response.status === 429 && retryCount < retryLimit - 1) {
          // Handle rate limits (429 Too Many Requests) with exponential backoff
          retryCount++;
          const delay = 1000 * Math.pow(2, retryCount); // Exponential backoff
          console.warn(
            `Apify API rate limited. Retrying in ${delay}ms (attempt ${retryCount})`
          );
          await new Promise((resolve) => setTimeout(resolve, delay));
          continue;
        }

        throw new Error(`Apify API error (${response.status}): ${errorText}`);
      }

      return await response.json();
    } catch (error) {
      if (retryCount >= retryLimit - 1 || response?.status !== 429) {
        console.error(
          `Failed Apify request: ${
            error instanceof Error ? error.message : "Unknown error"
          }`
        );
        throw error;
      }
      retryCount++;
    }
  }

  throw new Error("Exceeded maximum retry attempts for Apify API");
};
