# No database ships with the package, so database-backed tests run against
# whatever CAULOBROWSER_DB_PATH points to and are skipped when it is unset or
# points at a missing file (e.g. on CI).
test_db_path <- function() {
  path <- Sys.getenv("CAULOBROWSER_DB_PATH")
  testthat::skip_if(
    !nzchar(path) || !file.exists(path),
    "CAULOBROWSER_DB_PATH is not set to an existing DuckDB file"
  )
  path
}
