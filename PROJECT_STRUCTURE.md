# Project Structure

```
caulobrowser/
├── DESCRIPTION              # Package metadata & dependencies (Updated automatically)
├── NAMESPACE		     # Updated automatically
├── R/
│   ├── app_config.R         # golem config access
│   ├── app_server.R         # Main server function
│   ├── app_ui.R             # Main UI function (bslib page_navbar)
│   ├── run_app.R            # Entry point
│   ├── fct_database.R       # DuckDB connection & query functions
│   ├── fct_plots.R          # Plotting helpers (ggiraph, SVG schematics)
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
│   └── golem-config.yml     # App configuration (db path from CAULOBROWSER_DB_PATH)
├── tests/
│   └── testthat/            # Unit tests
└── app.R                    # Deployment entry point
```
