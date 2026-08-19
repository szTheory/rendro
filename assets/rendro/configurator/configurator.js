(() => {
  "use strict";

  const FALLBACK = { family: "invoice", preset: "swiss", accent: "#2C6BED", mode: "light" };
  const LOADING_COPY = "Loading catalog previews…";
  const ERROR_COPY = "Couldn’t load the catalog or copy the snippet. Reload this documentation page and try again.";
  const controls = Object.fromEntries(["family", "preset", "accent", "mode"].map((key) => [key, document.getElementById(key)]));
  const status = document.getElementById("status");
  const error = document.getElementById("error");
  const preview = document.getElementById("preview");
  const disclosure = document.getElementById("disclosure");
  const snippetCode = document.getElementById("snippet-code");
  const copyButton = document.getElementById("copy-snippet");
  let index;
  let catalog;

  const validSlug = (value) => typeof value === "string" && /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(value);
  const validAccent = (value) => typeof value === "string" && /^#[0-9A-F]{6}$/.test(value);
  const validateSafeCatalogPath = (value) => typeof value === "string" && /^assets\/rendro\/catalog\/[a-z0-9-]+\/[a-z0-9-]+\/[a-z0-9-]+-(?:light|dark)\.png$/.test(value);
  const setStatus = (message) => { status.textContent = message; };
  const setEnabled = (enabled) => {
    Object.values(controls).forEach((control) => { control.disabled = !enabled; });
    copyButton.disabled = !enabled;
  };

  const fail = () => {
    setEnabled(false);
    preview.replaceChildren();
    disclosure.replaceChildren();
    snippetCode.textContent = "";
    error.textContent = ERROR_COPY;
    error.hidden = false;
    setStatus("Catalog previews are unavailable.");
  };

  const optionsAreValid = (options) => ["families", "presets", "accents", "modes"].every((name) => Array.isArray(options[name]) && options[name].every((option) => option && typeof option.label === "string" && (name === "accents" ? validAccent(option.value) : validSlug(option.value))));
  const indexIsValid = (candidate) => candidate && candidate.schema_version === 1 && optionsAreValid(candidate.options) && Array.isArray(candidate.records) && candidate.records.length > 0 && candidate.records.every((record) => validSlug(record.family) && validSlug(record.preset) && validAccent(record.accent) && (record.mode === "light" || record.mode === "dark") && typeof record.snippet === "string");
  const catalogCellIsValid = (cell) => validSlug(cell.family) && ((cell.preset === null && cell.accent === null && cell.mode === "light") || (validSlug(cell.preset) && validAccent(cell.accent) && (cell.mode === "light" || cell.mode === "dark"))) && validateSafeCatalogPath(cell.png_path) && typeof cell.alt === "string" && typeof cell.caption === "string";
  const catalogIsValid = (candidate) => candidate && Array.isArray(candidate.cells) && candidate.cells.every(catalogCellIsValid);

  const allowedValues = (name) => new Set(index.options[name].map((option) => option.value));
  const catalogUsesClosedEnums = () => catalog.cells.filter((cell) => cell.preset !== null).every((cell) => allowedValues("families").has(cell.family) && allowedValues("presets").has(cell.preset) && allowedValues("accents").has(cell.accent) && allowedValues("modes").has(cell.mode));
  const firstSelectableState = () => {
    const cell = catalog.cells.find((candidate) => allowedValues("families").has(candidate.family) && allowedValues("presets").has(candidate.preset) && allowedValues("accents").has(candidate.accent) && allowedValues("modes").has(candidate.mode));
    return cell ? { family: cell.family, preset: cell.preset, accent: cell.accent, mode: cell.mode } : FALLBACK;
  };
  const readRequestedState = () => {
    const params = new URLSearchParams(window.location.search);
    const keys = ["family", "preset", "accent", "mode"];
    const state = Object.fromEntries(keys.map((key) => [key, params.getAll(key)]));
    const valid = state.family.length === 1 && state.preset.length === 1 && state.accent.length === 1 && state.mode.length === 1 && allowedValues("families").has(state.family[0]) && allowedValues("presets").has(state.preset[0]) && allowedValues("accents").has(state.accent[0]) && allowedValues("modes").has(state.mode[0]);
    return valid ? Object.fromEntries(keys.map((key) => [key, state[key][0]])) : firstSelectableState();
  };
  const writeCanonicalUrl = (state) => {
    const params = new URLSearchParams();
    ["family", "preset", "accent", "mode"].forEach((key) => params.set(key, state[key]));
    history.replaceState(null, "", `${window.location.pathname}?${params.toString()}${window.location.hash}`);
  };
  const recordFor = (state) => index.records.find((record) => record.family === state.family && record.preset === state.preset && record.accent === state.accent && record.mode === state.mode);
  const resolvePreview = (state) => {
    const exact = catalog.cells.find((cell) => cell.family === state.family && cell.preset === state.preset && cell.accent === state.accent && cell.mode === state.mode);
    if (exact) return { kind: "exact", cell: exact };
    const representative = catalog.cells.find((cell) => cell.family === state.family && cell.preset === state.preset && cell.mode === state.mode && cell.accent !== state.accent);
    return representative ? { kind: "representative", cell: representative } : { kind: "none", cell: null };
  };
  const renderPreview = (resolution, state) => {
    preview.replaceChildren();
    disclosure.replaceChildren();
    if (resolution.kind === "none") {
      setStatus("No catalog preview matches this selection. Copied code is valid, but this catalog has no equivalent pre-rendered example.");
      return;
    }
    const image = document.createElement("img");
    image.src = `../catalog/${resolution.cell.png_path.split("/").slice(3).join("/")}`;
    image.alt = resolution.cell.alt;
    image.addEventListener("load", () => setStatus(resolution.kind === "exact" ? `Exact pre-rendered ${state.preset} · ${state.accent} · ${state.mode} preview.` : `Preview: catalog example uses ${resolution.cell.accent}. Copied code uses your exact accent ${state.accent}.`), { once: true });
    image.addEventListener("error", fail, { once: true });
    const figure = document.createElement("figure");
    const caption = document.createElement("figcaption");
    caption.textContent = resolution.cell.caption;
    figure.append(image, caption);
    preview.append(figure);
    if (resolution.kind === "representative") {
      disclosure.textContent = `Preview: nearest available catalog example (${resolution.cell.accent}). Copied code uses your exact accent ${state.accent}.`;
    } else if (resolution.cell.boundary_disclosure) {
      disclosure.textContent = resolution.cell.boundary_disclosure;
    }
  };
  const render = () => {
    const state = Object.fromEntries(Object.entries(controls).map(([key, control]) => [key, control.value]));
    const record = recordFor(state);
    if (!record) return fail();
    writeCanonicalUrl(state);
    snippetCode.textContent = record.snippet;
    renderPreview(resolvePreview(state), state);
  };
  const populate = () => {
    const names = { family: "families", preset: "presets", accent: "accents", mode: "modes" };
    Object.entries(names).forEach(([controlName, optionName]) => {
      controls[controlName].replaceChildren(...index.options[optionName].map((option) => {
        const node = document.createElement("option");
        node.value = option.value;
        node.textContent = option.label;
        return node;
      }));
      controls[controlName].addEventListener("change", render);
    });
    const requested = readRequestedState();
    Object.entries(requested).forEach(([key, value]) => { controls[key].value = value; });
    setEnabled(true);
    error.hidden = true;
    render();
  };
  copyButton.addEventListener("click", async () => {
    const visibleCodeText = snippetCode.textContent;
    try {
      await navigator.clipboard.writeText(visibleCodeText);
      error.replaceChildren();
      error.hidden = true;
      copyButton.textContent = "Snippet copied";
      setStatus("Snippet copied");
      window.setTimeout(() => { copyButton.textContent = "Copy Elixir snippet"; }, 2000);
    } catch (_error) {
      error.textContent = ERROR_COPY;
      error.hidden = false;
      setStatus("Snippet could not be copied. Select the visible source and try again.");
    }
  });
  setStatus(LOADING_COPY);
  Promise.all([fetch("index.json"), fetch("../catalog.json")])
    .then(async ([indexResponse, catalogResponse]) => {
      if (!indexResponse.ok || !catalogResponse.ok) throw new Error("catalog request failed");
      [index, catalog] = await Promise.all([indexResponse.json(), catalogResponse.json()]);
      if (!indexIsValid(index) || !catalogIsValid(catalog) || !catalogUsesClosedEnums()) throw new Error("catalog schema failed");
      populate();
    })
    .catch(fail);
})();
