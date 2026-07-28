test_that("mod_overview_table_ui works", {
  ui <- mod_overview_table_ui(id = "test")
  golem::expect_shinytaglist(ui)
  fmls <- formals(mod_overview_table_ui)
  expect_true("id" %in% names(fmls))
})

test_that("mod_overview_table_server has correct formals", {
  fmls <- formals(mod_overview_table_server)
  for (i in c("id", "gene_results", "db_con")) {
    expect_true(i %in% names(fmls))
  }
})

# overview_data has Category column and one column named after the gene
testServer(
  mod_overview_table_server,
  args = list(
    gene_results = shiny::reactive(
      search_genes(
        DBI::dbConnect(
          duckdb::duckdb(),
          test_db_path()
        ),
        "CCNA_01248"
      )
    ),
    db_con = shiny::reactiveVal(NULL)
  ),
  {
    df <- overview_data()
    expect_true("Category" %in% colnames(df))
    expect_true("CCNA_01248" %in% colnames(df))
    expect_equal(ncol(df), 2) # Category + one gene
  }
)

# overview_data contains all three section-header sentinels
testServer(
  mod_overview_table_server,
  args = list(
    gene_results = shiny::reactive(
      search_genes(
        DBI::dbConnect(
          duckdb::duckdb(),
          test_db_path()
        ),
        "CCNA_01248"
      )
    ),
    db_con = shiny::reactiveVal(NULL)
  ),
  {
    df <- overview_data()
    expect_true(".hdr.Gene" %in% df$Category)
    expect_true(".hdr.Product" %in% df$Category)
    expect_true(".hdr.Additional Resources" %in% df$Category)
  }
)

# overview_data adds one column per searched gene
testServer(
  mod_overview_table_server,
  args = list(
    gene_results = shiny::reactive(
      search_genes(
        DBI::dbConnect(
          duckdb::duckdb(),
          test_db_path()
        ),
        "CCNA_00090,CCNA_01248"
      )
    ),
    db_con = shiny::reactiveVal(NULL)
  ),
  {
    df <- overview_data()
    expect_equal(ncol(df), 3) # Category + 2 genes
    expect_true("CCNA_00090" %in% colnames(df))
    expect_true("CCNA_01248" %in% colnames(df))
  }
)

# viewer_location is NULL before any Gene Viewer link is clicked
testServer(
  mod_overview_table_server,
  args = list(
    gene_results = shiny::reactive(
      search_genes(
        DBI::dbConnect(
          duckdb::duckdb(),
          test_db_path()
        ),
        "ctrA"
      )
    ),
    db_con = shiny::reactiveVal(NULL)
  ),
  {
    expect_null(viewer_location())
  }
)

# viewer_location returns the navigation string when input$viewer_nav is set
testServer(
  mod_overview_table_server,
  args = list(
    gene_results = shiny::reactive(
      search_genes(
        DBI::dbConnect(
          duckdb::duckdb(),
          test_db_path()
        ),
        "ctrA"
      )
    ),
    db_con = shiny::reactiveVal(NULL)
  ),
  {
    loc <- "gi|221232939|ref|NC_011916.1|:101960..102943"
    session$setInputs(viewer_nav = loc)
    expect_equal(viewer_location(), loc)
  }
)
