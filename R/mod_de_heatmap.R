#' Differential Expression Heatmap Module (Section 3)
#'
#' @description A shiny module for displaying log2 fold-change values as an
#'   interactive heatmap across DE comparison experiments.
#'   X-axis = experiments (display_label), Y-axis = selected genes.
#'   Color: diverging blue-white-red scale centered at log2FC = 0.
#'   A dropdown filters experiments by data_type.
#'
#' @param id Internal parameter for {shiny} module namespacing.
#' @param gene_results Reactive data frame of selected genes from
#'   `mod_gene_search_server()`.
#' @param db_con Reactive DBI connection from `app_server`.
#'
#' @name mod_de_heatmap
#' @noRd

mod_de_heatmap_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::tagList(
    shiny::p(
      class = "text-muted",
      "Log\u00b2 fold-change values from comparison experiments.",
      "Blue\u00a0=\u00a0down-regulated, red\u00a0=\u00a0up-regulated relative to the reference."
    ),
    shiny::div(
      class = "row align-items-start",
      shiny::div(
        class = "col-12 col-lg-8",
        ggiraph::girafeOutput(ns("de_heatmap"))
      ),
      shiny::div(
        class = "col-12 col-lg-4",
        style = "padding-top: 8px;",
        shiny::uiOutput(ns("experiment_panel"))
      )
    )
  )
}

mod_de_heatmap_server <- function(id, gene_results, dtype_filter, db_con) {
  shiny::moduleServer(id, function(input, output, session) {
    # ── Fetch DE data, reacts to gene selection + data_type filter ─────────
    de_data <- shiny::reactive({
      genes <- gene_results()
      shiny::req(nrow(genes) > 0)

      get_de_results_for_heatmap(
        db_con(),
        gene_ids = genes$gene_id,
        data_type = dtype_filter
      )
    })

    # ── Dynamic height: 40 px per experiment row in the tallest facet ────────
    plot_height_px <- shiny::reactive({
      df <- de_data()
      if (is.null(df) || nrow(df) == 0) {
        return(200L)
      }
      max_experiments <- max(
        tapply(df$display_label, df$data_type, function(x) length(unique(x)))
      )
      max(200L, max_experiments * 28L)
    })

    # ── Experiment details panel (click to show) ───────────────────────────
    output$experiment_panel <- shiny::renderUI({
      selected_id <- input$de_heatmap_selected

      if (is.null(selected_id) || !nzchar(selected_id)) {
        return(bslib::card(
          bslib::card_body(
            shiny::p(
              class = "text-muted",
              style = "font-size: 0.85em;",
              "Click a row to see experiment details."
            )
          )
        ))
      }

      df <- de_data()
      row <- df[df$experiment_id == selected_id, ][1, ]

      doi_val <- row$doi
      doi_cell <- if (is_present(doi_val)) {
        shiny::tags$a(
          href = paste0("https://doi.org/", doi_val),
          target = "_blank",
          doi_val
        )
      } else {
        shiny::span("\u2014")
      }

      bslib::card(
        style = "font-size: 0.85em;",
        bslib::card_header("Experiment details"),
        bslib::card_body(
          shiny::tags$table(
            class = "table table-sm table-borderless mb-0",
            shiny::tags$tbody(
              make_row("Experiment:", na_or(row$display_label)),
              make_row("Data type:", na_or(row$data_type)),
              make_row("Strain:", na_or(row$strain)),
              make_row("Genetic Background:", na_or(row$genetic_background)),
              make_row("Treatment:", na_or(row$treatment)),
              make_row("Treatment level:", na_or(row$treatment_level)),
              make_row("Media:", na_or(row$media)),
              make_row("Growth phase:", na_or(row$growth_phase)),
              make_row("Reference Background:", na_or(row$ref_strain)),
              make_row("Reference Treatment:", na_or(row$ref_treatment)),
              make_row(
                "Reference Treatment level:",
                na_or(row$ref_treatment_level)
              ),
              make_row("Reference Media:", na_or(row$ref_media)),
              make_row("Reference Growth phase:", na_or(row$ref_growth_phase)),
              make_row("Lab group:", na_or(row$lab_group)),
              make_row("DOI:", doi_cell)
            )
          )
        )
      )
    })

    # ── Render heatmap ─────────────────────────────────────────────────────
    output$de_heatmap <- ggiraph::renderGirafe({
      df <- de_data()

      if (is.null(df) || nrow(df) == 0) {
        empty_plot <- ggplot2::ggplot() +
          ggplot2::annotate(
            "text",
            x = 0.5,
            y = 0.5,
            label = paste0(
              "No comparison data available\n",
              "for the selected genes and data type."
            ),
            hjust = 0.5,
            vjust = 0.5,
            size = 4,
            color = "#888888"
          ) +
          ggplot2::theme_void()
        return(ggiraph::girafe(ggobj = empty_plot))
      }

      plot_de_heatmap(df, height_px = plot_height_px())
    })
  })
}
