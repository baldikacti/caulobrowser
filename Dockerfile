FROM baldikacti/caulobrowser_base:latest
ARG TARGETARCH
# Setup pelican binary
RUN mkdir -p /usr/local/bin && \
    case "$TARGETARCH" in \
      amd64) ARCH="x86_64" ;; \
      arm64) ARCH="arm64" ;; \
      *) echo "Unsupported arch: $TARGETARCH" && exit 1 ;; \
    esac && \
    wget -O - "https://dl.pelicanplatform.org/latest/pelican_$(uname -s)_${ARCH}.tar.gz" \
    | tar zx -C /usr/local/bin/ --strip-components=1
COPY renv.lock renv.lock
RUN R -e 'options(renv.config.pak.enabled = FALSE);renv::restore()'
COPY ./deploy/caulobrowser_*.tar.gz /app.tar.gz
RUN R -e 'remotes::install_local("/app.tar.gz",upgrade="never")'
RUN rm /app.tar.gz
EXPOSE 3838
ENV CAULOBROWSER_DB_PATH=/database/caulobrowser.duckdb
RUN mkdir /database
CMD ["R", "-e", "options('shiny.port'=3838,shiny.host='0.0.0.0');library(caulobrowser);caulobrowser::run_app()"]
