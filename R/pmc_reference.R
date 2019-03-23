#' Format references in PMC XML
#'
#' @param doc \code{xml_document} from PMC
#'
#' @return a tibble with id, pmid, authors, year, title, journal, volume, pages,
#' and doi.
#'
#' @author Chris Stubben
#'
#' @note Mixed citations without any child tags are added to the author column.
#'
#' @examples
#' # doc <- europepmc::epmc_ftxt("PMC2231364")
#' doc <- read_xml(system.file("extdata/PMC2231364.xml", package = "tidypmc"))
#' x <- pmc_reference(doc)
#' x
#'
#' @export

pmc_reference <- function (doc){
   z <- xml_find_all(doc, "//ref")
   # cat(as.character(z[[1]]))
   if(length(z) > 0){
   n <- sapply(z, function(x) xml_name(xml_find_all(x, "./*")))
   x <- as.vector(unlist(n))
   x <- table(x[!x %in% c("label", "note")])
   message( "Found ", paste(x, names(x), collapse = " and "), " tags")
   ## xml_find_first returns NA for missing values
   pmid <- sapply(z, function(x) xml_text(xml_find_first(x, ".//pub-id[@pub-id-type='pmid']"), trim=TRUE))
   doi <-  sapply(z, function(x) xml_text(xml_find_first(x, ".//pub-id[@pub-id-type='doi']"), trim=TRUE))
   a1 <-   lapply(z, function(x) xml_text(xml_find_all(x, ".//surname"), trim=TRUE))
   a2 <-   lapply(z, function(x) xml_text(xml_find_all(x, ".//given-names"), trim=TRUE))
   ## if all references have same number of authors, use SIMPLIFY=FALSE, see PMC6369050
   authors <- sapply( mapply(paste, a1,a2, SIMPLIFY=FALSE), paste, collapse=", ")
   authors[authors == ""]<-NA
   # same authors published twice in same year, 2012a 2012b
   # year <-  sapply(z, function(x) xml_integer(xml_find_first(x, ".//year")))
   year <-  sapply(z, function(x) xml_text(xml_find_first(x, ".//year"), trim=TRUE))
   if(all(grepl("^[0-9]+$", year))) year <- as.integer(year)
   title <- sapply(z, function(x) xml_text( xml_find_first(x, ".//article-title"), trim=TRUE))
   # new lines in title PMC4909105
   title <- gsub("\n *", " ", title)
   journal<-sapply(z, function(x) xml_text( xml_find_first(x, ".//source"), trim=TRUE))
   volume <-sapply(z, function(x) xml_text( xml_find_first(x, ".//volume"), trim=TRUE))
   p1 <-    sapply(z, function(x) xml_text( xml_find_first(x, ".//fpage"), trim=TRUE))
   p2 <-    sapply(z, function(x) xml_text( xml_find_first(x, ".//lpage"), trim=TRUE))
   pages <- paste(p1, p2, sep ="-")
   pages <- gsub("-NA", "", pages)
   x <- tibble::tibble(id= 1:length(pmid), pmid, authors, year, title, journal, volume, pages, doi)
   # add mixed citation to title??
   n <- which(is.na(x$authors) & is.na(x$title))
   if(length(n) > 0){
      if(nrow(x) == length(n)) message(" References are missing author and title tags")
      else message(" ", length(n), " references are missing author and title tags")
      message(" Adding /ref string to author column")
      x$authors[n] <- sapply(z[n], xml_text)
      }
   }else{
      message("No /ref tags")
      x <-NULL
   }
   x
}
