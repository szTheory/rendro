defmodule Rendro.DocsContract.ConfiguratorStaticContractTest do
  use ExUnit.Case, async: true

  @html "assets/rendro/configurator/index.html"
  @css "assets/rendro/configurator/configurator.css"
  @javascript "assets/rendro/configurator/configurator.js"

  test "static configurator uses semantic native controls and a no-submit shell" do
    html = File.read!(@html)

    for control <- ~w(family preset accent mode) do
      assert html =~ "<label for=\"#{control}\""
      assert html =~ "<select id=\"#{control}\" name=\"#{control}\" disabled>"
    end

    assert html =~ "<pre id=\"snippet\""
    assert html =~ "<code id=\"snippet-code\">"
    assert html =~ "Copy Elixir snippet"
    assert html =~ "aria-live=\"polite\""
    assert html =~ "role=\"alert\""
    refute html =~ ~r/<form[^>]+action=/
    refute html =~ ~r/<form[^>]+method=/
  end

  test "static assets retain the locked responsive and token-native presentation" do
    css = File.read!(@css)

    assert css =~ "var(--rendro-grid-app-max)"
    assert css =~ "minmax(0, 320px)"
    assert css =~ "@media (max-width: 899px)"
    assert css =~ "min-height: 44px"
    assert css =~ "overflow-x: auto"
    assert css =~ "@media (prefers-reduced-motion: reduce)"
    assert css =~ ":focus-visible"
    refute css =~ ~r/#[0-9A-Fa-f]{3,8}/
  end

  test "browser controller remains static, safe, and fail closed" do
    javascript = File.read!(@javascript)

    assert javascript =~ "Loading catalog previews…"

    assert javascript =~
             "Couldn’t load the catalog or copy the snippet. Reload this documentation page and try again."

    assert javascript =~ "fetch(\"index.json\")"
    assert javascript =~ "fetch(\"../catalog.json\")"
    assert javascript =~ "textContent"
    assert javascript =~ "replaceState"
    assert javascript =~ "navigator.clipboard.writeText"
    assert javascript =~ "URLSearchParams"
    assert javascript =~ "validateSafeCatalogPath"
    refute javascript =~ "innerHTML"
    refute javascript =~ "eval("
    refute javascript =~ "localStorage"
    refute javascript =~ "sessionStorage"
    refute javascript =~ "XMLHttpRequest"
    refute javascript =~ "fetch(\"http"
  end
end
