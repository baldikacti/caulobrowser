test_that("mod_gene_search_ui works", {
  ui <- mod_gene_search_ui(id = "test")
  golem::expect_shinytaglist(ui)
  fmls <- formals(mod_gene_search_ui)
  for (i in c("id")) {
    expect_true(i %in% names(fmls))
  }
})

test_that("mod_gene_search_server has correct formals", {
  fmls <- formals(mod_gene_search_server)
  for (i in c("id", "db_con")) {
    expect_true(i %in% names(fmls))
  }
})

# Namespace wiring
testServer(
  mod_gene_search_server,
  args = list(
    db_con = shiny::reactiveVal(DBI::dbConnect(
      duckdb::duckdb(),
      system.file("extdata", "caulobrowser.duckdb", package = "caulobrowser")
    ))
  ),
  {
    ns <- session$ns
    expect_true(inherits(ns, "function"))
    expect_true(grepl("test", ns("test")))
  }
)

# Known-gene search returns matching row
testServer(
  mod_gene_search_server,
  args = list(
    db_con = shiny::reactiveVal(DBI::dbConnect(
      duckdb::duckdb(),
      system.file("extdata", "caulobrowser.duckdb", package = "caulobrowser")
    ))
  ),
  {
    session$setInputs(gene_query = "CCNA_00090", btn_search = 1)
    result <- gene_results()
    expect_equal(nrow(result), 1)
    expect_equal(result$gene_name, "CCNA_00090")
  }
)

# No-match query returns 0 rows
testServer(
  mod_gene_search_server,
  args = list(
    db_con = shiny::reactiveVal(DBI::dbConnect(
      duckdb::duckdb(),
      system.file("extdata", "caulobrowser.duckdb", package = "caulobrowser")
    ))
  ),
  {
    session$setInputs(gene_query = "notAGene", btn_search = 1)
    result <- gene_results()
    expect_equal(nrow(result), 0)
  }
)

# Comma-separated query returns multiple genes
testServer(
  mod_gene_search_server,
  args = list(
    db_con = shiny::reactiveVal(DBI::dbConnect(
      duckdb::duckdb(),
      system.file("extdata", "caulobrowser.duckdb", package = "caulobrowser")
    ))
  ),
  {
    session$setInputs(gene_query = "CCNA_00090,CCNA_01248", btn_search = 1)
    result <- gene_results()
    expect_gte(nrow(result), 2)
  }
)

# Search by CCNA locus tag
testServer(
  mod_gene_search_server,
  args = list(
    db_con = shiny::reactiveVal(DBI::dbConnect(
      duckdb::duckdb(),
      system.file("extdata", "caulobrowser.duckdb", package = "caulobrowser")
    ))
  ),
  {
    session$setInputs(gene_query = "CCNA_00090", btn_search = 1)
    result <- gene_results()
    expect_equal(nrow(result), 1)
    expect_equal(result$gene_id, "CCNA_00090")
  }
)
