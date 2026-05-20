const {onCall, onRequest, HttpsError} = require("firebase-functions/v2/https");
const axios = require("axios");
const { GoogleAuth } = require("google-auth-library");
const admin = require("firebase-admin");
const {getStorage, getDownloadURL} = require("firebase-admin/storage");
const crypto = require("crypto");

admin.initializeApp();

/**
 * Converts a public Firebase Storage URL to a GCS URI.
 * @param {string} publicUrl The public URL of the file in Firebase Storage.
 * @return {string} The GCS URI (e.g., "gs://bucket/object").
 */
function getGcsUri(publicUrl) {
  try {
    const url = new URL(publicUrl);
    const path = url.pathname;
    const parts = path.split('/o/');
    const bucketAndPrefix = parts[0];
    const objectPath = parts[1];

    if (!bucketAndPrefix || !objectPath) {
      throw new Error("Invalid Firebase Storage URL format.");
    }
    const bucket = bucketAndPrefix.substring(bucketAndPrefix.lastIndexOf('/') + 1);
    return `gs://${bucket}/${decodeURIComponent(objectPath)}`;
  } catch(e) {
      console.error("Could not parse public URL:", publicUrl, e);
      // Re-throw with a clear message for the client
      throw new HttpsError('invalid-argument', `The provided image URL is not a valid Firebase Storage URL: ${publicUrl}`);
  }
}

/**
 * Creates the correct image object for the Vertex AI API. Virtual Try-On accepts
 * only gcsUri or bytesBase64Encoded—not arbitrary uri. For Firebase Storage we
 * use gcsUri; for other URLs we fetch and send base64.
 * @param {string} imageUrl The URL of the image.
 * @return {Promise<object>} An object for the Vertex AI payload.
 */
async function createImageObject(imageUrl) {
    if (imageUrl.includes("firebasestorage.googleapis.com")) {
        return { gcsUri: getGcsUri(imageUrl) };
    }
    if (imageUrl.startsWith("http://") || imageUrl.startsWith("https://")) {
        const resp = await axios.get(imageUrl, { responseType: "arraybuffer" });
        const base64 = Buffer.from(resp.data).toString("base64");
        return { bytesBase64Encoded: base64 };
    }
    throw new HttpsError("invalid-argument", `Invalid image URL format: ${imageUrl}`);
}

const auth = new GoogleAuth({
  scopes: "https://www.googleapis.com/auth/cloud-platform",
});

exports.startVertexTryOn = onCall({ region: "us-central1", cors: true }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  const project = "kenz-fashion-d060d";
  // Virtual Try-On is not available in europe-west3; use us-central1 (Iowa).
  const location = "us-central1";
  const { personImageUrl, productImageUrl } = request.data;

  if (!personImageUrl || !productImageUrl) {
    console.error("Request is missing personImageUrl or productImageUrl", request.data);
    throw new HttpsError('invalid-argument', 'You must provide both a personImageUrl and a productImageUrl.');
  }

  console.log("Function triggered with personImageUrl:", personImageUrl, "and productImageUrl:", productImageUrl);

  try {
    const personImageObject = await createImageObject(personImageUrl);
    const productImageObject = await createImageObject(productImageUrl);

    console.log("Created Vertex AI image objects.");

    const client = await auth.getClient();
    const token = await client.getAccessToken();

    const url = `https://${location}-aiplatform.googleapis.com/v1/projects/${project}/locations/${location}/publishers/google/models/virtual-try-on-001:predict`;

    const payload = {
      instances: [{
        personImage: { image: personImageObject },
        productImages: [{ image: productImageObject }]
      }],
      parameters: { sampleCount: 1 }
    };
    
    console.log("Sending payload to Vertex AI:", JSON.stringify(payload, null, 2));

    const response = await axios.post(url, payload, {
      headers: {
        Authorization: `Bearer ${token.token}`,
        "Content-Type": "application/json",
      }
    });

    console.log("Received response from Vertex AI.");

    if (!response.data || !response.data.predictions || response.data.predictions.length === 0 || !response.data.predictions[0].bytesBase64Encoded) {
        console.error("Unexpected Vertex AI response structure:", JSON.stringify(response.data));
        throw new HttpsError('internal', 'AI service returned an unexpected response.');
    }

    return {
      tryOnImageBase64: response.data.predictions[0].bytesBase64Encoded
    };

  } catch (error) {
    // If it's already an HttpsError, just rethrow it
    if (error instanceof HttpsError) {
        throw error;
    }
    // Structured log so it appears in Cloud Logging with full payload
    const errPayload = {
      message: "startVertexTryOn failed",
      errorMessage: error.message,
      errorName: error.name,
      ...(error.response && {
        vertexStatus: error.response.status,
        vertexData: error.response.data,
      }),
      ...(error.stack && { stack: error.stack }),
    };
    console.error(JSON.stringify(errPayload));
    if (error.response) {
      console.error("Vertex AI Error Data:", JSON.stringify(error.response.data));
      console.error("Vertex AI Error Status:", error.response.status);
    } else if (error.request) {
      console.error("Vertex AI No Response:", error.request);
    } else {
      console.error("Error", error.message);
    }
    throw new HttpsError('internal', 'AI processing failed. See function logs for details.');
  }
});

exports.uploadTryOnImageHttp = onRequest(
  {cors: true, timeoutSeconds: 60, region: "us-central1"},
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({error: {message: "Method not allowed"}});
      return;
    }
    try {
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({error: {message: "Missing or invalid Authorization header"}});
        return;
      }
      const token = authHeader.slice(7);
      await admin.auth().verifyIdToken(token);
      
      const {base64Image, productId, fileName} = req.body;
      if (!base64Image || !productId || !fileName) {
        res.status(400).json({error: {message: "Missing base64Image, productId, or fileName"}});
        return;
      }

      const buffer = Buffer.from(base64Image, "base64");
      const timestamp = Date.now();
      const storagePath = `products/${productId}/_${timestamp}_${fileName}`;
      const bucket = getStorage().bucket();
      const file = bucket.file(storagePath);
      
      await file.save(buffer, {
        metadata: {
          contentType: "image/jpeg",
          firebaseStorageDownloadTokens: crypto.randomUUID(),
        },
      });

      const url = await getDownloadURL(file);

      res.status(200).json({url});
    } catch (err) {
      const errPayload = {
        message: "uploadTryOnImageHttp failed",
        errorMessage: err.message,
        errorCode: err.code,
        errorName: err.name,
        ...(err.stack && { stack: err.stack }),
      };
      console.error(JSON.stringify(errPayload));
      if (err.code === "auth/id-token-expired" || err.code === "auth/argument-error") {
        res.status(401).json({error: {message: err.message || "Invalid token"}});
      } else {
        res.status(500).json({error: {message: err.message || "Upload failed"}});
      }
    }
  }
);
