#' The Application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  shiny::tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),

    bslib::page_navbar(
      title = shiny::span(
        shiny::strong("CauloBrowser"),
        style = "font-size: 1.3em;"
      ),
      window_title = "CauloBrowser",
      theme = bslib::bs_theme(
        version = 5,
        bootswatch = "flatly",
        primary = "#2c3e50",
        "navbar-bg" = "#2c3e50",
        "accordion-button-bg" = "#2c3e50",
        "accordion-button-color" = "#ffffff",
        "accordion-button-active-bg" = "#2c3e50",
        "accordion-button-active-color" = "#ffffff",
        "accordion-icon-color" = "#ffffff",
        "accordion-icon-active-color" = "#ffffff"
      ),

      # ── Main search & results tab ──────────────────────────
      bslib::nav_panel(
        title = "Gene Browser",
        icon = shiny::icon("dna"),

        shiny::div(
          class = "container-fluid",
          style = "max-width: 1400px; margin: 0 auto; padding-top: 20px;",

          # Header
          shiny::div(
            class = "text-center mb-4",
            shiny::h2("CauloBrowser"),
            shiny::p(
              class = "lead text-muted",
              "A systems biology resource for ",
              shiny::em("Caulobacter crescentus")
            )
          ),

          # Gene search module
          shiny::wellPanel(
            mod_gene_search_ui("gene_search")
          ),

          # Results: shown only after search
          shiny::conditionalPanel(
            condition = "output.has_results",
            ns = shiny::NS(NULL),

            # Section 1: Overview table (Figure 1)
            bslib::accordion(
              bslib::accordion_panel(
                title = "Gene Overview",
                mod_overview_table_ui("overview_table")
              ),
              open = TRUE
            ),

            # Section 2: Expression & Localization (Figure 2)
            bslib::accordion(
              bslib::accordion_panel(
                title = "Expression & Localization",
                mod_expression_ui("expression")
              ),
              open = FALSE
            ),

            # Section 3: Expression Browser
            bslib::accordion(
              bslib::accordion_panel(
                title = "Expression Browser",
                mod_de_heatmap_ui("expression_heatmap")
              ),
              open = FALSE
            ),

            # Section 4: Fitness Browser
            bslib::accordion(
              bslib::accordion_panel(
                title = "Fitness Browser",
                mod_de_heatmap_ui("fitness_heatmap")
              ),
              open = FALSE
            )
          )
        )
      ),

      # ──Gene Viewer tab --───────────────────────────────────
      bslib::nav_panel(
        title = "Gene Viewer",
        mod_gene_viewer_ui("gene_viewer")
      ),

      # ── About / Help tab ───────────────────────────────────
      bslib::nav_panel(
        title = "About",
        icon = shiny::icon("circle-info"),

        shiny::div(
          class = "container",
          style = "max-width: 800px; margin-top: 30px;",

          shiny::h2("About CauloBrowser"),
          shiny::p(
            shiny::em("Caulobacter crescentus"),
            "is a premier model organism for studying the molecular basis",
            "of cellular asymmetry. CauloBrowser integrates diverse",
            "high-throughput experimental datasets into a single searchable",
            "resource."
          ),

          shiny::h4("Integrated Data Types"),
          shiny::tags$ul(
            shiny::tags$li("Gene expression profiling (microarray, RNA-seq)"),
            shiny::tags$li("Ribosome profiling (translation efficiency)"),
            shiny::tags$li("LC-MS proteomics"),
            shiny::tags$li("ChIP-seq (transcription factor binding)"),
            shiny::tags$li("Tn-seq (gene essentiality)"),
            shiny::tags$li("Protein subcellular localization"),
            shiny::tags$li("Chromosome methylation (SMRT sequencing)")
          ),

          shiny::h4("References"),
          shiny::p(
            "Lasker, K., Schrader, J.M., Men, Y., Marshik, T., Dill, D.L.,",
            "McAdams, H.H., & Shapiro, L. (2016). CauloBrowser: A systems",
            "biology resource for Caulobacter crescentus.",
            shiny::em("Nucleic Acids Research, 44"),
            "(D1), D640-D645.",
            shiny::a(
              "DOI: 10.1093/nar/gkv1050",
              href = "https://doi.org/10.1093/nar/gkv1050",
              target = "_blank"
            )
          ),

          shiny::h4("Technology"),
          shiny::p(
            "Built with R Shiny (golem framework), DuckDB, ggiraph, and reactable."
          )
        )
      ),

      # ── Download tab ────────────────────────────────────────
      bslib::nav_panel(
        title = "Download",
        icon = shiny::icon("download"),

        shiny::div(
          class = "container",
          style = "max-width: 800px; margin-top: 30px;",

          shiny::h2("Download Data"),
          shiny::p(
            "Download genome-wide datasets in CSV format."
          ),
          shiny::p(
            class = "text-muted",
            "(Download functionality will be implemented in a future version.)"
          )
        )
      )
    )
  )
}


#' Add external resources to the application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  golem::add_resource_path(
    "www",
    app_sys("app/www")
  )

  shiny::tags$head(
    golem::favicon(),
    golem::bundle_resources(
      path = app_sys("app/www"),
      app_title = "CauloBrowser"
    ),
    # Custom CSS
    shiny::tags$style(shiny::HTML(
      "
      .well {
        background-color: #ffffff;
        border: 1px solid #dee2e6;
        border-radius: 8px;
        padding: 20px;
      }
      .card {
        margin-bottom: 20px;
        border-radius: 8px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.1);
      }
      .rt-table {
        font-size: 0.9em;
      }
      a {
        color: #3498db;
      }
    "
    ))
  )
}
