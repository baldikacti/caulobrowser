# ── is_present ────────────────────────────────────────────────────────────────

test_that("is_present returns TRUE for a non-empty string", {
  expect_true(is_present("hello"))
})

test_that("is_present returns FALSE for NULL", {
  expect_false(is_present(NULL))
})

test_that("is_present returns FALSE for NA", {
  expect_false(is_present(NA))
})

test_that("is_present returns FALSE for empty string", {
  expect_false(is_present(""))
})

# ── missing_val ───────────────────────────────────────────────────────────────

test_that("missing_val returns TRUE for NA", {
  expect_true(missing_val(NA))
})

test_that("missing_val returns TRUE for empty string", {
  expect_true(missing_val(""))
})

test_that("missing_val returns FALSE for a non-empty string", {
  expect_false(missing_val("hello"))
})

# ── na_or ─────────────────────────────────────────────────────────────────────

test_that("na_or returns the value when present", {
  expect_equal(na_or("hello"), "hello")
})

test_that("na_or returns em-dash for NULL", {
  expect_equal(na_or(NULL), "—")
})

test_that("na_or returns em-dash for NA", {
  expect_equal(na_or(NA), "—")
})

test_that("na_or returns em-dash for empty string", {
  expect_equal(na_or(""), "—")
})

test_that("na_or returns custom fallback when provided", {
  expect_equal(na_or(NA, or = "N/A"), "N/A")
})

test_that("na_or with md = TRUE renders a markdown link as an anchor", {
  result <- as.character(na_or("See [the paper](https://example.com).", md = TRUE))
  expect_match(
    result,
    '<a href="https://example.com">the paper</a>',
    fixed = TRUE
  )
})

test_that("na_or with md = TRUE keeps plain text intact", {
  expect_match(
    as.character(na_or("No links here", md = TRUE)),
    "No links here",
    fixed = TRUE
  )
})

test_that("na_or with md = TRUE still returns the fallback for missing values", {
  expect_equal(na_or(NA, md = TRUE), "—")
  expect_equal(na_or(NULL, md = TRUE), "—")
  expect_equal(na_or("", md = TRUE), "—")
})

# ── make_row ──────────────────────────────────────────────────────────────────

test_that("make_row returns a shiny.tag", {
  row <- make_row("Gene", "ctrA")
  expect_s3_class(row, "shiny.tag")
})

test_that("make_row tag name is tr", {
  row <- make_row("Gene", "ctrA")
  expect_equal(row$name, "tr")
})

test_that("make_row HTML contains th with label and td with value", {
  row <- make_row("Gene", "ctrA")
  html <- as.character(row)
  expect_equal(
    html,
    "<tr>\n  <th style=\"white-space: nowrap; font-weight: 600;\">Gene</th>\n  <td>ctrA</td>\n</tr>"
  )
})

test_that("make_row accepts a shiny tag as value", {
  val <- shiny::tags$strong("bold")
  row <- make_row("Label", val)
  expect_s3_class(row, "shiny.tag")
  expect_match(as.character(row), "<strong>bold</strong>")
})

# ── ext_link ──────────────────────────────────────────────────────────────────

test_that("ext_link returns a character string", {
  result <- ext_link("https://example.com", "Example")
  expect_type(result, "character")
})

test_that("ext_link contains href and target=_blank", {
  result <- ext_link("https://example.com", "Example")
  expect_match(result, 'href="https://example.com"', fixed = TRUE)
  expect_match(result, 'target="_blank"', fixed = TRUE)
})

test_that("ext_link contains the label text", {
  result <- ext_link("https://example.com", "Example")
  expect_match(result, "Example")
})

# ── opt_link ──────────────────────────────────────────────────────────────────

test_that("opt_link returns NULL for NA val", {
  expect_null(opt_link(NA, "https://example.com", "Link"))
})

test_that("opt_link returns NULL for empty string val", {
  expect_null(opt_link("", "https://example.com", "Link"))
})

test_that("opt_link returns a link string when val is present", {
  result <- opt_link("P0ABK2", "https://uniprot.org/P0ABK2", "UniProt")
  expect_type(result, "character")
  expect_match(result, "UniProt")
  expect_match(result, 'target="_blank"', fixed = TRUE)
})

# ── viewer_link ───────────────────────────────────────────────────────────────

test_that("viewer_link returns NULL when start_pos is NA", {
  ns <- shiny::NS("test")
  expect_null(viewer_link(NA, 100, ns))
})

test_that("viewer_link returns NULL when end_pos is NA", {
  ns <- shiny::NS("test")
  expect_null(viewer_link(1, NA, ns))
})

test_that("viewer_link returns NULL when start_pos is empty string", {
  ns <- shiny::NS("test")
  expect_null(viewer_link("", 100, ns))
})

test_that("viewer_link returns NULL when end_pos is empty string", {
  ns <- shiny::NS("test")
  expect_null(viewer_link(1, "", ns))
})

test_that("viewer_link returns a character string when both coords are present", {
  ns <- shiny::NS("test")
  result <- viewer_link(1000, 2000, ns)
  expect_type(result, "character")
})

test_that("viewer_link contains Shiny.setInputValue onclick", {
  ns <- shiny::NS("test")
  result <- viewer_link(1000, 2000, ns)
  expect_match(result, "Shiny.setInputValue")
})

test_that("viewer_link formats location with NC_011916 reference and coords", {
  ns <- shiny::NS("test")
  result <- viewer_link(1000, 2000, ns)
  expect_match(result, "NC_011916.1", fixed = TRUE)
  expect_match(result, "1000..2000", fixed = TRUE)
})

test_that("viewer_link scopes input ID via the ns function", {
  ns <- shiny::NS("mymodule")
  result <- viewer_link(1000, 2000, ns)
  expect_match(result, "mymodule")
})

# ── is_hdr ────────────────────────────────────────────────────────────────────

test_that("is_hdr returns TRUE for .hdr. prefixed string", {
  expect_true(is_hdr(".hdr.GENE"))
})

test_that("is_hdr returns TRUE for bare sentinel", {
  expect_true(is_hdr(".hdr."))
})

test_that("is_hdr returns FALSE for a normal category string", {
  expect_false(is_hdr("gene_name"))
})

test_that("is_hdr returns FALSE for empty string", {
  expect_false(is_hdr(""))
})

# ── hdr_label ─────────────────────────────────────────────────────────────────

test_that("hdr_label strips the .hdr. prefix", {
  expect_equal(hdr_label(".hdr.GENE"), "GENE")
})

test_that("hdr_label handles multi-word labels", {
  expect_equal(hdr_label(".hdr.ADDITIONAL RESOURCES"), "ADDITIONAL RESOURCES")
})

test_that("hdr_label returns empty string for bare sentinel", {
  expect_equal(hdr_label(".hdr."), "")
})
