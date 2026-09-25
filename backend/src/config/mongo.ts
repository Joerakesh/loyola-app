import { MongoClient, Db } from "mongodb";

let connectionPromise: Promise<MongoClient> | null = null;

const CONNECT_RETRIES = 3;
const RETRY_DELAY_MS = 750;

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function connectWithRetry(mongoUri: string): Promise<MongoClient> {
  let lastError: unknown;

  for (let attempt = 1; attempt <= CONNECT_RETRIES; attempt += 1) {
    const mongoClient = new MongoClient(mongoUri, {
      serverSelectionTimeoutMS: 10_000,
    });

    mongoClient.on("error", (error) => {
      console.error("MongoDB error:", error);
    });

    try {
      await mongoClient.connect();

      return mongoClient;
    } catch (error) {
      lastError = error;

      if (attempt < CONNECT_RETRIES) {
        await delay(RETRY_DELAY_MS * attempt);
      }
    }
  }

  throw lastError;
}

/**
 * Lazily connects to MongoDB and caches the *resolved* connection.
 *
 * A failed connect is never kept cached: the moment the promise rejects it is
 * discarded so the next call retries with a fresh client. This matters because
 * the Atlas `mongodb+srv` SRV resolution can transiently fail with
 * `ESERVFAIL`; caching the rejection would brick every Mongo call for the
 * lifetime of the process.
 */
export async function connectMongo(): Promise<MongoClient> {
  const mongoUri = process.env.MONGODB_URI;

  if (!mongoUri) {
    throw new Error("MONGODB_URI environment variable is not configured");
  }

  if (!connectionPromise) {
    connectionPromise = connectWithRetry(mongoUri).catch((error) => {
      connectionPromise = null;
      throw error;
    });
  }

  return connectionPromise;
}

export async function getDb(): Promise<Db> {
  const client = await connectMongo();

  return client.db(process.env.MONGODB_DB_NAME ?? "loyola_app");
}