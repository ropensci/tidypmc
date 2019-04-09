#' Download PMC XML
#'
#' A wrapper for \code{epmc_ftxt} in the \code{europepmc} package to download
#' an \code{xml_document} from Europe PMC
#'
#' @param id a PMC id starting with 'PMC'
#'
#' @return \code{xml_document}
#'
#' @source \url{https://github.com/ropensci/europepmc}
#'
#' @examples
#' \dontrun{
#' doc <- europepmc::epmc_ftxt("PMC2231364") # OR
#' doc <- pmc_xml("PMC2231364")
#' }
#' doc <- read_xml(system.file("extdata/PMC2231364.xml", package = "tidypmc"))
#' doc
#'
#' @export

pmc_xml <- function(id){
   europepmc::epmc_ftxt(id)
}
