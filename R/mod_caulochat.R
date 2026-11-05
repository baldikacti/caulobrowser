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
#' The LLM client comes from [caulochat_llm_config()]. Returns NULL when no
#' provider is configured or the client cannot be built; the reason is kept in
#' `.qc_cache$status$reason`. Success and "not configured" are cached for the
#' process; a build error (e.g. Ollama not running yet) is retried on the next
#' call.
#' @noRd
make_caulochat_qc <- function() {
  if (is.null(.qc_cache$status) || isTRUE(.qc_cache$status$retry)) {
    status <- tryCatch(
      {
        cfg <- caulochat_llm_config()
        client <- caulochat_build_client(cfg)
        if (is.null(client)) {
          list(
            enabled = FALSE,
            reason = "No LLM provider is configured."
          )
        } else {
          .qc_cache$qc <- querychat::QueryChat$new(
            NULL,
            client = client,
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
          .qc_cache$model_info <- caulochat_model_info(client)
          message("CauloChat: using ", caulochat_describe(cfg))
          list(enabled = TRUE, reason = NULL)
        }
      },
      error = function(e) {
        list(enabled = FALSE, reason = conditionMessage(e), retry = TRUE)
      }
    )
    if (!status$enabled) {
      message("CauloChat disabled: ", status$reason)
    }
    .qc_cache$status <- status
  }
  .qc_cache$qc
}

#' Clear the cached QueryChat, its status and its connection (for tests).
#' @noRd
caulochat_reset <- function() {
  if (!is.null(.qc_cache$con)) {
    try(close_db_connection(.qc_cache$con), silent = TRUE)
  }
  rm(list = ls(.qc_cache, all.names = TRUE), envir = .qc_cache)
  invisible(NULL)
}

#' Small muted line under the chat input naming the model and provider.
#' @noRd
caulochat_model_footer <- function(info) {
  if (is.null(info)) {
    return(NULL)
  }
  shiny::div(
    class = "caulochat-model text-muted small text-center mt-1",
    shiny::icon("microchip"),
    "Model: ",
    shiny::strong(info$model),
    paste0(" · Provider: ", info$provider)
  )
}

#' Card shown in place of the chat when no LLM is available.
#' @noRd
caulochat_unavailable_ui <- function(reason) {
  bslib::card(
    class = "border-warning",
    bslib::card_header(
      shiny::icon("triangle-exclamation"),
      "CauloChat is unavailable"
    ),
    bslib::card_body(
      shiny::p(reason),
      shiny::p(
        "To enable it, set these environment variables (or point ",
        shiny::code("CAULOCHAT_CONFIG"),
        " to a YAML file with the same settings) and restart the app:"
      ),
      shiny::pre(paste(
        "CAULOCHAT_PROVIDER=openai_compatible  # or ollama, anthropic, openai, litellm, ...",
        "CAULOCHAT_MODEL=<model name>",
        "CAULOCHAT_BASE_URL=<endpoint URL>     # gateways, Ollama, vLLM",
        "CAULOCHAT_API_KEY=<key>               # not needed for Ollama",
        sep = "\n"
      )),
      shiny::p(
        "See the 'Configuring CauloChat' section of the README and ",
        shiny::code("inst/caulochat-config.example.yml"),
        "."
      )
    )
  )
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
  if (is.null(qc)) {
    return(tagList(caulochat_unavailable_ui(.qc_cache$status$reason)))
  }
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
    # Rendered directly under the chat input.
    footer = caulochat_model_footer(.qc_cache$model_info),
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
    # No LLM configured: the UI already explains why.
    if (is.null(qc)) {
      return(invisible(NULL))
    }
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
