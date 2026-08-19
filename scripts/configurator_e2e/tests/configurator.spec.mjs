import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

const state = "family=invoice&preset=swiss&accent=%232C6BED&mode=light";
const noExternal = (page) => {
  const failures = [];
  page.on("console", (message) => message.type() === "error" && failures.push(`console: ${message.text()}`));
  page.on("pageerror", (error) => failures.push(`page: ${error.message}`));
  page.on("request", (request) => !request.url().startsWith("http://127.0.0.1:4174/") && failures.push(`external: ${request.url()}`));
  return () => expect(failures).toEqual([]);
};
const visit = async (page, query = state) => { await page.goto(`?${query}`); await expect(page.locator("#copy-snippet")).toBeEnabled(); };
const scan = async (page) => {
  const results = await new AxeBuilder({ page }).include("main.configurator-page").analyze();
  expect(results.violations).toEqual([]);
};

test("canonical URL fallback and exact source/copy round trip are atomic", async ({ page, context }) => {
  const finish = noExternal(page);
  await context.grantPermissions(["clipboard-read", "clipboard-write"], { origin: "http://127.0.0.1:4174" });
  await visit(page, "family=invoice&family=ticket&preset=bad&accent=%23000000&mode=dark");
  await expect(page).toHaveURL(/family=invoice&preset=swiss&accent=%232C6BED&mode=light/);
  const source = await page.locator("#snippet-code").textContent();
  await page.locator("#copy-snippet").click();
  await expect(page.locator("#copy-snippet")).toHaveText("Snippet copied");
  expect(await page.evaluate(() => navigator.clipboard.readText())).toBe(source);
  await expect(page.locator("main")).toMatchAriaSnapshot(`
    - main:
      - heading "Choose a documented theme starting point" [level=1]
      - region "Configuration"
      - region "Catalog preview"
  `);
  await scan(page);
  finish();
});

test("exact, representative, none, failures, keyboard, and motion keep requested code stable", async ({ page }) => {
  const finish = noExternal(page);
  await visit(page);
  const exactSource = await page.locator("#snippet-code").textContent();
  await expect(page.locator("img")).toHaveCount(1);
  await page.selectOption("#accent", "#0E7C76");
  await expect(page.locator("#disclosure")).toContainText("Copied code uses your exact accent #0E7C76");
  expect(await page.locator("#snippet-code").textContent()).not.toBe(exactSource);
  await page.route("**/catalog.json", async (route) => {
    const catalog = await (await route.fetch()).json();
    catalog.cells = catalog.cells.filter((cell) => !(cell.family === "invoice" && cell.preset === "swiss" && cell.mode === "light"));
    await route.fulfill({ json: catalog });
  });
  await visit(page);
  await expect(page.locator("img")).toHaveCount(0);
  await expect(page.locator("#snippet-code")).not.toBeEmpty();
  await page.unrouteAll({ behavior: "wait" });
  await page.emulateMedia({ reducedMotion: "reduce", colorScheme: "dark" });
  await visit(page, "family=invoice&preset=swiss&accent=%232C6BED&mode=dark");
  await expect(page.locator("#disclosure")).toContainText("Screen-oriented");
  await page.locator("#family").focus();
  await page.keyboard.press("Tab");
  await expect(page.locator("#preset")).toBeFocused();
  expect(await page.locator("#copy-snippet").evaluate((element) => getComputedStyle(element).minHeight)).toBe("44px");
  await scan(page);
  finish();
});

for (const [name, viewport, colorScheme, query] of [
  ["desktop-light-exact", { width: 1280, height: 900 }, "light", state],
  ["desktop-dark-exact", { width: 1280, height: 900 }, "dark", "family=invoice&preset=swiss&accent=%232C6BED&mode=dark"],
  ["breakpoint-899-representative", { width: 899, height: 900 }, "light", "family=invoice&preset=swiss&accent=%230E7C76&mode=light"],
  ["breakpoint-900-none", { width: 900, height: 900 }, "light", state],
  ["mobile-dark-representative", { width: 390, height: 844 }, "dark", "family=invoice&preset=swiss&accent=%230E7C76&mode=dark"],
  ["mobile-loading", { width: 390, height: 844 }, "light", state],
  ["mobile-manifest-error", { width: 390, height: 844 }, "light", state]
]) {
  test(`visual baseline ${name}`, async ({ page }) => {
    await page.setViewportSize(viewport); await page.emulateMedia({ colorScheme });
    if (name === "mobile-loading") await page.route("**/index.json", (route) => new Promise(() => route.abort()));
    if (name === "breakpoint-900-none") await page.route("**/catalog.json", async (route) => {
      const catalog = await (await route.fetch()).json();
      catalog.cells = catalog.cells.filter((cell) => !(cell.family === "invoice" && cell.preset === "swiss" && cell.mode === "light"));
      await route.fulfill({ json: catalog });
    });
    if (name === "mobile-manifest-error") await page.route("**/catalog.json", (route) => route.fulfill({ status: 500, body: "failed" }));
    await page.goto(`?${query}`);
    if (!name.startsWith("mobile-loading") && !name.startsWith("mobile-manifest-error")) await expect(page.locator("#copy-snippet")).toBeEnabled();
    await expect(page.locator(".configurator-layout")).toHaveScreenshot(`${name}.png`, { animations: "disabled" });
    if (viewport.width < 900) expect(await page.locator(".configurator-layout").evaluate((el) => getComputedStyle(el).gridTemplateColumns)).not.toContain("320px");
    else expect(await page.locator(".configurator-layout").evaluate((el) => getComputedStyle(el).gridTemplateColumns)).toContain("320px");
  });
}
