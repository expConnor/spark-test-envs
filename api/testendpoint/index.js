export function checkBearerToken(request) {
  try {
    const authHeader = request.headers?.authorization;
    if (!authHeader) return false;
    const token = authHeader.replace("Bearer ", "").trim();
    return token === process.env.UNLEASH_SECRET;
  } catch (error) {
    console.error("Error checking token:", error.message);
    return false;
  }
}

export function validateRequest(req, res) {
  // Check Bearer token
  if (!checkBearerToken(req)) {
    res
      .status(401)
      .json({ error: "Unauthorized: Invalid or missing Bearer token" });
    return false;
  }
  // Check HTTP method
  if (req.method !== "POST") {
    res.status(405).json({ error: "Method not allowed" });
    return false;
  }
  // Check request body
  const { schema, tables } = req.body;
  if (!schema || !tables || !Array.isArray(tables)) {
    res
      .status(400)
      .json({ error: "Invalid request body. Need schema and tables array." });
    return false;
  }
  return { schema, tables };
}

export default async function handler(req, res) {
  // Validate the request
  const validationResult = validateRequest(req, res);
  if (!validationResult) return;

  // If validation passes, return hello world
  res.status(200).json({
    message: "Hello World!",
    timestamp: new Date().toISOString(),
  });
}
