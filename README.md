
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Caulobrowser <img src="inst/app/www/favicon.ico" align="right" height="50"/>

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**CauloBrowser** is an interactive Shiny application for browsing and
visualizing curated high-throughput experimental data for *Caulobacter
crescentus*. It reimplements and extends the original
[CauloBrowser](https://doi.org/10.1093/nar/gkv1050) web resource using
modern R tooling.

## Features

| Feature                                 | CauloBrowser Section | Status     |
|-----------------------------------------|----------------------|------------|
| Gene search (name, locus tag, CC tag)   | Start page           | ✅         |
| Gene overview table with external links | Section 1            | ✅         |
| Time-resolved expression profiles       | Section 2            | ✅         |
| Differential expression heatmap         | Section 3            | ✅         |
| Genome browser (multi-track viewer)     | Section 4            | 🔜 Planned |
| Data download (CSV)                     | Download page        | 🔜 Planned |

## Installation

``` r
# Install from GitHub
remotes::install_github("baldikacti/caulobrowser")
```

## Quick Start

### 1. Generate a demo database

``` r
caulobrowser::generate_example_database(path = ".")
```

This creates a `caulobrowser.duckdb` file with demo data for 5 genes
(ctrA, ftsZ, popZ, dnaA, ccrM) including expression time-courses and
differential expression results.

### 2. Run the app

``` r
# Set the `CAULOBROWSER_DB_PATH` to where your database is
Sys.setenv(
  "CAULOBROWSER_DB_PATH" = "/path/to/caulobrowser.duckdb"
)
caulobrowser::run_app()
# Or during development:
golem::run_dev()
```

### 3. Try searching for: `ctrA, ftsZ, popZ`

## Project Structure

    caulobrowser/
    ├── DESCRIPTION              # Package metadata & dependencies
    ├── NAMESPACE
    ├── R/
    │   ├── app_config.R         # golem config access
    │   ├── app_server.R         # Main server function
    │   ├── app_ui.R             # Main UI function (bslib page_navbar)
    │   ├── run_app.R            # Entry point
    │   ├── fct_database.R       # DuckDB connection & query functions
    │   ├── fct_plots.R          # Plotting helpers (ggiraph, SVG schematics)
    │   ├── generate_example_database.R  # Demo database generator
    │   ├── mod_gene_search.R    # Module: gene search bar
    │   ├── mod_overview_table.R # Module: Figure 1 overview table
    │   ├── mod_expression.R     # Module: Figure 2 expression & localization
    │   └── mod_de_heatmap.R     # Module: Section 3 DE heatmap
    ├── dev/
    │   ├── 01_start.R           # Initial project setup
    │   ├── 02_dev.R             # Development workflow
    │   ├── 03_deploy.R          # Deployment helpers
    │   └── run_dev.R            # Quick launch
    ├── inst/
    │   ├── app/www/             # Static assets (CSS, favicon)
    │   ├── extdata/             # DuckDB database file
    │   └── golem-config.yml     # App configuration
    ├── tests/
    │   └── testthat/            # Unit tests
    └── app.R                    # Deployment entry point

## Database Schema

The app reads from a DuckDB database with five tables:

- `genes` — `gene_id` (VARCHAR PK, CCNA_XXXXX NA1000 locus tag),
  `cc_tag` (CC_XXXX CB15 legacy tag), `gene_name`, `ncbi_protein_id`,
  `gene_biotype`, `description`

- `experiments` — `experiment_id` (VARCHAR PK), `display_label`,
  `experiment_class`, `data_type`, `strain`, `genetic_background`,
  `treatment`, `treatment_level`, `growth_phase`, `media`, `ref_strain`,
  `ref_treatment`, `ref_treatment_level`, `ref_growth_phase`,
  `ref_media`, `lab_group`, `doi`, `geo_id`, `date_added`

- `experiment_conditions` — (`experiment_id`, `condition_label`)
  composite PK; `condition_order` (INTEGER), `condition_value` (DOUBLE),
  `condition_units`, `display_label`. FK → `experiments`

- `de_results` — (`gene_id`, `experiment_id`) composite PK; `log2fc`
  (DOUBLE NOT NULL), `padj` (DOUBLE). FK → `genes` + `experiments`

- `timecourse_expression` — (`gene_id`, `experiment_id`,
  `condition_label`) composite PK; `expression_value` (DOUBLE NOT NULL).
  FK → `genes`, `experiments`, and
  `experiment_conditions(experiment_id, condition_label)`

Indexes on: `de_results(experiment_id)`, `de_results(gene_id)`,
`timecourse_expression(gene_id)`,
`timecourse_expression(experiment_id)`,
`timecourse_expression(gene_id, experiment_id)`,
`experiments(experiment_class)`, `experiments(data_type)`,
`experiments(lab_group)`

## References

Lasker, K., Schrader, J.M., Men, Y., Marshik, T., Dill, D.L., McAdams,
H.H., & Shapiro, L. (2016). CauloBrowser: A systems biology resource for
*Caulobacter crescentus*. *Nucleic Acids Research, 44*(D1), D640–D645.
<https://doi.org/10.1093/nar/gkv1050>

## License

MIT

## Code of Conduct

Please note that the caulobrowser project is released with a
[Contributor Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
