import crypto from "crypto";

function createHmac(message) {
  const hmac = crypto.createHmac("sha256", process.env.API_SECRET);
  hmac.update(message);
  return hmac.digest("hex");
}

function verifyHmac(message, receivedHmac) {
  const hmacFromMessage = createHmac(message);
  return crypto.timingSafeEqual(
    Buffer.from(hmacFromMessage, "utf8"),
    Buffer.from(receivedHmac, "utf8")
  );
}

export const handler = async (event) => {
  console.log("Event: ", event);
  const response = {
    statusCode: 200,
    body: JSON.stringify("Webhook processed"),
  };

  event.Records.forEach((record) => {
    console.log("message attributes ", record.messageAttributes);
    const payload = JSON.parse(record.body);

    const bodyString = payload.body;
    const hmacSignature = record.messageAttributes.hmac.stringValue;

    if (!verifyHmac(bodyString, hmacSignature)) {
      console.log("Invalid HMAC. Dropping webhook");
      return response;
    }

    console.log("Processing payload webhook", payload);
  });

  return response;
};
