# ---------------------------------------
#         ⛏️ STAGE 1: BUILD
# ---------------------------------------
ARG ELIXIR_VERSION=1.14.0
ARG OTP_VERSION=25.1.1
ARG DEBIAN_VERSION=bullseye-20220801-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} as builder

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Prepare working directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set ENV
ENV MIX_ENV="prod"

# Install deps
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

# Build assets
RUN mix assets.deploy

# Compile app
RUN mix compile

# Copy runtime config
COPY config/runtime.exs config/

# Copy release config (includes overlays)
COPY rel rel

# Build release
RUN mix release

# ---------------------------------------
#         🚀 STAGE 2: RUNNER
# ---------------------------------------
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# App directory
WORKDIR "/app"
RUN chown nobody /app

# Set ENV
ENV MIX_ENV="prod"

# Copy compiled release
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/landbuyer /app/

# Drop privileges
USER nobody

# Start the app via overlayed script (created by mix release overlays)
CMD ["/app/bin/server"]

# Appended by flyctl
ENV ECTO_IPV6 true
ENV ERL_AFLAGS "-proto_dist inet6_tcp"
