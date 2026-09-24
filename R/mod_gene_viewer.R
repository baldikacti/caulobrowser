#' gene_viewer UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_gene_viewer_ui <- function(id) {
  ns <- NS(id)
  tagList(
    bslib::card(
      bslib::card_header("Gene Viewer"),
      bslib::card_body(JBrowseR::JBrowseROutput(ns("browserOutput")))
    )
  )
}

#' gene_viewer Server Functions
#'
#' @noRd
mod_gene_viewer_server <- function(
  id,
  location = shiny::reactive(NULL),
  db_con
) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    jb_config <- shiny::reactive({
      con <- db_con()
      shiny::req(con)

      jbrowser_meta <- get_gene_viewer_metadata(con)
      tracks_df <- jbrowser_meta$tracks
      # text_index is (ix, ixx, meta.json, assembly name)
      ix <- jbrowser_meta$text_index
      assembly_name <- ix[[4]]

      assembly <- list(name = assembly_name, uri = jbrowser_meta$assembly)

      text_search <- list(
        type = "TrixTextSearchAdapter",
        textSearchAdapterId = paste0(assembly_name, "-index"),
        assemblyNames = list(assembly_name),
        ixFilePath = list(uri = ix[[1]]),
        ixxFilePath = list(uri = ix[[2]]),
        metaFilePath = list(uri = ix[[3]])
      )

      tracks <- Map(
        \(id, type, path) {
          list(
            type = if (type == "feature") {
              "FeatureTrack"
            } else {
              "QuantitativeTrack"
            },
            trackId = id,
            name = id,
            assemblyNames = list(assembly_name),
            adapter = list(
              type = if (type == "feature") {
                "Gff3TabixAdapter"
              } else {
                "BigWigAdapter"
              },
              uri = path
            )
          )
        },
        tracks_df$experiment_id,
        tracks_df$track_type,
        tracks_df$https_paths
      )

      list(
        assembly = assembly,
        tracks = unname(tracks),
        text_search = text_search,
        # Only the annotation tracks open by default; the wiggle tracks are
        # available from the track selector.
        default_tracks = as.list(
          tracks_df$experiment_id[tracks_df$track_type == "feature"]
        )
      )
    })

    effective_location <- shiny::reactive({
      loc <- location()
      if (is.null(loc) || !nzchar(trimws(loc))) {
        "gi|221232939|ref|NC_011916.1|:1..4016942"
      } else {
        loc
      }
    })

    output$browserOutput <- JBrowseR::renderJBrowseR({
      cfg <- jb_config()
      JBrowseR::JBrowseR(
        assembly = cfg$assembly,
        tracks = cfg$tracks,
        aggregateTextSearchAdapters = list(cfg$text_search),
        session = list(
          name = "CauloBrowser",
          view = list(
            id = "linearGenomeView",
            type = "LinearGenomeView",
            launch = list(
              assembly = cfg$assembly$name,
              loc = shiny::isolate(effective_location()),
              tracks = cfg$default_tracks
            )
          )
        )
        # configuration = list(theme = list(palette = list(
        #   primary = list(main = "#5da8a3"),
        #   secondary = list(main = "#333")
        # )))
      )
    })

    shiny::observeEvent(
      effective_location(),
      JBrowseR::update_jbrowse(
        "browserOutput",
        location = effective_location()
      ),
      ignoreInit = TRUE
    )
  })
}
