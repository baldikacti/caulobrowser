#' Create an HTML table row with a label and value cell
#'
#' @param label Character. Text for the header cell (`<th>`).
#' @param value The content for the data cell (`<td>`). Can be a string or a
#'   Shiny tag object.
#'
#' @return A `shiny.tag` object representing a `<tr>` element.
#' @noRd
make_row <- function(label, value) {
  shiny::tags$tr(
    shiny::tags$th(label, style = "white-space: nowrap; font-weight: 600;"),
    shiny::tags$td(value)
  )
}

#' Test whether a scalar is non-NULL, non-NA, and non-empty
#'
#' @param x A scalar value to test.
#' @return `TRUE` if `x` is non-`NULL`, non-`NA`, and has at least one character.
#' @noRd
is_present <- function(x) {
  !is.null(x) && !is.na(x) && nzchar(x)
}

#' Return a value or a fallback if missing/empty
#'
#' Coalesces `NULL`, `NA`, and empty strings to `or` so UI cells
#' always display something meaningful.
#'
#' @param x A scalar value to test.
#' @param or The fallback value to return when `x` is `NULL`, `NA`, or empty.
#'   Defaults to `"—"` (em-dash).
#'
#' @return `x` if it is non-`NULL`, non-`NA`, and non-empty; otherwise `or`.
#' @noRd
na_or <- function(x, or = "\u2014") {
  if (is_present(x)) x else or
}
