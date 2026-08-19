import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./tests",
  fullyParallel: false,
  workers: 1,
  retries: 0,
  timeout: 30_000,
  reporter: [["list"], ["html", { outputFolder: "playwright-report", open: "never" }]],
  use: {
    baseURL: "http://127.0.0.1:4174/configurator/index.html",
    browserName: "chromium",
    locale: "en-US",
    timezoneId: "UTC",
    deviceScaleFactor: 1,
    trace: "retain-on-failure",
    video: "retain-on-failure",
    screenshot: "only-on-failure"
  },
  webServer: { command: "node static-server.mjs", port: 4174, reuseExistingServer: false }
});
