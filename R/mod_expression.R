#' Expression Profile Module (Figure 2)
#'
#' @description A shiny module for displaying time-resolved gene expression
#'   data across the Caulobacter cell cycle. Reproduces CauloBrowser Figure 2:
#'   - Dropdown to select genetic background
#'   - Dynamic plots grouped by data type (RNA-seq, microarray, etc.)
#'   - DOI link next to each experiment's plot
#'
#' @param id Internal parameter for {shiny} module namespacing.
#'
#' @name mod_expression
#' @noRd

mod_expression_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::tagList(
    shiny::h3("Section 2: Time-Resolved Expression"),
    shiny::p(
      class = "text-muted",
      "Expression levels across the Caulobacter cell cycle from multiple",
      "experimental platforms. Select a genetic background to filter experiments."
    ),
    shiny::selectInput(
      ns("genetic_background"),
      label = "Genetic background",
      choices = NULL,
      width = "40%"
    ),
    shiny::uiOutput(ns("expr_plots"))
  )
}


mod_expression_server <- function(id, gene_results, db_con) {
  shiny::moduleServer(id, function(input, output, session) {
    # Color palette: consistent colors for each gene across all plots
    color_palette <- shiny::reactive({
      genes <- gene_results()
      shiny::req(nrow(genes) > 0)
      gene_names <- genes$gene_name
      colors <- c(
        "#E41A1C",
        "#377EB8",
        "#4DAF4A",
        "#984EA3",
        "#FF7F00",
        "#A65628",
        "#F781BF",
        "#999999"
      )
      setNames(colors[seq_along(gene_names)], gene_names)
    })

    # Populate genetic_background dropdown from DB
    shiny::observe({
      tryCatch(
        {
          backgrounds <- get_timecourse_backgrounds(db_con())
          if (length(backgrounds) > 0) {
            shiny::updateSelectInput(
              session,
              "genetic_background",
              choices = backgrounds
            )
          } else {
            shiny::updateSelectInput(
              session,
              "genetic_background",
              choices = c("No timecourse experiments available" = "")
            )
          }
        },
        error = function(e) {
          shiny::updateSelectInput(
            session,
            "genetic_background",
            choices = c("Error loading backgrounds" = "")
          )
        }
      )
    })

    # Fetch expression data filtered by selected genetic background
    expression_data <- shiny::reactive({
      genes <- gene_results()
      shiny::req(
        nrow(genes) > 0,
        input$genetic_background,
        nchar(input$genetic_background) > 0
      )
      get_expression_data(
        db_con(),
        genes$gene_id,
        genetic_background = input$genetic_background
      )
    })

    # Build unique experiment metadata table (one row per experiment)
    experiment_meta <- shiny::reactive({
      df <- expression_data()
      shiny::req(df, nrow(df) > 0)
      unique(df[, c(
        "experiment_id",
        "experiment_type",
        "display_label",
        "doi"
      )])
    })

    # Dynamic plot container: group by data_type, one card per experiment
    output$expr_plots <- shiny::renderUI({
      meta <- experiment_meta()
      shiny::req(meta, nrow(meta) > 0)

      ns <- session$ns

      # Order experiment_type groups sensibly
      type_order <- c(
        "microarray",
        "rnaseq",
        "ribosome_profiling",
        "proteomics"
      )
      data_types <- unique(meta$experiment_type)
      ordered_types <- c(
        intersect(type_order, data_types),
        setdiff(data_types, type_order)
      )

      type_labels <- c(
        microarray = "Microarray",
        rnaseq = "RNA-seq",
        ribosome_profiling = "Ribosome Profiling",
        proteomics = "Proteomics (LC-MS)"
      )

      groups <- lapply(ordered_types, function(dtype) {
        exps <- meta[meta$experiment_type == dtype, ]
        label <- unname(type_labels[dtype])
        if (is.na(label)) {
          label <- dtype
        }

        cards <- lapply(seq_len(nrow(exps)), function(i) {
          exp_id <- exps$experiment_id[i]
          exp_label <- exps$display_label[i]
          doi_val <- exps$doi[i]
          output_id <- paste0("plot_", exp_id)

          doi_link <- if (
            !is.null(doi_val) && !is.na(doi_val) && nzchar(doi_val)
          ) {
            shiny::tags$a(
              href = paste0("https://doi.org/", doi_val),
              target = "_blank",
              doi_val
            )
          } else {
            NULL
          }

          shiny::div(
            style = "margin-bottom: 24px;",
            shiny::div(
              style = "display: flex; align-items: baseline; gap: 12px; margin-bottom: 4px;",
              shiny::strong(exp_label),
              doi_link
            ),
            ggiraph::girafeOutput(ns(output_id), height = "300px")
          )
        })

        shiny::tagList(
          shiny::h4(label, style = "margin-top: 20px; margin-bottom: 8px;"),
          shiny::hr(style = "margin-top: 0;"),
          cards
        )
      })

      shiny::tagList(groups)
    })

    # Register renderPlotly for each experiment dynamically
    shiny::observe({
      df <- expression_data()
      shiny::req(df, nrow(df) > 0)
      meta <- experiment_meta()
      pal <- color_palette()

      lapply(seq_len(nrow(meta)), function(i) {
        local({
          exp_id <- meta$experiment_id[i]
          exp_label <- meta$display_label[i]
          output_id <- paste0("plot_", exp_id)

          output[[output_id]] <- ggiraph::renderGirafe({
            sub_df <- df[df$experiment_id == exp_id, ]
            plot_single_expression(
              sub_df,
              title = exp_label,
              color_palette = pal
            )
          })
          shiny::outputOptions(output, output_id, suspendWhenHidden = FALSE)
        })
      })
    })
  })
}
