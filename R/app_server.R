#' The Application Server-Side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {
  # ── Database connection (shared across modules) ──────────────
  # Wrapped in a reactive so modules can call db_con()
  db_con <- shiny::reactiveVal()

  shiny::observe({
    tryCatch(
      {
        con <- get_db_connection()
        db_con(con)
      },
      error = function(e) {
        shiny::showNotification(
          shiny::tagList(
            shiny::strong("Database Error"),
            shiny::br(),
            e$message
          ),
          type = "error",
          duration = NULL # persistent until dismissed
        )
      }
    )
  })

  # Clean up on session end

  session$onSessionEnded(function() {
    con <- shiny::isolate(db_con())
    if (!is.null(con)) {
      tryCatch(
        close_db_connection(con),
        error = function(e) message("DB disconnect error: ", e$message)
      )
    }
  })

  # ── Module: Gene Search ──────────────────────────────────────
  gene_results <- mod_gene_search_server("gene_search", db_con)

  # ── Conditional panel flag ───────────────────────────────────
  output$has_results <- shiny::reactive({
    res <- tryCatch(gene_results(), error = function(e) NULL)
    !is.null(res) && nrow(res) > 0
  })
  shiny::outputOptions(output, "has_results", suspendWhenHidden = FALSE)

  # ── Module: Overview Table (Section 1) ────────────────────────
  mod_overview_table_server("overview_table", gene_results, db_con)

  # ── Module: Expression Profiles (Section 2) ───────────────────
  mod_expression_server("expression", gene_results, db_con)

  # ── Module: Expression Browser (Section 3) ───---------------──
  mod_de_heatmap_server("expression_heatmap", gene_results, c("rnaseq"), db_con)

  # ── Module: Fitness Browser (Section 4) ──────-----------------
  mod_de_heatmap_server("fitness_heatmap", gene_results, c("tnseq"), db_con)

  # ── Module: Gene Viewer ----------------──────-----------------
  mod_gene_viewer_server("gene_viewer")
}
