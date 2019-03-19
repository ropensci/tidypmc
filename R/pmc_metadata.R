#' Get PMC article metadata
#'
#' Get a list of journal and article metadata in /front tag
#'
#' @param doc \code{xml_document} from PMC
#'
#' @return  a list
#'
#' @author Chris Stubben
#'
#' @examples
#' # doc <- europepmc::epmc_ftxt("PMC2231364") # OR
#' doc <- read_xml(system.file("extdata/PMC2231364.xml", package = "tidypmc"))
#' pmc_metadata(doc)
#'
#' @export

pmc_metadata <-function(doc ){
   z <- vector("list")
   ## //front has journal-meta and article-meta
   # cat( as.character(xml_find_all(doc, "//journal-meta")))
   pmcid <- xml_text(xml_find_first(doc, "//front//article-id[@pub-id-type='pmcid']"))
   if(!is.na(pmcid))   z[["PMCID"]] <- paste0("PMC", pmcid)
   z[["Title"]] <- xml_text(xml_find_all(doc, "//front//article-title"))
   a1 <- xml_text(xml_find_all(doc, "//front//contrib[not(@contrib-type='editor')]/name/given-names"))
   a2 <- xml_text(xml_find_all(doc, "//front//contrib[not(@contrib-type='editor')]/name/surname"))
   if(length(a1) != length(a2)) message("WARNING: Check author names -missing first or last tag")
   authors <-  paste(a1, a2)
   ## comma-delimited string (easier to bind_rows with multiple pmcids)
   authors <-  paste(authors, collapse=", ")
   z[["Authors"]] <- authors
   # PUB Dates  - tags always sorted day, month, year?
    epub <- xml_text( xml_find_all(doc, "//pub-date[@pub-type='epub']/*") )
   if(length(epub) > 0) z[["Published online"]] <- paste(rev(epub), collapse="-")
   rec <- xml_text( xml_find_all(doc, "//history/date[@date-type='received']/*") )
   if(length(rec) > 0) z[["Date received"]] <- paste(rev(rec), collapse="-")
   # Journal meta
   journal <- xml_text( xml_find_first(doc,  "//journal-meta//journal-title"))
   if(!is.na(journal))  z[["Journal"]] <- journal
   ## volume and issue in article metadata
   volume <- xml_text( xml_find_first(doc, "//article-meta/volume"))
   if(!is.na(volume)) z[["Volume"]] <- volume
   issue <- xml_text( xml_find_first(doc, "//article-meta/issue"))
   if(!is.na(issue)) z[["Issue"]] <- issue
   #PAGES
   p1 <- xml_text( xml_find_first(doc, "//article-meta/fpage"))
   if(!is.na(p1)){
      p2 <- xml_text( xml_find_first(doc, "//article-meta/lpage"))
      if(p1 != p2) p1 <- paste(p1, p2, sep="-")
   }else{
      p1 <- xml_text( xml_find_first(doc, "//article-meta/elocation-id"))

   }
   z[["Pages"]]  <- p1
   ## DOI
   doi <- xml_text(xml_find_first(doc, "//front//article-id[@pub-id-type='doi']"))
   if(!is.na(doi)) z[["DOI"]] <- doi
   #publisher?
   x <- xml_text( xml_find_all(doc,  "//journal-meta//publisher-name"))
   if(!is.na(x)) z[["Publisher"]]<- x
   z
}
