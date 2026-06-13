# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Run the app

```r
# Development (hot reload)
golem::run_dev()

# Production
caulobrowser::run_app()
```

### Connect to demo database

```r
con <- DBI::dbConnect(
    duckdb::duckdb(),
    system.file("extdata", "caulobrowser.duckdb", package = "caulobrowser")
  )
```

### Test

```r
devtools::test()                                                        # all tests
testthat::test_file("tests/testthat/test-fct_database.R")              # single file
```

### Check / lint

```r
devtools::check()      # full R CMD check (run before deploying)
```

### Dependency management

```r
attachment::att_amend_desc()   # sync DESCRIPTION with actual imports
usethis::use_package("pkg")    # add a new dependency
golem::document_and_reload()   # rebuild docs + reload
```

## Architecture

CauloBrowser is a **golem-based R package** that exposes a single Shiny app via `run_app()`. The golem framework wraps the app as an R package, so standard R package tooling (`devtools`, `testthat`) applies throughout.

### Data layer

All data lives in a **DuckDB** embedded database opened in read-only mode per session. The database path is configured via the `CAULOBROWSER_DB_PATH` environment variable (set in `dev/run_dev.R`). 

Read the database schema from [here](DATABASE_SCHEMA.md).

### UI / server

`R/app_ui.R` defines a three-tab bslib navbar (Gene Browser, About, Download). `R/app_server.R` manages the DuckDB connection lifecycle and calls module servers. All UI is composed from Shiny modules.

### Shiny modules

| File                       | Module                 | Role                                                |
| -------------------------- | ---------------------- | --------------------------------------------------- |
| `R/mod_gene_search.R`    | `mod_gene_search`    | Text input → reactive gene records                 |
| `R/mod_overview_table.R` | `mod_overview_table` | Reactable gene summary table with external DB links |
| `R/mod_expression.R`     | `mod_expression`     | Expression plots (ggiraph), strain selector         |
| `R/mod_de_heatmap.R`     | `mod_de_heatmap`     | Comparison heatmaps (ggiraph), data_type selector   |
| `R/mod_gene_viewer.R`     | `mod_gene_viewer`     | Jbrowse-based IGV-like gene viewer   |

### Plotting

`R/fct_plots.R` contains:

- `plot_expression_timecourse()` — multi-gene interactive ggplot2 line chart using ggiraph
- `plot_single_expression()` — single-experiment variant
- `render_cell_schematic()` — custom SVG of Caulobacter cell with protein positions
- `plot_de_heatmap()` - plots heatmaps from log2foldchange results and facets on data_type

### Configuration

`inst/golem-config.yml` is read by `get_golem_config()` from `R/app_config.R`. The `default` block sets the database path; environment-specific overrides (`production`, etc.) can be added there.
