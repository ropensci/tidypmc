#' Download XML from PubMed Central
#'
#' @param id a PMC id starting with 'PMC'
#'
#' @return \code{xml_document}
#'
#' @source \url{https://europepmc.org/RestfulWebService}
#'
#' @examples
#' \dontrun{
#' doc <- pmc_xml("PMC2231364")
#' }
#'
#' @export

pmc_xml <- function(id) {
  if (!grepl("^PMC[0-9]+$", id)) {
    stop("id should be a valid PMC id like PMC2231364")
  }
  url1 <- paste0(
    "https://www.ebi.ac.uk/europepmc/webservices/rest/", id, "/fullTextXML"
  )
  xml2::read_xml(url1)
}
