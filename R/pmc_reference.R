#' Format references in PMC XML
#'
#' @param doc \code{xml_document} from PMC
#'
#' @return a tibble with id, pmid, authors, year, title, journal, volume, pages,
#' and doi.
#'
#' @author Chris Stubben
#'
#' @note Mixed citations without any child tags are added to the title column.
#'
#' @examples
#' # doc <- epmc_ftxt("PMC2231364")
#' doc <- read_xml(system.file("extdata/PMC2231364.xml", package = "tidypmc"))
#' x <- pmc_reference(doc)
#' x
#'
#' @export

pmc_reference <- function (doc){
   z <- xml_find_all(doc, "//ref")
   # cat(as.character(z[[1]]))
   n <- sapply(z, function(x) xml_name(xml_find_all(x, "./*")))
   x <- as.vector(n)
   x <- table(x[x!="label"])
   message( "Found ", paste(x, names(x), collapse = " and "), " tags")
   ## xml_find_first returns NA for missing values
   pmid <-  sapply(z, function(x) xml_text(xml_find_first(x, ".//pub-id[@pub-id-type='pmid']")))
   doi <-   sapply(z, function(x) xml_text(xml_find_first(x, ".//pub-id[@pub-id-type='doi']")))
   a1 <-    sapply(z, function(x) xml_text(xml_find_all(x, ".//surname")))
   a2 <-    sapply(z, function(x) xml_text(xml_find_all(x, ".//given-names")))
   authors<-sapply( mapply(paste, a1,a2), paste, collapse=", ")
   authors[authors == ""]<-NA
   year <-  sapply(z, function(x) xml_integer(xml_find_first(x, ".//year")))
   title <- sapply(z, function(x) xml_text( xml_find_first(x, ".//article-title")))
   journal<-sapply(z, function(x) xml_text( xml_find_first(x, ".//source")))
   volume <-sapply(z, function(x) xml_text( xml_find_first(x, ".//volume")))
   p1 <-    sapply(z, function(x) xml_text( xml_find_first(x, ".//fpage")))
   p2 <-    sapply(z, function(x) xml_text( xml_find_first(x, ".//lpage")))
   pages <- mapply(paste, p1,p2, MoreArgs = list(sep="-"))
   x <- tibble::tibble(id= 1:length(pmid), pmid, authors, year, title, journal, volume, pages, doi)
   # add mixed citation to title??
   n <- which(is.na(x$year) & is.na(x$title))
   if(length(n) > 0) x$title[n] <- sapply(z[n], xml_text)
   x
}
