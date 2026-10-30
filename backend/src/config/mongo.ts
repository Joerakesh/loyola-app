import { MongoClient, Db } from "mongodb";

let connectionPromise: Promise<MongoClient> | null = null;

export function connectMongo(): Promise<MongoClient> {
  const mongoUri = process.env.MONGODB_URI;

  if (!mongoUri) {
    return Promise.reject(
      new Error("MONGODB_URI environment variable is not configured"),
    );
  }

  if (!connectionPromise) {
    const mongoClient = new MongoClient(mongoUri, {
      serverSelectionTimeoutMS: 10000,
    });

    mongoClient.on("error", (error) => {
      console.error("MongoDB error:", error);
    });

    // Cache a successful connection for warm serverless invocations, but do
    // not leave a rejected promise cached forever after a transient failure.
    connectionPromise = mongoClient.connect().catch((error: unknown) => {
      connectionPromise = null;
      void mongoClient.close().catch(() => undefined);
      throw error;
    });
  }

  return connectionPromise;
}

export async function getDb(): Promise<Db> {
  const client = await connectMongo();

  return client.db(process.env.MONGODB_DB_NAME ?? "loyola_app");
}
