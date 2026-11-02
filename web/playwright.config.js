import { defineConfig } from "@playwright/test";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

export default defineConfig({
  testDir: "./tests",
  workers: 1,
  timeout: 30000,
  use: {
    baseURL: "http://127.0.0.1:5174",
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
  },
  webServer: [
    {
      command: "python -m uvicorn app.main:app --host 127.0.0.1 --port 8001",
      cwd: path.join(root, "api"),
      url: "http://127.0.0.1:8001/health",
      reuseExistingServer: false,
      env: {
        DATABASE_URL: "sqlite:///./campah_e2e.db",
        APP_ENV: "development",
        JWT_SECRET: "test-only-secret-for-browser-integration",
        ADMIN_EMAIL: "admin@example.com",
        ADMIN_PASSWORD: "TestAdminPassword123",
        CLOUDINARY_URL: "",
        MODEL_PATH: "./missing-e2e-model.pt",
        CORS_ORIGINS: "http://127.0.0.1:5174",
      },
    },
    {
      command: "npm run dev -- --host 127.0.0.1 --port 5174 --strictPort",
      url: "http://127.0.0.1:5174",
      reuseExistingServer: false,
      env: { VITE_API_URL: "http://127.0.0.1:8001" },
    },
  ],
});
