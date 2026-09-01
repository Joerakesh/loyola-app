import { createClient } from "redis";

const redisUrl = process.env.REDIS_URL;

if (!redisUrl) {
  throw new Error("REDIS_URL environment variable is not configured");
}

export const redis = createClient({
  url: redisUrl,
});

redis.on("error", (error) => {
  console.error("Redis error:", error);
});

let connectionPromise: Promise<void> | null = null;

export function connectRedis() {
  if (!connectionPromise) {
    connectionPromise = redis.connect();
  }

  return connectionPromise;
}
