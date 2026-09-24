# Package-level cache: populated on first runtime call, never at load time.
.qc_cache <- new.env(parent = emptyenv())

#' Raw greeting content shown at chat startup.
#' @noRd
caulochat_greeting_html <- function() {
  readLines(
    system.file("prompts", "greeting.md", package = "caulobrowser"),
    warn = FALSE
  ) |>
    paste(collapse = "\n")
}

#' Tables exposed to the chat; must match the keys under `tables:` in
#' `inst/prompts/data-dict.yaml`.
#' @noRd
caulochat_tables <- c(
  "genes",
  "experiments",
  "experiment_conditions",
  "de_results",
  "timecourse_expression"
)

#' Return the process-level QueryChat singleton, creating it on first call.
#' @noRd
make_caulochat_qc <- function() {
  if (is.null(.qc_cache$qc)) {
    qc <- querychat::QueryChat$new(
      NULL,
      client = ellmer::chat_openai_compatible(
        model = "qwen3-8-27b",
        base_url = "https://litellm.harmonyhpc.io/v1"
      ),
      data_dict = system.file(
        "prompts",
        "data-dict.yaml",
        package = "caulobrowser"
      ),
      extra_instructions = "Always update the dashboard with the relevant information.",
      greeting = caulochat_greeting_html(),
      tools = c("filter", "query", "visualize"),
      cleanup = FALSE
    )
    .qc_cache$qc <- qc
  }
  .qc_cache$qc
}

#' Register the chat tables on a dedicated read-only connection, once per
#' process. Called before the first `$server()`, so querychat treats it as
#' initial configuration. Errors if the database is unavailable.
#' @noRd
caulochat_register_tables <- function(qc) {
  if (length(qc$table_names()) == 0) {
    .qc_cache$con <- get_db_connection()
    qc$add_tables(.qc_cache$con, caulochat_tables)
  }
  invisible(qc)
}

#' caulochat UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_caulochat_ui <- function(id) {
  ns <- NS(id)
  qc <- make_caulochat_qc()
  # Chat-first layout: the same pieces as querychat's
  tagList(qc$ui(
    id = ns(qc$id),
    drawer = shinychat::chat_drawer(
      bslib::card(
        full_screen = TRUE,
        bslib::card_header(
          shiny::textOutput(ns("results_title"), inline = TRUE)
        ),
        reactable::reactableOutput(ns("dt")),
        bslib::card_footer(shiny::verbatimTextOutput(ns("sql")))
      ),
      title = "Results",
      open = FALSE,
      width = "calc(min(clamp(360px, 55vw, 720px), 100%))"
    ),
    # Transcript export; /handoff (built in) exports the results instead.
    toolbar_input = bslib::toolbar(
      shiny::downloadButton(
        ns("download_transcript"),
        label = "Download chat",
        icon = shiny::icon("download"),
        class = "btn-sm btn-outline-secondary"
      )
    )
  ))
}

#' caulochat Server Functions
#'
#' @noRd
mod_caulochat_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    qc <- make_caulochat_qc()
    # Without a database there is nothing to chat about; app_server already
    # reports the database error to the user.
    registered <- tryCatch(
      {
        caulochat_register_tables(qc)
        TRUE
      },
      error = function(e) FALSE
    )
    if (!registered) {
      return(invisible(NULL))
    }
    qc_vals <- qc$server()

    # Multi-table: show whichever table the chat last filtered
    # (genes until the first filter).
    current_table_name <- shiny::reactive({
      qc_vals$current_table() %||% caulochat_tables[[1]]
    })
    current_table <- shiny::reactive(qc_vals$table(current_table_name()))

    # Open the results drawer whenever the chat filters a table.
    shiny::observe({
      if (shiny::isTruthy(current_table()$sql())) {
        shinychat::chat_drawer_show(paste0(qc$id, "-chat"))
      }
    })

    output$results_title <- shiny::renderText({
      current_table()$title() %||% current_table_name()
    })

    output$dt <- reactable::renderReactable(
      reactable::reactable(
        current_table()$df(),
        searchable = TRUE,
        striped = TRUE,
        highlight = TRUE,
        compact = TRUE,
        # Truncate long cells; the full value shows on hover via `title`.
        defaultColDef = reactable::colDef(
          maxWidth = 400,
          html = TRUE,
          cell = reactable::JS(
            "function(cellInfo) {
              var val = cellInfo.value == null ? '' : String(cellInfo.value);
              var esc = val.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/\"/g, '&quot;');
              return '<span title=\"' + esc + '\" ' +
                'style=\"display:block;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;\">' +
                esc + '</span>';
            }"
          )
        ),
        theme = reactable::reactableTheme(
          style = list(fontSize = "0.85rem")
        )
      )
    )
    output$sql <- shiny::renderText(current_table()$sql() %||% "")

    output$download_transcript <- shiny::downloadHandler(
      filename = function() {
        chat_export_filename(title = current_table()$title())
      },
      content = function(file) {
        turns <- if (!is.null(qc_vals$client)) {
          qc_vals$client$get_turns()
        } else {
          list()
        }
        transcript <- format_chat_transcript(
          turns = turns,
          greeting = caulochat_greeting_html(),
          title = current_table()$title()
        )
        writeLines(transcript, file, useBytes = TRUE)
      }
    )
  })
}
