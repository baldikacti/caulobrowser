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

### One-time setup (generate demo database)
```r
caulobrowser::generate_example_database(path = ".")
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

All data lives in a **DuckDB** embedded database opened in read-only mode per session. The database path is configured via the `CAULOBROWSER_DB_PATH` environment variable (set in `dev/run_dev.R`). Schema (five tables):

- `genes` — `gene_id` (VARCHAR PK, CCNA_XXXXX NA1000 locus tag), `cc_tag` (CC_XXXX CB15 legacy tag), `gene_name`, `ncbi_protein_id`, `gene_biotype`, `description`

- `experiments` — `experiment_id` (VARCHAR PK), `display_label`, `experiment_class`, `data_type`, `strain`, `genetic_background`, `treatment`, `treatment_level`, `growth_phase`, `media`, `ref_strain`, `ref_treatment`, `ref_treatment_level`, `ref_growth_phase`, `ref_media`, `lab_group`, `doi`, `geo_id`, `date_added`

- `experiment_conditions` — (`experiment_id`, `condition_label`) composite PK; `condition_order` (INTEGER), `condition_value` (DOUBLE), `condition_units`, `display_label`. FK → `experiments`

- `de_results` — (`gene_id`, `experiment_id`) composite PK; `log2fc` (DOUBLE NOT NULL), `padj` (DOUBLE). FK → `genes` + `experiments`

- `timecourse_expression` — (`gene_id`, `experiment_id`, `condition_label`) composite PK; `expression_value` (DOUBLE NOT NULL). FK → `genes`, `experiments`, and `experiment_conditions(experiment_id, condition_label)`

Indexes on: `de_results(experiment_id)`, `de_results(gene_id)`, `timecourse_expression(gene_id)`, `timecourse_expression(experiment_id)`, `timecourse_expression(gene_id, experiment_id)`, `experiments(experiment_class)`, `experiments(data_type)`, `experiments(lab_group)`

### UI / server

`R/app_ui.R` defines a three-tab bslib navbar (Gene Browser, About, Download). `R/app_server.R` manages the DuckDB connection lifecycle and calls module servers. All UI is composed from Shiny modules.

### Shiny modules

| File | Module | Role |
|------|--------|------|
| `R/mod_gene_search.R` | `mod_gene_search` | Text input → reactive gene records |
| `R/mod_overview_table.R` | `mod_overview_table` | Reactable gene summary table with external DB links |
| `R/mod_expression.R` | `mod_expression` | Expression plots (ggiraph), strain selector |
| `R/mod_de_heatmap.R` | `mod_de_heatmap` | Comparison heatmaps (ggiraph), data_type selector |

### Plotting

`R/fct_plots.R` contains:
- `plot_expression_timecourse()` — multi-gene interactive ggplot2 line chart using ggiraph
- `plot_single_expression()` — single-experiment variant
- `render_cell_schematic()` — custom SVG of Caulobacter cell with protein positions
- `plot_de_heatmap()` - plots heatmaps from log2foldchange results and facets on data_type

### Configuration

`inst/golem-config.yml` is read by `get_golem_config()` from `R/app_config.R`. The `default` block sets the database path; environment-specific overrides (`production`, etc.) can be added there.

### Deployment

`dev/03_deploy.R` has helpers for shinyapps.io (`rsconnect::deployApp()`), Posit Connect, and Docker. Always run `devtools::check()` first.
