#!/usr/bin/env bash
set -euo pipefail

HEXDOCS_RETRIES="${HEXDOCS_RETRIES:-20}"
HEXDOCS_DELAY_SECONDS="${HEXDOCS_DELAY_SECONDS:-15}"

check_contains() {
  local label="$1"
  local url="$2"
  local needle="$3"

  printf 'Checking %s... ' "$label"
  if curl -fsSL "$url" | grep -F "$needle" >/dev/null; then
    printf 'PASS\n'
  else
    printf 'FAIL\n'
    return 1
  fi
}

check_status_once() {
  local url="$1"
  curl -fsSL -o /dev/null "$url"
}

check_hexdocs_status() {
  local label="$1"
  local url="$2"
  local attempt

  for attempt in $(seq 1 "$HEXDOCS_RETRIES"); do
    printf 'Checking %s (%s/%s)... ' "$label" "$attempt" "$HEXDOCS_RETRIES"

    if check_status_once "$url"; then
      printf 'PASS\n'
      return 0
    fi

    printf 'not ready\n'
    if [ "$attempt" -lt "$HEXDOCS_RETRIES" ]; then
      sleep "$HEXDOCS_DELAY_SECONDS"
    fi
  done

  printf 'FAIL: %s did not become available at %s\n' "$label" "$url" >&2
  return 1
}

check_contains \
  "GitHub README" \
  "https://raw.githubusercontent.com/szTheory/rendro/main/README.md" \
  "Rendered Recipe Gallery"

check_contains \
  "GitHub comparison guide" \
  "https://raw.githubusercontent.com/szTheory/rendro/main/guides/comparison.md" \
  "Generating PDFs in Elixir without Chrome"

check_contains \
  "GitHub Livebook" \
  "https://raw.githubusercontent.com/szTheory/rendro/main/guides/livebook/first_invoice.livemd" \
  "First Invoice"

check_contains \
  "GitHub ADOPTION.md" \
  "https://raw.githubusercontent.com/szTheory/rendro/main/ADOPTION.md" \
  "# Adoption Signals"

check_hexdocs_status "HexDocs README" "https://hexdocs.pm/rendro/readme.html"
check_hexdocs_status "HexDocs comparison guide" "https://hexdocs.pm/rendro/comparison.html"
check_hexdocs_status "HexDocs Livebook" "https://hexdocs.pm/rendro/first_invoice.html"

printf 'Public launch URLs verified.\n'
