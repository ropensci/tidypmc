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
#' doc <- xml2::read_xml(system.file("extdata/PMC2231364.xml",
#'         package = "tidypmc"))
#' pmc_metadata(doc)
#'
#' @export

pmc_metadata <-function(doc){
   if(class(doc)[1] != "xml_document"){
        stop("doc should be an xml_document from PMC")
   }
   z <- vector("list")
   ## //front has journal-meta and article-meta
   # cat( as.character(xml2::xml_find_all(doc, "//front//journal-meta")))
   pmcid <- xml2::xml_text(xml2::xml_find_first(doc,
             "//front//article-id[@pub-id-type='pmcid']"))
   if(!is.na(pmcid))   z[["PMCID"]] <- paste0("PMC", pmcid)
   t1 <- xml2::xml_text(xml2::xml_find_first(doc,
                                        "//front//article-title"), trim=TRUE)
   if(!is.na(t1)){
       z[["Title"]] <- t1
      a1 <- xml2::xml_text(xml2::xml_find_all(doc,
              "//front//contrib[not(@contrib-type='editor')]/name/given-names"))
      a2 <- xml2::xml_text(xml2::xml_find_all(doc,
                "//front//contrib[not(@contrib-type='editor')]/name/surname"))
      if(length(a1) != length(a2)){
          message("WARNING: Check author names -missing first or last tag")
      }
      authors <-  paste(a1, a2)
      ## comma-delimited string (easier to bind_rows with multiple pmcids)
      authors <-  paste(authors, collapse=", ")
      z[["Authors"]] <- authors
      ## Year published,  use collection else ppub year?
      year <- xml2::xml_text( xml2::xml_find_first(doc,
                  "//front//pub-date[@pub-type='collection']/year") )
      if(is.na(year)) year <- xml2::xml_text( xml2::xml_find_first(doc,
                                   "//front//pub-date[@pub-type='ppub']/year"))
      if(is.na(year)) year <- xml2::xml_text( xml2::xml_find_first(doc,
                                   "//front//pub-date[@pub-type='epub']/year"))
      if(!is.na(year))  z[["Year"]] <- as.integer(year)
      # Journal meta
      journal <- xml2::xml_text(xml2::xml_find_first(doc,
                      "//front//journal-meta//journal-title"))
      if(!is.na(journal))  z[["Journal"]] <- journal
      ## volume and issue in article metadata
      volume <- xml2::xml_text( xml2::xml_find_first(doc,
                                             "//front//article-meta/volume"))
      if(!is.na(volume)) z[["Volume"]] <- volume
      issue <- xml2::xml_text( xml2::xml_find_first(doc,
                                              "//front//article-meta/issue"))
      if(!is.na(issue)) z[["Issue"]] <- issue
      #PAGES
      p1 <- xml2::xml_text( xml2::xml_find_first(doc,
                                              "//front//article-meta/fpage"))
      if(!is.na(p1)){
         p2 <- xml2::xml_text( xml2::xml_find_first(doc,
                                              "//front//article-meta/lpage"))
         if(p1 != p2) p1 <- paste(p1, p2, sep="-")
      }else{
         p1 <- xml2::xml_text(xml2::xml_find_first(doc,
                                     "//front//article-meta/elocation-id"))
      }
      z[["Pages"]] <- p1
      # More PUB Dates  - tags always sorted day, month, year?
      epub <- xml2::xml_text(xml2::xml_find_all(doc,
                                    "//front//pub-date[@pub-type='epub']/*"))
      if(length(epub) > 0){
          z[["Published online"]] <- paste(rev(epub), collapse="-")
      }
      rec <- xml2::xml_text(xml2::xml_find_all(doc,
                  "//front//history/date[@date-type='received']/*") )
      if(length(rec) > 0) z[["Date received"]] <- paste(rev(rec), collapse="-")
      ## DOI
      doi <- xml2::xml_text(xml2::xml_find_first(doc,
                      "//front//article-id[@pub-id-type='doi']"))
      if(!is.na(doi)) z[["DOI"]] <- doi
      # Publisher?
      x <- xml2::xml_text(xml2::xml_find_first(doc,
                                 "//front//journal-meta//publisher-name"))
      if(!is.na(x)) z[["Publisher"]]<- x
   }else{
      message("No title found. Not a PMC XML document?")
      z <- NULL
   }
   z
}
