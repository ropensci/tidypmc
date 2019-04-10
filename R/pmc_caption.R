#' Split captions into sentences
#'
#' Split figure, table and supplementary material captions into sentences
#'
#' @param doc \code{xml_document} from PMC
#'
#' @return a tibble with tag, label, sentence number and text
#'
#' @author Chris Stubben
#'
#' @examples
#' # doc <- europepmc::epmc_ftxt("PMC2231364") # OR
#' doc <- xml2::read_xml(system.file("extdata/PMC2231364.xml",
#'         package = "tidypmc"))
#' x <- pmc_caption(doc)
#' x
#' dplyr::filter(x, sentence == 1)
#'
#' @export

pmc_caption <- function(doc){
   if(class(doc)[1] != "xml_document"){
        stop("doc should be an xml_document from PMC")
   }
   ### Figures
   z <-  xml2::xml_find_all(doc, "//fig" )
   # cat(as.character(z[[1]]))
   if(length(z) > 0) {
      n <- length(z)
      message("Found ", n, ifelse(n > 1, " figures", " figure"))
      ## should have label and caption?
      f1 <- vapply(z, function(x) xml2::xml_text(
                xml2::xml_find_first(x, "./label"), trim=TRUE), character(1))
      # get caption /title and /p tags together since some caption titles are
      # missing, in bold tags or have very long titles that should be split.
      # use node() to avoid pasting /title and /p sentences without a space
      f2 <- vapply(z, function(x) paste( xml2::xml_text(
            xml2::xml_find_all(x, "./caption/*")), collapse=" "), character(1))
      if(all(is.na(f1)) & all(f2=="")){
         ## ANY label and ANY paragrah
         f1 <- vapply(z, function(x) xml2::xml_text(
                xml2::xml_find_first(x, ".//label"), trim=TRUE), character(1))
         f2 <- vapply(z, function(x) xml2::xml_text(
                xml2::xml_find_first(x, ".//p")), character(1))
      }
      names(f2) <- gsub("\\.$", "", f1)
      ## only some fig tags with media only
      f2 <- f2[f2 != ""]
      #  text in media/ tag
      if(length(f2) == 0){
         message(" No figure /caption or /p tag to parse - link to image only?")
         figs <- NULL
      }else{
         x1 <- vapply(f2, tokenizers::tokenize_sentences, list(1))
         figs <- dplyr::bind_rows(
               lapply(x1, function(z)
                tibble::tibble(sentence = seq_along(z), text=z)), .id="label")
      }
   }else{
      figs <- NULL
   }
   ### Tables
   z  <- xml2::xml_find_all(doc, "//table-wrap")
   if(length(z) > 0) {
      n <- length(z)
      message("Found ", n, ifelse(n>1, " tables", " table"))
      ## should have label and caption?
      f1 <- vapply(z, function(x) xml2::xml_text(
               xml2::xml_find_first(x, "./label"), trim=TRUE), character(1))
      # some with long subcaptions
      f2 <- vapply(z, function(x) paste(xml2::xml_text(
          xml2::xml_find_all(x, "./caption/*")), collapse=" "), character(1))
      names(f2) <- gsub("\\.$", "", f1)
      ## only some table tags with media only
      f2 <- f2[f2 != ""]
      x1 <- vapply(f2, tokenizers::tokenize_sentences, list(1))
      tbls <- dplyr::bind_rows(
         lapply(x1, function(z)
                 tibble::tibble(sentence = seq_along(z), text=z)), .id="label")
   }else{
      tbls <- NULL
   }
   ### Supplements
   z <-  xml2::xml_find_all(doc, "//supplementary-material")
   if(length(z) > 0){
      if(!all(xml2::xml_text(z, trim=TRUE) == "")){
         n <- length(z)
         message("Found ", n, ifelse(n > 1, " supplements", " supplement"))
         ## label often missing
         f1 <- vapply(z, function(x) xml2::xml_text(
                xml2::xml_find_first(x, "./label"), trim=TRUE), character(1))
         # use paste ./caption/* to avoid mashing together title and p like
         # Additional file 1Figure S1
         f2 <- vapply(z, function(x) paste( xml2::xml_text(
            xml2::xml_find_all(x, "./caption/*")), collapse=" "), character(1))
         # mBio with /p tags only, others with media/captions only
         if(all(f2 == "")){
           f2 <- vapply(z, function(x) xml2::xml_text(
                    xml2::xml_find_first(x, ".//p")), character(1))
           f2[is.na(f2)] <- ""
         }
         # remove period to avoid splitting (DOC), (XLSX) into new sentences -
         # misses (XLSX 32 kb)
         f2 <- gsub("\\.( \\([A-Z]+\\))", "\\1", f2)
         x1 <- vapply(f2, tokenizers::tokenize_sentences,
                                                list(1), USE.NAMES=FALSE)
         if(all(is.na(f1))){
            y <- vapply(x1, function(x) x[1], character(1))
            # if all have more than 1 sentence, then use first for label if all
            # are less than 40 characters?
            if(all(vapply(x1, length, integer(1)) > 1) & all(nchar(y) < 40)){
               f1 <- y
               x1 <- lapply(x1, function(x) x[-1])
            }else{
               if(length(y) == 1){
                 message(" Missing supplement label tag, using File S1")
               }else{
                 message(" Missing supplement label tag, using File S1 to S",
                     length(y))
               }
               f1 <- paste0("File S", seq_along(y))
            }
         }
         names(x1) <- gsub("\\.$", "", f1)
         sups <- dplyr::bind_rows(
            lapply(x1, function(z)
              tibble::tibble(sentence = seq_along(z), text=z)), .id="label")
        }else{
          message(" No text found in supplement tag")
          sups <- NULL
       }
   }else{
     sups <- NULL
   }
   x <- dplyr::bind_rows(list(figure= figs, table = tbls, supplement = sups),
                          .id="tag")
   if(nrow(x) == 0){
       message("No caption tags found")
       x <- NULL
   }
   x
}
