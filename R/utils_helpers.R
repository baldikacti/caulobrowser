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
#' @param md Logical. When `TRUE`, a present value is passed through
#'   [shiny::markdown()] so free-text fields containing markdown (e.g.
#'   `[text](url)` links) render as HTML. Defaults to `FALSE`.
#'
#' @return `x` (rendered as markdown when `md = TRUE`) if it is non-`NULL`,
#'   non-`NA`, and non-empty; otherwise `or`.
#' @noRd
na_or <- function(x, or = "\u2014", md = FALSE) {
  if (!is_present(x)) {
    return(or)
  }
  if (md) shiny::markdown(x) else x
}

#' Test whether a scalar is NA or empty string
#'
#' @param x A scalar value to test.
#' @return `TRUE` if `x` is `NA` or has zero characters; `FALSE` otherwise.
#' @noRd
missing_val <- function(x) is.na(x) || !nzchar(x)

#' Build an HTML anchor that opens in a new tab
#'
#' @param url Character. The href destination.
#' @param label Character. The visible link text.
#' @return A length-1 character string containing an `<a>` tag.
#' @noRd
ext_link <- function(url, label) {
  sprintf('<a href="%s" target="_blank">%s</a>', url, label)
}

#' Optionally build an external link, returning NULL when the value is missing
#'
#' @param val Scalar. The identifier used in the URL; when `NA` or empty the
#'   function returns `NULL`.
#' @param url Character. Full URL to link to.
#' @param label Character. Visible link text.
#' @return An HTML anchor string, or `NULL` if `val` is missing/empty.
#' @noRd
opt_link <- function(val, url, label) {
  if (missing_val(val)) NULL else ext_link(url, label)
}

#' Build a Shiny-wired Gene Viewer navigation link
#'
#' Generates an `<a>` tag whose `onclick` fires `Shiny.setInputValue` so the
#' Gene Viewer module can navigate to the locus. Returns `NULL` when either
#' coordinate is missing.
#'
#' @param start_pos Numeric or character. Start coordinate on the reference
#'   sequence. Treated as missing if `NA` or empty.
#' @param end_pos Numeric or character. End coordinate. Treated as missing if
#'   `NA` or empty.
#' @param ns A Shiny namespace function (from `session$ns`) used to scope the
#'   input ID.
#' @return An HTML anchor string, or `NULL`.
#' @noRd
viewer_link <- function(start_pos, end_pos, ns) {
  if (missing_val(start_pos) || missing_val(end_pos)) {
    return(NULL)
  }
  loc <- sprintf("gi|221232939|ref|NC_011916.1|:%s..%s", start_pos, end_pos)
  input_id <- ns("viewer_nav")
  sprintf(
    '<a href="#" onclick="Shiny.setInputValue(\'%s\', \'%s\', {priority: \'event\'}); return false;">link</a>',
    input_id,
    loc
  )
}

#' Test whether a Category value is a section-header sentinel
#'
#' Rows whose `Category` starts with `".hdr."` are rendered as section headers
#' in the overview reactable, not as data rows.
#'
#' @param cat Character. A value from the `Category` column.
#' @return `TRUE` if `cat` begins with `".hdr."`.
#' @noRd
is_hdr <- function(cat) startsWith(cat, ".hdr.")

#' Strip the section-header sentinel prefix from a Category value
#'
#' @param cat Character. A `.hdr.*` Category value.
#' @return The display label with the `".hdr."` prefix removed.
#' @noRd
hdr_label <- function(cat) sub("^\\.hdr\\.", "", cat)
