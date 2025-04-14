# --- BUILD STAGE ---
ARG ELIXIR_VERSION=1.14.0
ARG OTP_VERSION=25.1.1
ARG DEBIAN_VERSION=bullseye-20220801-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} AS builder

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod

# Install dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy config files
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Copy source
COPY priv priv
COPY lib lib
COPY assets assets

# Assets and compilation
RUN mix assets.deploy
RUN mix compile

# Copy runtime config
COPY config/runtime.exs config/

# Copy rel directory and build release
COPY rel rel
RUN apt-get update -y && apt-get install -y dos2unix && find rel/ -type f -exec dos2unix {} +
RUN mix release

# --- RUN STAGE ---
FROM ${RUNNER_IMAGE}

# Install runtime dependencies
RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app
RUN chown nobody /app
USER nobody

ENV MIX_ENV=prod

# Copy release from build stage
COPY --from=builder --chown=nobody:root /app/_build/prod/rel/landbuyer /app/

# Launch the release directly
CMD ["/app/bin/landbuyer", "start"]

# Fly.io runtime settings
ENV ECTO_IPV6=true
ENV ERL_AFLAGS="-proto_dist inet6_tcp"
