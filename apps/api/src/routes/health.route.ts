import { Router } from "express";
import { pool } from "../database/pool";

export const healthRouter: Router = Router();

healthRouter.get("/", (_req, res) => {
  res.status(200).json({
    success: true,
    data: {
      status: "ok",
      service: "household-os-api",
      timestamp: new Date().toISOString()
    }
  });
});

healthRouter.get("/ready", async (_req, res) => {
  try {
    await pool.query("SELECT 1");
    res.status(200).json({
      success: true,
      data: {
        status: "ready",
        database: "ok",
        timestamp: new Date().toISOString()
      }
    });
  } catch {
    res.status(503).json({
      success: false,
      error: {
        code: "DATABASE_UNAVAILABLE",
        message: "Database is not reachable"
      }
    });
  }
});
