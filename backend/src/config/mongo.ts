import { MongoClient, Db } from "mongodb";

const mongoUri = process.env.MONGODB_URI;

if (!mongoUri) {
  throw new Error("MONGODB_URI environment variable is not configured");
}

const mongoClient = new MongoClient(mongoUri, {
  serverSelectionTimeoutMS: 5000,
});

mongoClient.on("error", (error) => {
  console.error("MongoDB error:", error);
});

let connectionPromise: Promise<MongoClient> | null = null;

export function connectMongo(): Promise<MongoClient> {
  if (!connectionPromise) {
    connectionPromise = mongoClient.connect();
  }

  return connectionPromise;
}

export async function getDb(): Promise<Db> {
  const client = await connectMongo();

  return client.db(process.env.MONGODB_DB_NAME ?? "loyola_app");
}