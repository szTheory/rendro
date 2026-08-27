#!/usr/bin/env node

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import * as pdfjsLib from "pdfjs-dist/legacy/build/pdf.mjs";

const OBSERVER = "rendro-pdfjs-advisory";
const SCHEMA_VERSION = 1;
const OBSERVATION_KEYS = new Set([
  "schema_version",
  "observer",
  "advisory_boundary",
  "pdfjs_dist_version",
  "node_version",
  "recorded_at",
  "platform",
  "fixture",
  "page_count",
  "pages",
  "warnings",
  "errors",
  "first_page_png_sha256"
]);
const PAGE_KEYS = new Set(["page_number", "width", "height"]);

const FIXTURES = [
  {
    fixture: "test/fixtures/embedded_artifact_support_fixture.pdf",
    output: "priv/pdfjs_observations/embedded_artifact_support_fixture.json"
  },
  {
    fixture: "test/fixtures/pdfjs-rendro.pdf",
    output: "priv/pdfjs_observations/bench_rendro_invoice.json"
  }
];

const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, "../..");
const pdfjsRoot = path.join(here, "node_modules", "pdfjs-dist");

function usage() {
  return `Usage:
  node scripts/pdfjs_observer/observe.mjs --write
  node scripts/pdfjs_observer/observe.mjs --check
  node scripts/pdfjs_observer/observe.mjs --help

Records or checks pinned PDF.js advisory observations for committed Rendro PDF fixtures.
This maintainer tool is not a runtime dependency, support-matrix promotion, or GUI-viewer proof.`;
}

function parseMode(argv) {
  if (argv.length !== 1 || argv[0] === "--help" || argv[0] === "-h") {
    if (argv.length === 1 && (argv[0] === "--help" || argv[0] === "-h")) {
      console.log(usage());
      process.exit(0);
    }

    throw new Error(`Expected exactly one mode flag.\n\n${usage()}`);
  }

  if (argv[0] === "--write" || argv[0] === "--check") {
    return argv[0].slice(2);
  }

  throw new Error(`Unknown option ${argv[0]}.\n\n${usage()}`);
}

function repoPath(relativePath) {
  if (path.isAbsolute(relativePath) || relativePath.includes("..")) {
    throw new Error(`Fixture paths must be repo-relative allowlist entries: ${relativePath}`);
  }

  return path.join(repoRoot, relativePath);
}

function stableObservation(observation) {
  return {
    schema_version: observation.schema_version,
    observer: observation.observer,
    advisory_boundary: observation.advisory_boundary,
    pdfjs_dist_version: observation.pdfjs_dist_version,
    fixture: observation.fixture,
    page_count: observation.page_count,
    pages: observation.pages,
    warnings: observation.warnings,
    errors: observation.errors,
    first_page_png_sha256: observation.first_page_png_sha256
  };
}

function assertObservationShape(observation, output) {
  const requiredStrings = [
    "observer",
    "advisory_boundary",
    "pdfjs_dist_version",
    "node_version",
    "recorded_at",
    "platform",
    "fixture"
  ];

  assertAllowedKeys(observation, OBSERVATION_KEYS, output);

  if (observation.schema_version !== SCHEMA_VERSION) {
    throw new Error(`${output}: expected schema_version ${SCHEMA_VERSION}`);
  }

  for (const key of requiredStrings) {
    if (typeof observation[key] !== "string" || observation[key].length === 0) {
      throw new Error(`${output}: expected non-empty string ${key}`);
    }
  }

  if (!Number.isInteger(observation.page_count) || observation.page_count < 1) {
    throw new Error(`${output}: expected positive integer page_count`);
  }

  if (!Array.isArray(observation.pages) || observation.pages.length !== observation.page_count) {
    throw new Error(`${output}: expected pages length to match page_count`);
  }

  if (!Array.isArray(observation.warnings) || !Array.isArray(observation.errors)) {
    throw new Error(`${output}: expected warnings and errors arrays`);
  }

  if (
    Object.hasOwn(observation, "first_page_png_sha256") &&
    !/^[0-9a-f]{64}$/.test(observation.first_page_png_sha256)
  ) {
    throw new Error(`${output}: expected lowercase SHA-256 first_page_png_sha256`);
  }

  for (const page of observation.pages) {
    assertAllowedKeys(page, PAGE_KEYS, `${output} page ${page.page_number || "?"}`);

    if (!Number.isInteger(page.page_number) || page.page_number < 1) {
      throw new Error(`${output}: expected positive integer page_number`);
    }

    if (typeof page.width !== "number" || page.width <= 0) {
      throw new Error(`${output}: expected positive page width`);
    }

    if (typeof page.height !== "number" || page.height <= 0) {
      throw new Error(`${output}: expected positive page height`);
    }
  }
}

function assertAllowedKeys(object, allowedKeys, output) {
  for (const key of Object.keys(object)) {
    if (!allowedKeys.has(key)) {
      throw new Error(`${output}: unexpected key ${key}`);
    }
  }
}

async function captureConsole(fn) {
  const warnings = [];
  const errors = [];
  const originalWarn = console.warn;
  const originalError = console.error;

  console.warn = (...args) => warnings.push(args.map(String).join(" "));
  console.error = (...args) => errors.push(args.map(String).join(" "));

  try {
    const value = await fn();
    return { value, warnings, errors };
  } finally {
    console.warn = originalWarn;
    console.error = originalError;
  }
}

async function observeFixture(fixture) {
  const absoluteFixture = repoPath(fixture.fixture);
  const data = new Uint8Array(fs.readFileSync(absoluteFixture));

  const { value, warnings, errors } = await captureConsole(async () => {
    const loadingTask = pdfjsLib.getDocument({
      data,
      disableWorker: true,
      cMapUrl: path.join(pdfjsRoot, "cmaps") + path.sep,
      cMapPacked: true,
      standardFontDataUrl: path.join(pdfjsRoot, "standard_fonts") + path.sep
    });

    const doc = await loadingTask.promise;
    const pages = [];

    try {
      for (let pageNumber = 1; pageNumber <= doc.numPages; pageNumber += 1) {
        const page = await doc.getPage(pageNumber);
        const viewport = page.getViewport({ scale: 1.0 });

        pages.push({
          page_number: pageNumber,
          width: Number(viewport.width.toFixed(4)),
          height: Number(viewport.height.toFixed(4))
        });

        page.cleanup();
      }

      return {
        page_count: doc.numPages,
        pages
      };
    } finally {
      await doc.cleanup();
      await loadingTask.destroy();
    }
  });

  return {
    schema_version: SCHEMA_VERSION,
    observer: OBSERVER,
    advisory_boundary:
      "Pinned PDF.js advisory observation only; not GUI-viewer proof or Rendro runtime support.",
    pdfjs_dist_version: pdfjsLib.version,
    node_version: process.version,
    recorded_at: new Date().toISOString(),
    platform: `${process.platform}-${process.arch}; ${os.type()} ${os.release()}`,
    fixture: fixture.fixture,
    page_count: value.page_count,
    pages: value.pages,
    warnings,
    errors
  };
}

function writeJson(output, data) {
  fs.mkdirSync(path.dirname(repoPath(output)), { recursive: true });
  fs.writeFileSync(repoPath(output), `${JSON.stringify(data, null, 2)}\n`);
}

function readJson(output) {
  return JSON.parse(fs.readFileSync(repoPath(output), "utf8"));
}

async function writeObservations() {
  for (const fixture of FIXTURES) {
    const observation = await observeFixture(fixture);
    assertObservationShape(observation, fixture.output);
    writeJson(fixture.output, observation);
    console.log(`Wrote ${fixture.output}`);
  }
}

async function checkObservations() {
  for (const fixture of FIXTURES) {
    const expected = readJson(fixture.output);
    const actual = await observeFixture(fixture);

    assertObservationShape(expected, fixture.output);
    assertObservationShape(actual, fixture.output);

    if (
      JSON.stringify(stableObservation(actual)) !== JSON.stringify(stableObservation(expected))
    ) {
      console.error(`Observation drift for ${fixture.output}`);
      console.error("Expected stable facts:");
      console.error(JSON.stringify(stableObservation(expected), null, 2));
      console.error("Actual stable facts:");
      console.error(JSON.stringify(stableObservation(actual), null, 2));
      process.exit(1);
    }

    console.log(`Checked ${fixture.output}`);
  }
}

async function main() {
  const mode = parseMode(process.argv.slice(2));

  if (mode === "write") {
    await writeObservations();
  } else {
    await checkObservations();
  }
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
