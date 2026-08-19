import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

const state = "family=invoice&preset=swiss&accent=%232C6BED&mode=light";
const noExternal = (page, expectedConsoleErrors = []) => {
  const failures = [];
  page.on("console", (message) => message.type() === "error" && !expectedConsoleErrors.includes(message.text()) && failures.push(`console: ${message.text()}`));
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

test("clipboard rejection retains exact source and a successful retry clears its actionable alert", async ({ page }) => {
  const finish = noExternal(page);
  await page.addInitScript(() => {
    let attempts = 0;
    window.__rendroCopiedSources = [];
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: {
        writeText: async (source) => {
          window.__rendroCopiedSources.push(source);
          attempts += 1;
          if (attempts === 1) throw new DOMException("rejected", "NotAllowedError");
        }
      }
    });
  });
  await visit(page);
  const source = await page.locator("#snippet-code").textContent();

  await page.locator("#copy-snippet").click();
  await expect(page.locator("#snippet-code")).toHaveText(source);
  await expect(page.locator("#copy-snippet")).toBeEnabled();
  await expect(page.locator("#error[role=alert]")).toBeVisible();
  await expect(page.locator("#error")).toContainText("Reload this documentation page and try again.");
  await expect(page.locator("#status")).toHaveText("Snippet could not be copied. Select the visible source and try again.");

  await page.locator("#copy-snippet").click();
  await expect(page.locator("#copy-snippet")).toHaveText("Snippet copied");
  await expect(page.locator("#status")).toHaveText("Snippet copied");
  await expect(page.locator("#error[role=alert]")).toBeHidden();
  expect(await page.evaluate(() => window.__rendroCopiedSources)).toEqual([source, source]);
  await expect(page.locator("#copy-snippet")).toBeFocused();
  await expect(page.locator("#copy-snippet")).toBeEnabled();
  finish();
});

test("selected preview-image failure clears fabricated content and reload restores it", async ({ page }) => {
  const finish = noExternal(page, ["Failed to load resource: net::ERR_FAILED"]);
  const selectedPng = "**/catalog/invoice/northline-logistics/swiss-light.png";
  let failures = 0;
  await page.route(selectedPng, async (route) => {
    failures += 1;
    await route.abort("failed");
  });
  await page.goto(`?${state}`);
  await expect(page.locator("#error[role=alert]")).toBeVisible();
  await expect(page.locator("#error")).toContainText("Reload this documentation page and try again.");
  await expect(page.locator("#status")).toHaveText("Catalog previews are unavailable.");
  await expect(page.locator("#preview img")).toHaveCount(0);
  await expect(page.locator("#snippet-code")).toBeEmpty();
  for (const control of ["#family", "#preset", "#accent", "#mode", "#copy-snippet"]) {
    await expect(page.locator(control)).toBeDisabled();
  }
  expect(failures).toBe(1);

  await page.unroute(selectedPng);
  await page.reload();
  await expect(page.locator("#preview img")).toHaveCount(1);
  await expect(page.locator("#error[role=alert]")).toBeHidden();
  await expect(page.locator("#snippet-code")).not.toBeEmpty();
  await expect(page.locator("#status")).toHaveText("Exact pre-rendered swiss · #2C6BED · light preview.");
  for (const control of ["#family", "#preset", "#accent", "#mode", "#copy-snippet"]) {
    await expect(page.locator(control)).toBeEnabled();
  }
  finish();
});

for (const [name, colorScheme, query, expectedBackground, expectedMode] of [
  ["dark chrome with a light document", "dark", state, "rgb(27, 23, 19)", "light"],
  ["light chrome with a dark document", "light", "family=invoice&preset=swiss&accent=%232C6BED&mode=dark", "rgb(247, 243, 234)", "dark"]
]) {
  test(`browser chrome and document mode remain independent: ${name}`, async ({ page }) => {
    const finish = noExternal(page);
    await page.emulateMedia({ colorScheme });
    await visit(page, query);
    await expect(page.locator("body")).toHaveCSS("background-color", expectedBackground);
    await expect(page.locator("#mode")).toHaveValue(expectedMode);
    await expect(page).toHaveURL(new RegExp(`mode=${expectedMode}`));
    await expect(page.locator("#snippet-code")).toContainText(`mode: :${expectedMode}`);
    await expect(page.locator("#preview img")).toHaveAttribute("src", new RegExp(`swiss-${expectedMode}\\.png`));
    if (expectedMode === "dark") {
      await expect(page.locator("#disclosure")).toContainText("Screen-oriented");
    } else {
      await expect(page.locator("#status")).toHaveText("Exact pre-rendered swiss · #2C6BED · light preview.");
    }
    finish();
  });
}

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
