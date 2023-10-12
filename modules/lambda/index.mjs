import crypto from "crypto";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";

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

async function saveToS3(s3client, webhookBody, key) {
  const input = {
    Body: webhookBody,
    Bucket: process.env.BUCKET,
    Key: key,
  };
  const command = new PutObjectCommand(input);
  await s3client.send(command);
}

export const handler = async (event) => {
  console.log("Event: ", event);
  const response = {
    batchItemFailures: [],
  };

  for (const record of event.Records) {
    console.log("message attributes ", record.messageAttributes);
    const payload = JSON.parse(record.body);

    const bodyString = record.body;
    const hmacSignature = record.messageAttributes.hmac.stringValue;

    try {
      if (!verifyHmac(bodyString, hmacSignature)) {
        console.log("Invalid HMAC. Dropping webhook");
        continue;
      }
    } catch (error) {
      console.log("Error verifying HMAC. Dropping webhook", error);
      continue;
    }

    const client = new S3Client({
      region: process.env.REGION,
    });

    try {
      await saveToS3(
        client,
        bodyString,
        record.messageAttributes["webook-id"].stringValue
      );
      console.log("Processing payload webhook", payload);
    } catch (error) {
      console.log("Error processing webhook", error);
      // failed record will go back to queue
      response.batchItemFailures.push({ itemIdentifier: record.messageId });
    }
  }

  return response;
};
