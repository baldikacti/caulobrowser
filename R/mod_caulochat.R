# Package-level cache: populated on first runtime call, never at load time.
.qc_cache <- new.env(parent = emptyenv())

#' Return the process-level QueryChat singleton, creating it on first call.
#' @noRd
make_caulochat_qc <- function() {
  if (is.null(.qc_cache$qc)) {
    .qc_cache$qc <- querychat::QueryChat$new(
      NULL,
      "genes",
      client = ellmer::chat_anthropic(model = "claude-sonnet-4-6"),
      data_description = readLines(
        system.file("prompts", "data_description.md", package = "caulobrowser"),
        warn = FALSE
      ) |>
        paste(collapse = "\n"),
      prompt_template = readLines(
        system.file("prompts", "query.md", package = "caulobrowser"),
        warn = FALSE
      ) |>
        paste(collapse = "\n"),
      greeting = readLines(
        system.file("prompts", "greeting.md", package = "caulobrowser"),
        warn = FALSE
      ) |>
        paste(collapse = "\n"),
      tools = c("filter", "query", "visualize")
    )
  }
  .qc_cache$qc
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
  bslib::page_sidebar(
    title = "Caulo Chat",
    sidebar = qc$sidebar(width = 400, id = ns(qc$id)),
    bslib::card(
      full_screen = TRUE,
      bslib::card_header("Results"),
      reactable::reactableOutput(ns("dt"))
    ),
    bslib::card(
      fill = FALSE,
      max_height = "200px",
      bslib::card_header("SQL Query"),
      bslib::card_body(
        shiny::verbatimTextOutput(ns("sql"))
      )
    )
  )
}

#' caulochat Server Functions
#'
#' @noRd
mod_caulochat_server <- function(id, db_con) {
  moduleServer(id, function(input, output, session) {
    shiny::observeEvent(
      db_con(),
      {
        qc_vals <- .qc_cache$qc$server(data_source = db_con())
        output$dt <- reactable::renderReactable(
          reactable::reactable(
            qc_vals$df(),
            searchable = TRUE,
            striped = TRUE,
            highlight = TRUE,
            compact = TRUE,
            defaultColDef = reactable::colDef(
              maxWidth = 300,
              style = list(
                whiteSpace = "nowrap",
                overflow = "hidden",
                textOverflow = "ellipsis"
              ),
              html = TRUE,
              cell = reactable::JS(
                "function(cellInfo) {
                  var val = cellInfo.value == null ? '' : String(cellInfo.value);
                  return '<span title=\"' + val.replace(/\"/g, '&quot;') + '\">' + val + '</span>';
                }"
              )
            ),
            theme = reactable::reactableTheme(
              style = list(fontSize = "0.85rem")
            )
          )
        )
        output$sql <- shiny::renderText(qc_vals$sql() %||% "")
      },
      ignoreNULL = TRUE,
      once = TRUE
    )
  })
}
