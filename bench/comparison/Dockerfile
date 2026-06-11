FROM hexpm/elixir:1.19.3-erlang-27.3.4.1-debian-bookworm-20251117-slim

ENV MIX_ENV=prod \
    MIX_INSTALL_DIR=/root/.cache/mix/installs

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      chromium \
      fonts-dejavu-core \
      time \
      wkhtmltopdf && \
    rm -rf /var/lib/apt/lists/*

COPY bench/comparison/tools/prewarm_mix_install.exs /tmp/rendro_prewarm_mix_install.exs

RUN mix local.hex --force && \
    mix local.rebar --force && \
    elixir /tmp/rendro_prewarm_mix_install.exs chromic_pdf && \
    elixir /tmp/rendro_prewarm_mix_install.exs pdf_generator
