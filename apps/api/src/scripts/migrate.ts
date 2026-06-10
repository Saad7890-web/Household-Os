import { logger } from "../config/logger";
import { runMigrations } from "../database/migrate";

async function main() {
  try {
    await runMigrations();
    logger.info("Database migrations completed successfully");
    process.exit(0);
  } catch (error) {
    logger.error({ err: error }, "Database migrations failed");
    process.exit(1);
  }
}

void main();
