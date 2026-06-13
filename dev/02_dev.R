# Development Workflow
# ==================================================
# Run these lines during development as needed.

# ── Dependencies ──────────────────────────────────
# Add package dependencies (these update DESCRIPTION automatically)
attachment::att_amend_desc(
  extra.suggests = c(
    "knitr",
    "devtools",
    "roxygen2",
    "usethis",
    "pkgdown",
    "covr"
  ),
  update.config = TRUE
)

usethis::use_package("shiny")
usethis::use_package("golem")
usethis::use_package("bslib")
usethis::use_package("config")
usethis::use_package("DT")
usethis::use_package("duckdb")
usethis::use_package("DBI")
usethis::use_package("ggplot2")
usethis::use_package("glue")
usethis::use_package("htmltools")
usethis::use_package("ggirafe")
usethis::use_package("reactable")
usethis::use_package("shinyWidgets")
usethis::use_package("tidyr")
usethis::use_package("JBrowseR")

# ── Add Modules ───────────────────────────────────
# These were already created manually, but for new modules use:
golem::add_module(name = "gene_viewer", with_test = TRUE)
#
# Existing modules:
#   mod_gene_search    - Search bar and gene lookup
#   mod_overview_table - Figure 1: Gene overview table
#   mod_expression     - Figure 2: Expression profiles & localization

# ── Add helper function files ─────────────────────
golem::add_fct("helpers")
golem::add_utils("helpers")
#
# Existing fct_ files:
#   fct_database.R - DuckDB connection and query functions
#   fct_plots.R    - Plotting helper functions

# ── Documentation ─────────────────────────────────
# Build documentation and reload
usethis::use_vignette("shinyexample")
devtools::build_vignettes()
usethis::use_coverage()

# ── Run the app ───────────────────────────────────
golem::run_dev()
