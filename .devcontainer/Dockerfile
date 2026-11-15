# syntax=docker/dockerfile:1
FROM ubuntu:24.04

ARG RIG_VERSION=0.11.1
ARG RUST_TOOLCHAIN=stable
ARG PROJECT_DIR=/workspace/caulobrowser

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 LC_ALL=C.UTF-8

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    just \
    less \
    openssh-client \
    procps \
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
    libcurl4-openssl-dev \
    librsvg2-dev \
    libmagick++-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Pelican
RUN case "$(uname -m)" in \
      x86_64) ARCH="x86_64" ;; \
      aarch64) ARCH="arm64" ;; \
      *) echo "Unsupported arch: $(uname -m)" && exit 1 ;; \
    esac && \
    wget -O - "https://dl.pelicanplatform.org/latest/pelican_Linux_${ARCH}.tar.gz" \
    | tar zx -C /usr/local/bin/ --strip-components=1

# rig binary: root-owned, read-only at runtime
RUN curl -fsSL "https://github.com/r-lib/rig/releases/download/v${RIG_VERSION}/rig-linux-$(arch)-${RIG_VERSION}.tar.gz" \
    | tar xz -C /usr/local

# Renames the ubuntu user
RUN usermod -l coder -d /home/coder -m ubuntu \
 && groupmod -n coder ubuntu \
 && install -d -o coder -g coder /opt/r /opt/rust /opt/duckdb /workspaces "${PROJECT_DIR}"

# R, Rust and DuckDB state live outside $HOME
ENV RIG_MODE=user \
    RIG_R_INSTALL_DIR=/opt/r/versions \
    RIG_BINARY_DIR=/opt/r/bin \
    RIG_PROJ_LIBRARY_ROOT=/opt/r/projects \
    R_LIBS_USER=/opt/r/library/%v \
    RUSTUP_HOME=/opt/rust/rustup \
    CARGO_HOME=/opt/rust/cargo \
    DUCKDB_R_HOME=/opt/duckdb \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    PATH=/opt/rust/cargo/bin:/opt/r/bin:${PATH}

# --- user: everything below stays writable at runtime ---
USER 1000:1000

# Rust: rustup/cargo can add toolchains and crates later without root
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path \
      --profile minimal --default-toolchain "${RUST_TOOLCHAIN}" \
      -c rustfmt -c clippy -c rust-src

# R + deps from rproj.lock (the lock pins the R version).
# The package itself is installed at runtime, from the real checkout.
WORKDIR ${PROJECT_DIR}
COPY --chown=1000:1000 rproj.toml rproj.lock ./
RUN rig proj sync --frozen --no-install-project \
 && rig library add tools \
 && rig pkg install -l tools devtools languageserver \
 && rm -rf /tmp/rig-* ~/.cache

# DuckDB extensions into $DUCKDB_R_HOME, matching the locked duckdb version.
# Then leave PROJECT_DIR empty for the real checkout.
RUN .rvenv/bin/Rscript -e 'library(duckdb); \
      con <- dbConnect(duckdb()); \
      for (ext in c("json")) dbExecute(con, sprintf("INSTALL %s", ext)); \
      dbDisconnect(con, shutdown = TRUE)' \
 && find . -mindepth 1 -delete

WORKDIR /home/coder
