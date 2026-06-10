import crypto from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import { Client } from "pg";
import { env } from "../config/env";
import { logger } from "../config/logger";

type MigrationFile = {
  version: string;
  filename: string;
  sql: string;
  checksum: string;
};

const migrationsDir = path.join(process.cwd(), "src", "database", "migrations");

function checksum(content: string): string {
  return crypto.createHash("sha256").update(content).digest("hex");
}

async function readMigrations(): Promise<MigrationFile[]> {
  const entries = await fs.readdir(migrationsDir, { withFileTypes: true });

  const sqlFiles = entries
    .filter((entry) => entry.isFile() && entry.name.endsWith(".sql"))
    .map((entry) => entry.name)
    .sort((a, b) => a.localeCompare(b));

  const migrations: MigrationFile[] = [];

  for (const filename of sqlFiles) {
    const version = filename;
    const filePath = path.join(migrationsDir, filename);
    const sql = await fs.readFile(filePath, "utf8");

    migrations.push({
      version,
      filename,
      sql,
      checksum: checksum(sql)
    });
  }

  return migrations;
}

async function ensureMigrationsTable(client: Client): Promise<void> {
  await client.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version TEXT PRIMARY KEY,
      checksum TEXT NOT NULL,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
  `);
}

async function loadAppliedMigrations(
  client: Client
): Promise<Map<string, string>> {
  const result = await client.query<{ version: string; checksum: string }>(`
    SELECT version, checksum
    FROM schema_migrations
    ORDER BY version ASC
  `);

  return new Map(result.rows.map((row) => [row.version, row.checksum]));
}

async function applyMigration(
  client: Client,
  migration: MigrationFile
): Promise<void> {
  await client.query("BEGIN");

  try {
    await client.query(migration.sql);
    await client.query(
      `
      INSERT INTO schema_migrations (version, checksum)
      VALUES ($1, $2)
      `,
      [migration.version, migration.checksum]
    );
    await client.query("COMMIT");

    logger.info({ version: migration.version }, "Migration applied");
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  }
}

export async function runMigrations(): Promise<void> {
  const client = new Client({
    connectionString: env.DATABASE_URL,
    ssl: env.DB_SSL ? { rejectUnauthorized: false } : undefined,
    application_name: `${env.APP_NAME}-migrator`
  });

  await client.connect();

  try {
    await ensureMigrationsTable(client);

    const applied = await loadAppliedMigrations(client);
    const migrations = await readMigrations();

    for (const migration of migrations) {
      const appliedChecksum = applied.get(migration.version);

      if (appliedChecksum && appliedChecksum !== migration.checksum) {
        throw new Error(
          `Migration checksum mismatch for ${migration.version}. The file was changed after it was applied.`
        );
      }

      if (!appliedChecksum) {
        await applyMigration(client, migration);
      }
    }
  } finally {
    await client.end();
  }
}
