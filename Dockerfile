FROM baldikacti/caulobrowser_base:latest
COPY renv.lock renv.lock
RUN R -e 'options(renv.config.pak.enabled = FALSE);renv::restore()'
COPY ./deploy/caulobrowser_*.tar.gz /app.tar.gz
RUN R -e 'remotes::install_local("/app.tar.gz",upgrade="never")'
RUN rm /app.tar.gz
EXPOSE 3838
ENV CAULOBROWSER_DB_PATH=/database/caulobrowser.duckdb
RUN mkdir /database
CMD ["R", "-e", "options('shiny.port'=3838,shiny.host='0.0.0.0');library(caulobrowser);caulobrowser::run_app()"]
