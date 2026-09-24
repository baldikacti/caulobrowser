ARG BASE_IMAGE=ghcr.io/baldikacti/caulobrowser-base:latest
FROM $BASE_IMAGE
COPY renv.lock renv.lock
RUN R -e 'options(renv.config.pak.enabled = FALSE);renv::restore()'
COPY ./deploy/caulobrowser_*.tar.gz /app.tar.gz
RUN R CMD INSTALL /app.tar.gz && rm /app.tar.gz
EXPOSE 3838
ENV CAULOBROWSER_DB_PATH=/database/caulobrowser.duckdb
RUN mkdir /database
CMD ["R", "-e", "options('shiny.port'=3838,shiny.host='0.0.0.0');library(caulobrowser);caulobrowser::run_app()"]
