#' Render a single `ellmer::Content` item as markdown for the transcript
#'
#' Text content passes through as-is. The querychat tool calls that drive the
#' Results/SQL Query cards (`querychat_update_dashboard`, `querychat_visualize`)
#' are rendered as a titled SQL/ggsql code block so the query behind an answer
#' is preserved in the export. Tool results and any other content types are
#' dropped (their effect is already visible in the Results/SQL Query cards).
#'
#' @param item an `ellmer::Content` object
#' @return character scalar, possibly `""`
#' @noRd
format_chat_content_item <- function(item) {
  if (inherits(item, "ellmer::ContentText")) {
    return(trimws(item@text))
  }
  if (inherits(item, "ellmer::ContentToolRequest")) {
    args <- item@arguments
    return(switch(item@name,
      querychat_update_dashboard = paste0(
        "**Query:** ", args$title %||% "(untitled)", "\n\n",
        "```sql\n", trimws(args$query %||% ""), "\n```"
      ),
      querychat_visualize = paste0(
        "**Visualization:** ", args$title %||% "(untitled)", "\n\n",
        "```\n", trimws(args$ggsql %||% ""), "\n```"
      ),
      querychat_reset_dashboard = "_Reset dashboard._",
      ""
    ))
  }
  ""
}

#' Format a CauloChat conversation as a markdown transcript
#'
#' @param turns list of `ellmer::Turn` objects (from `chat$get_turns()`)
#' @param greeting character scalar, raw greeting HTML/markdown shown at
#'   chat startup (not recorded as a turn by querychat, so it must be passed
#'   in separately)
#' @param title character scalar, current dashboard title (optional)
#' @param exported_at POSIXct, injectable for deterministic tests
#'
#' @return single character string, the full markdown transcript
#' @noRd
format_chat_transcript <- function(turns = list(),
                                    greeting = NULL,
                                    title = NULL,
                                    exported_at = Sys.time()) {
  header <- "# CauloChat Transcript"
  if (nzchar(trimws(title %||% ""))) {
    header <- c(header, paste0("**Dashboard title:** ", title))
  }
  header <- c(header, paste0("**Exported:** ", format(exported_at, "%Y-%m-%d %H:%M:%S")))

  sections <- character(0)
  if (nzchar(trimws(greeting %||% ""))) {
    sections <- c(sections, paste0("## Assistant\n\n", trimws(greeting)))
  }

  for (turn in turns) {
    pieces <- vapply(turn@contents, format_chat_content_item, character(1))
    text <- trimws(paste(pieces[nzchar(pieces)], collapse = "\n\n"))
    if (!nzchar(text)) next
    role_header <- switch(turn@role,
      user = "## User",
      assistant = "## Assistant",
      system = "## System",
      paste0("## ", turn@role)
    )
    sections <- c(sections, paste0(role_header, "\n\n", text))
  }

  if (length(sections) == 0) {
    sections <- "_No conversation recorded yet._"
  }

  paste(
    paste(header, collapse = "\n\n"),
    paste(sections, collapse = "\n\n---\n\n"),
    sep = "\n\n---\n\n"
  )
}

#' Build a filename for a downloaded CauloChat transcript
#'
#' @param title character scalar, current dashboard title (optional)
#' @param timestamp POSIXct, injectable for deterministic tests
#'
#' @return character scalar filename ending in `.md`
#' @noRd
chat_export_filename <- function(title = NULL, timestamp = Sys.time()) {
  ts <- format(timestamp, "%Y%m%d-%H%M%S")

  slug <- if (nzchar(trimws(title %||% ""))) {
    s <- gsub("^-+|-+$", "", gsub("[^a-z0-9]+", "-", tolower(trimws(title))))
    if (nzchar(s)) s else NULL
  } else {
    NULL
  }

  if (!is.null(slug)) {
    sprintf("caulochat-%s-%s.md", slug, ts)
  } else {
    sprintf("caulochat-transcript-%s.md", ts)
  }
}
