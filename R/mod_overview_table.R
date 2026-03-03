#' Gene Overview Table Module (Figure 1)
#'
#' @description A shiny module that displays the gene overview table.
#'   Reproduces CauloBrowser Figure 1: a tabular summary with one column per
#'   searched gene, organised into sections (Gene, Product, Additional Resources).
#'
#' @param id Internal parameter for {shiny} module namespacing.
#'
#' @name mod_overview_table
#' @noRd

mod_overview_table_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::tagList(
    shiny::uiOutput(ns("overview_table_ui"))
  )
}


mod_overview_table_server <- function(id, gene_results, db_con) {
  shiny::moduleServer(id, function(input, output, session) {
    # Helper: produce an HTML anchor, or "—" when value is missing/empty
    ext_link <- function(url, label) {
      sprintf('<a href="%s" target="_blank">%s</a>', url, label)
    }
    missing_val <- function(x) is.na(x) || !nzchar(x)

    # Build the overview data: one column per gene, rows = annotation categories
    overview_data <- shiny::reactive({
      genes <- gene_results()
      shiny::req(nrow(genes) > 0)

      n <- nrow(genes)
      rows <- list()

      # ── Section: GENE ──────────────────────────────────────────────────────
      rows[[".hdr.Gene"]] <- rep("", n)
      rows[["Name"]] <- genes$gene_name
      rows[["Locus Tag (CCNA)"]] <- genes$gene_id
      rows[["CC Tag"]] <- genes$cc_tag
      rows[["Biotype"]] <- genes$gene_biotype

      # ── Section: PRODUCT ───────────────────────────────────────────────────
      rows[[".hdr.Product"]] <- rep("", n)
      rows[["Description"]] <- genes$description
      rows[["NCBI Protein"]] <- sapply(genes$ncbi_protein_id, function(pid) {
        if (missing_val(pid)) {
          "—"
        } else {
          ext_link(
            paste0("https://www.ncbi.nlm.nih.gov/protein/", pid),
            "Search NCBI"
          )
        }
      })
      rows[["UniProt"]] <- sapply(genes$gene_name, function(gn) {
        if (missing_val(gn)) {
          "—"
        } else {
          ext_link(
            paste0(
              "https://www.uniprot.org/uniprotkb?query=",
              gn,
              "+AND+organism_id:565050"
            ),
            "Search UniProt"
          )
        }
      })

      # ── Section: ADDITIONAL RESOURCES ──────────────────────────────────────
      rows[[".hdr.Additional Resources"]] <- rep("", n)

      rows[["KEGG"]] <- sapply(genes$gene_id, function(locus) {
        # gene_id holds the CCNA locus tag; KEGG organism code for NA1000 is ccs
        if (missing_val(locus)) {
          "—"
        } else {
          ext_link(
            paste0("https://www.genome.jp/entry/ccs:", locus),
            "Search KEGG"
          )
        }
      })
      rows[["BioCyc"]] <- sapply(genes$gene_id, function(locus) {
        # CAULONA1000 is the BioCyc database for Caulobacter vibrioides NA1000
        if (missing_val(locus)) {
          "—"
        } else {
          ext_link(
            paste0(
              "https://biocyc.org/CAULONA1000/NEW-IMAGE?type=GENE&object=",
              locus
            ),
            "Search BioCyc"
          )
        }
      })

      # Convert to data frame (Category column + one column per gene)
      overview_df <- data.frame(
        Category = names(rows),
        do.call(rbind, lapply(rows, as.character)),
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
      idx <- is.na(genes$gene_name) | genes$gene_name == ""
      genes$gene_name[idx] <- genes$gene_id[idx]
      colnames(overview_df) <- c("Category", genes$gene_name)
      rownames(overview_df) <- NULL
      overview_df
    })

    output$overview_table_ui <- shiny::renderUI({
      shiny::req(overview_data())
      df <- overview_data()

      is_hdr <- function(cat) startsWith(cat, ".hdr.")
      hdr_label <- function(cat) sub("^\\.hdr\\.", "", cat)

      hdr_style <- list(
        backgroundColor = "#2c3e50",
        color = "#ffffff",
        fontWeight = "bold",
        fontSize = "0.78em",
        textTransform = "uppercase",
        letterSpacing = "0.06em"
      )
      cat_style <- list(fontWeight = "bold", backgroundColor = "#f8f9fa")

      # Build the named columns list explicitly to avoid c() name-NA edge cases
      gene_cols <- colnames(df)[-1]

      # Gene colDefs: header rows have "" in the cell value — use that to style
      gene_coldefs <- lapply(gene_cols, function(col_name) {
        reactable::colDef(
          name = col_name,
          html = TRUE,
          minWidth = 160,
          style = function(value) {
            # Header rows are stored as "" in gene columns; NA = missing data, no special style
            if (!is.na(value) && !nzchar(trimws(value))) hdr_style else list()
          }
        )
      })
      names(gene_coldefs) <- gene_cols

      all_cols <- c(
        list(
          Category = reactable::colDef(
            name = "",
            minWidth = 200,
            cell = function(value) {
              if (!is.na(value) && is_hdr(value)) hdr_label(value) else value
            },
            style = function(value) {
              if (!is.na(value) && is_hdr(value)) hdr_style else cat_style
            }
          )
        ),
        gene_coldefs
      )

      reactable::reactable(
        df,
        columns = all_cols,
        sortable = FALSE,
        bordered = TRUE,
        striped = FALSE,
        compact = TRUE,
        defaultPageSize = 20,
        theme = reactable::reactableTheme(
          headerStyle = list(
            backgroundColor = "#2c3e50",
            color = "#ffffff",
            fontWeight = "bold"
          )
        )
      )
    })
  })
}
