# Development image for CauloBrowser.
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Same system libraries as the production image, plus development tools
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

# Rust, installed system-wide and writable by the dev user: ggsql has no Linux
# binary and is compiled from source, and cargo writes to CARGO_HOME while building
ENV RUSTUP_HOME=/usr/local/rustup CARGO_HOME=/usr/local/cargo
ENV PATH="/usr/local/cargo/bin:${PATH}"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path --profile minimal \
    && chmod -R a+w "$RUSTUP_HOME" "$CARGO_HOME"

# Pelican binary (arch from uname, so it works without BuildKit's TARGETARCH)
RUN case "$(uname -m)" in \
      x86_64) ARCH="x86_64" ;; \
      aarch64) ARCH="arm64" ;; \
      *) echo "Unsupported arch: $(uname -m)" && exit 1 ;; \
    esac && \
    wget -O - "https://dl.pelicanplatform.org/latest/pelican_Linux_${ARCH}.tar.gz" \
    | tar zx -C /usr/local/bin/ --strip-components=1

# rig in user mode
COPY --from=ghcr.io/r-lib/rig/base:latest /rig /usr/local/bin/rig
ENV RIG_MODE=user

# Non-root dev user, UID 1000 (replaces Ubuntu's default "ubuntu" user).
ARG USERNAME=coder
ARG USER_UID=1000
RUN userdel --remove ubuntu 2>/dev/null || true \
    && useradd --create-home --uid "$USER_UID" --user-group --shell /bin/bash "$USERNAME"
# rig's quick links (R, Rscript), for processes that don't read shell startup files
ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"
USER $USERNAME
