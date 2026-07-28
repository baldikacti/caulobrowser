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

#' Return the process-level QueryChat singleton, creating it on first call.
#' @noRd
make_caulochat_qc <- function() {
  if (is.null(.qc_cache$qc)) {
    .qc_cache$qc <- querychat::QueryChat$new(
      NULL,
      "genes",
      client = ellmer::chat_anthropic(
        model = "claude-sonnet-4-6",
        base_url = "https://thekeymaker.umass.edu/v1"
      ),
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
      greeting = caulochat_greeting_html(),
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
mod_caulochat_server <- function(id, db_con) {
  moduleServer(id, function(input, output, session) {
    qc_state <- shiny::reactiveVal(NULL)

    shiny::observeEvent(
      db_con(),
      {
        qc_vals <- .qc_cache$qc$server(data_source = db_con())
        qc_state(qc_vals)
        output$dt <- reactable::renderReactable(
          reactable::reactable(
            qc_vals$df(),
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
        output$sql <- shiny::renderText(qc_vals$sql() %||% "")
      },
      ignoreNULL = TRUE,
      once = TRUE
    )

    output$download_transcript <- shiny::downloadHandler(
      filename = function() {
        qc_vals <- qc_state()
        chat_export_filename(
          title = if (!is.null(qc_vals)) qc_vals$title() %||% NULL else NULL
        )
      },
      content = function(file) {
        qc_vals <- qc_state()
        turns <- if (!is.null(qc_vals) && !is.null(qc_vals$client)) {
          qc_vals$client$get_turns()
        } else {
          list()
        }
        transcript <- format_chat_transcript(
          turns = turns,
          greeting = caulochat_greeting_html(),
          title = if (!is.null(qc_vals)) qc_vals$title() %||% NULL else NULL
        )
        writeLines(transcript, file, useBytes = TRUE)
      }
    )
  })
}
