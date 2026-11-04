# syntax=docker/dockerfile:1
FROM ubuntu:24.04
ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    wget \
    tar \
    make \
    cmake \
    libnode-dev \
    unixodbc-dev \
    xz-utils \
    libcairo2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    pandoc \
    zlib1g-dev \
    libssl-dev \
    libuv1-dev \
    libcurl4-openssl-dev curl \
    librsvg2-dev \
    libmagick++-dev \
    && rm -rf /var/lib/apt/lists/*

# Install rust (needed to build Rust-backed R packages from source)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Setup pelican binary
RUN mkdir -p /usr/local/bin && \
    case "$TARGETARCH" in \
      amd64) ARCH="x86_64" ;; \
      arm64) ARCH="arm64" ;; \
      *) echo "Unsupported arch: $TARGETARCH" && exit 1 ;; \
    esac && \
    wget -O - "https://dl.pelicanplatform.org/latest/pelican_$(uname -s)_${ARCH}.tar.gz" \
    | tar zx -C /usr/local/bin/ --strip-components=1

# Install rig
COPY --from=ghcr.io/r-lib/rig/base:latest /rig /usr/local/bin/rig

# Install R and the locked dependencies. rig installs the R version recorded in
# rproj.lock and puts the packages in the project library, /app/.rvenv/lib.
# Only the lock files are copied here so this layer is cached until they change.
WORKDIR /app
COPY rproj.toml rproj.lock ./
RUN --mount=type=cache,id=rig-cache,target=/root/.cache/rig-docker \
    rig proj sync --frozen --no-dev --no-install-project \
      --cache-dir /root/.cache/rig-docker

# Download duckdb extensions
# Fixed DuckDB home so extensions installed at build time are found at runtime
ENV DUCKDB_R_HOME=/opt/duckdb
RUN mkdir -p $DUCKDB_R_HOME && /app/.rvenv/bin/R -q -e 'library(duckdb); \
  con <- dbConnect(duckdb()); \
  for (ext in c("json")) dbExecute(con, sprintf("INSTALL %s", ext)); \
  dbDisconnect(con, shutdown = TRUE)'

# Install the app itself into the project library. The dependencies are
# already there, so this sync only installs caulobrowser from /app.
COPY DESCRIPTION NAMESPACE LICENSE ./
COPY R ./R
COPY inst ./inst
COPY man ./man
RUN rig proj sync --frozen --no-dev

EXPOSE 3838
ENV CAULOBROWSER_DB_PATH=/database/caulobrowser.duckdb
RUN mkdir /database

# Create HOME dir and make it world writable
ENV HOME=/home/caulobrowser
RUN useradd --uid 10001 --home-dir $HOME --no-create-home --shell /usr/sbin/nologin caulobrowser \
    && mkdir -m 1777 $HOME
WORKDIR $HOME
USER 10001
CMD ["/app/.rvenv/bin/R", "-e", "options(shiny.port = 3838, shiny.host = '0.0.0.0'); caulobrowser::run_app()"]
