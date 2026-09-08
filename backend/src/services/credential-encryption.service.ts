import {
  createCipheriv,
  createDecipheriv,
  createHash,
  randomBytes,
} from "node:crypto";

const ALGORITHM = "aes-256-gcm";
const VERSION = "v1";
const IV_LENGTH = 12;

function getKey(): Buffer {
  const secret = process.env.ERP_CREDENTIALS_ENCRYPTION_KEY;

  if (!secret) {
    throw new Error(
      "ERP_CREDENTIALS_ENCRYPTION_KEY environment variable is not configured",
    );
  }

  return createHash("sha256").update(secret).digest();
}

export class CredentialEncryptionService {
  encrypt(secret: string): string {
    const iv = randomBytes(IV_LENGTH);

    const cipher = createCipheriv(ALGORITHM, getKey(), iv);

    const ciphertext = Buffer.concat([
      cipher.update(secret, "utf8"),
      cipher.final(),
    ]);

    const authTag = cipher.getAuthTag();

    const payload = Buffer.concat([iv, authTag, ciphertext]).toString("base64");

    return `${VERSION}:${payload}`;
  }

  decrypt(payload: string): string {
    const [version, encoded] = payload.split(":");

    if (version !== VERSION) {
      throw new Error(`Unsupported credential version: ${version}`);
    }

    const buffer = Buffer.from(encoded, "base64");

    const iv = buffer.subarray(0, IV_LENGTH);
    const authTag = buffer.subarray(IV_LENGTH, IV_LENGTH + 16);
    const ciphertext = buffer.subarray(IV_LENGTH + 16);

    const decipher = createDecipheriv(ALGORITHM, getKey(), iv);

    decipher.setAuthTag(authTag);

    return Buffer.concat([
      decipher.update(ciphertext),
      decipher.final(),
    ]).toString("utf8");
  }
}

export const credentialEncryptionService = new CredentialEncryptionService();