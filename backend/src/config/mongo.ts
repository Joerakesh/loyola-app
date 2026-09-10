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
      serverSelectionTimeoutMS: 5000,
    });

    mongoClient.on("error", (error) => {
      console.error("MongoDB error:", error);
    });

    connectionPromise = mongoClient.connect();
  }

  return connectionPromise;
}

export async function getDb(): Promise<Db> {
  const client = await connectMongo();

  return client.db(process.env.MONGODB_DB_NAME ?? "loyola_app");
}