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
#'
#' `$server(data_source = )` only registers a single table per session, so
#' the tables are registered here up front on a dedicated read-only
#' connection that lives for the life of the process (querychat never
#' disconnects a caller-supplied connection).
#' @noRd
make_caulochat_qc <- function() {
  if (is.null(.qc_cache$qc)) {
    .qc_cache$con <- get_db_connection()
    qc <- querychat::QueryChat$new(
      .qc_cache$con,
      caulochat_tables[[1]],
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
    qc$add_tables(.qc_cache$con, caulochat_tables[-1])
    .qc_cache$qc <- qc
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
    shiny::tags$style(
      "
      .caulochat-bs-tt .tooltip-inner {
        font-size: 0.9rem;
        max-width: 450px;
        text-align: left;
        white-space: pre-wrap;
        word-break: break-word;
        line-height: 1.45;
      }
    "
    ),
    shiny::tags$script(shiny::HTML(
      "
      (function () {
        function debounce(fn, ms) {
          var t;
          return function () { clearTimeout(t); t = setTimeout(fn, ms); };
        }
        function initTooltips() {
          if (typeof bootstrap === 'undefined') return;
          document.querySelectorAll('[data-bs-toggle=\"tooltip\"]:not(.tt-ready)').forEach(function (el) {
            el.classList.add('tt-ready');
            new bootstrap.Tooltip(el, {
              trigger: 'hover',
              boundary: 'window',
              customClass: 'caulochat-bs-tt',
              title: function () {
                return this.scrollWidth > this.clientWidth
                  ? this.getAttribute('data-bs-title')
                  : '';
              }
            });
          });
        }
        new MutationObserver(debounce(initTooltips, 150))
          .observe(document.documentElement, { childList: true, subtree: true });
      })();
    "
    )),
    sidebar = qc$sidebar(
      shiny::downloadButton(
        ns("download_transcript"),
        label = "Download chat",
        icon = shiny::icon("download"),
        class = "btn-sm btn-outline-secondary w-100 mb-2"
      ),
      width = 600,
      id = ns(qc$id)
    ),
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
mod_caulochat_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    qc_vals <- make_caulochat_qc()$server()

    # Multi-table: show whichever table the chat last filtered
    # (genes until the first filter).
    current_table <- shiny::reactive({
      qc_vals$table(qc_vals$current_table() %||% caulochat_tables[[1]])
    })

    output$dt <- reactable::renderReactable(
      reactable::reactable(
        current_table()$df(),
        searchable = TRUE,
        striped = TRUE,
        highlight = TRUE,
        compact = TRUE,
        defaultColDef = reactable::colDef(
          maxWidth = 400,
          html = TRUE,
          cell = reactable::JS(
            "function(cellInfo) {
              var val = cellInfo.value == null ? '' : String(cellInfo.value);
              var esc = val.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/\"/g, '&quot;');
              return '<span data-bs-toggle=\"tooltip\" data-bs-title=\"' + esc + '\" ' +
                'style=\"display:block;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;cursor:default;\">' +
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
