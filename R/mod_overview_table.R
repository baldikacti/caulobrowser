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
    ns <- session$ns

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
      rows[["Genome location"]] <- paste(
        genes$start_pos,
        genes$end_pos,
        sep = ".."
      )
      rows[["Strand"]] <- genes$strand
      rows[["Biotype"]] <- genes$gene_biotype
      rows[["Essential"]] <- genes$essential
      rows[["Gene Viewer"]] <- sapply(seq_len(n), function(i) {
        g <- genes[i, ]
        viewer_link(g$start_pos, g$end_pos, ns)
      })
      rows[[
        "Molecules translated per cell (M2G)"
      ]] <- signif(genes$translated_prot_ave, 3)
      rows[[
        "Transcription rate (M2G)"
      ]] <- paste(signif(genes$copynumber_lifetime_min, 3), "minutes")
      rows[["mRNA Copy Number per Cell (M2G)"]] <- signif(genes$copynumber, 3)
      rows[["mRNA Halflife (M2G)"]] <- paste(
        signif(genes$mrna_halflife, 3),
        "minutes"
      )

      # ── Section: PRODUCT ───────────────────────────────────────────────────
      rows[[".hdr.Product"]] <- rep("", n)
      rows[["Length"]] <- genes$length
      rows[["Mass"]] <- genes$mass
      rows[["Structure"]] <- sapply(seq_len(n), function(i) {
        g <- genes[i, ]
        links <- Filter(
          Negate(is.null),
          list(
            opt_link(
              g$uniprot_id,
              sprintf(
                "https://search.foldseek.com/search?accession=%s&source=AlphaFoldDB",
                g$uniprot_id
              ),
              "Foldseek"
            ),
            {
              pdbid <- strsplit(g$PDB, ";")[[1]]
              url <- sprintf("https://www.rcsb.org/structure/%s", pdbid)
              mapply(
                \(x, y) opt_link(x, y, x),
                pdbid,
                url,
                USE.NAMES = FALSE,
                SIMPLIFY = FALSE
              ) |>
                unlist() |>
                paste(collapse = " ")
            }
          )
        )
        if (length(links) == 0) "\u2014" else paste(links, collapse = " ")
      })
      rows[["Catalytic Activity"]] <- sapply(seq_len(n), function(i) {
        g <- genes[i, ]
        if (missing_val(g$rhea_id)) {
          return(NA_character_)
        }
        rheaid <- strsplit(g$rhea_id, " ")[[1]]
        url <- sprintf(
          "https://www.rhea-db.org/rhea/%s",
          gsub("RHEA:", "", rheaid)
        )
        mapply(
          \(x, y) opt_link(x, y, x),
          rheaid,
          url,
          USE.NAMES = FALSE,
          SIMPLIFY = FALSE
        ) |>
          unlist() |>
          paste(collapse = " ")
      })
      rows[["Product"]] <- genes$product
      rows[["Function"]] <- genes$function_cc

      # ── Section: Additional Resources───────────────────────────────────────
      rows[[".hdr.Additional Resources"]] <- rep("", n)
      rows[["Homologies"]] <- sapply(seq_len(n), function(i) {
        g <- genes[i, ]
        cog <- g$COG
        if (missing_val(cog)) {
          NA_character_
        } else {
          opt_link(
            cog,
            paste0("https://www.ncbi.nlm.nih.gov/research/cog/cog/", cog),
            cog
          )
        }
      })
      rows[["Outlinks"]] <- sapply(seq_len(n), function(i) {
        g <- genes[i, ]
        links <- Filter(
          Negate(is.null),
          list(
            opt_link(
              g$protein_id,
              paste0(
                "https://www.ncbi.nlm.nih.gov/protein/",
                g$protein_id
              ),
              "NCBI Protein"
            ),
            opt_link(
              g$uniprot_id,
              sprintf(
                "https://www.uniprot.org/uniprotkb/%s/entry",
                g$uniprot_id
              ),
              "UniProt"
            ),
            opt_link(
              g$gene_id,
              paste0("https://www.genome.jp/entry/ccs:", g$gene_id),
              "KEGG"
            ),
            opt_link(
              g$gene_id,
              paste0(
                "https://biocyc.org/CAULONA1000/NEW-IMAGE?type=GENE&object=",
                g$gene_id
              ),
              "BioCyc"
            ),
            opt_link(
              g$cc_tag,
              paste0("https://string-db.org/network/190650/", g$cc_tag),
              "STRING"
            ),
            opt_link(
              g$gene_id,
              paste0(
                "https://papers.genomics.lbl.gov/cgi-bin/litSearch.cgi?query=",
                g$gene_id
              ),
              "PaperBlast"
            )
          )
        )
        if (length(links) == 0) "\u2014" else paste(links, collapse = " ")
      })

      # Convert to data frame (Category column + one column per gene)
      overview_df <- data.frame(
        Category = names(rows),
        do.call(rbind, lapply(rows, as.character)),
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
      colnames(overview_df) <- c("Category", genes$gene_name)
      rownames(overview_df) <- NULL
      overview_df
    })

    # Return the location string when a Gene Viewer link is clicked
    viewer_location <- shiny::reactive({
      input$viewer_nav
    })

    output$overview_table_ui <- shiny::renderUI({
      df <- overview_data()

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
        pagination = FALSE,
        theme = reactable::reactableTheme(
          headerStyle = list(
            backgroundColor = "#2c3e50",
            color = "#ffffff",
            fontWeight = "bold"
          )
        )
      )
    })

    viewer_location
  })
}
