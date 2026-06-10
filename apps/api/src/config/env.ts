import dotenv from "dotenv";
import { existsSync } from "fs";
import { dirname, resolve } from "path";
import { z } from "zod";

function findEnvFile(startDir: string): string | undefined {
  let currentDir = startDir;

  while (true) {
    const candidate = resolve(currentDir, ".env");

    if (existsSync(candidate)) {
      return candidate;
    }

    const parentDir = dirname(currentDir);
    if (parentDir === currentDir) {
      return undefined;
    }

    currentDir = parentDir;
  }
}

const envPath = findEnvFile(process.cwd());

if (envPath) {
  dotenv.config({ path: envPath });
} else {
  dotenv.config();
}

const envSchema = z.object({
  NODE_ENV: z
    .enum(["development", "test", "production"])
    .default("development"),
  PORT: z.coerce.number().int().positive().default(3000),
  APP_NAME: z.string().default("household-os-api"),
  LOG_LEVEL: z
    .enum(["fatal", "error", "warn", "info", "debug", "trace", "silent"])
    .default("info"),
  CORS_ORIGIN: z.string().default("http://localhost:5173"),

  DATABASE_URL: z.string().min(1, "DATABASE_URL is required"),
  DB_MAX_POOL_SIZE: z.coerce.number().int().positive().default(20),
  DB_IDLE_TIMEOUT_MS: z.coerce.number().int().positive().default(10000),
  DB_CONNECTION_TIMEOUT_MS: z.coerce.number().int().positive().default(5000),
  DB_SSL: z
    .enum(["true", "false"])
    .default("false")
    .transform((value) => value === "true")
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error(
    "Invalid environment variables:",
    parsed.error.flatten().fieldErrors
  );
  process.exit(1);
}

export const env = parsed.data;
