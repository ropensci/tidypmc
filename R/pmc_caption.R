#' Split figure, table and supplementary material captions into sentences
#'
#' @param doc \code{xml_document} from PMC
#'
#' @return a tibble with tag, label, sentence number and text
#'
#' @author Chris Stubben
#'
#' @examples
#' # doc <- epmc_ftp("PMC2231364") # OR
#' doc <- read_xml(system.file("extdata/PMC2231364.xml", package = "tidypmc"))
#' x <- pmc_caption(doc)
#' x
#' dplyr::filter(x, sentence==1)
#'
#' @export

pmc_caption <- function(doc){
   ### Figures
   z <-  xml_find_all(doc, "//fig" )
   # cat(as.character(z[[1]]))
   if (length(z) > 0) {
      n <- length(z)
      message("Found ", n, ifelse(n > 1, " figures", " figure"))
      ## should have label and caption?
      f1 <- sapply(z, function(x) xml_text(xml_find_first(x, "./label")))
      # get caption /title and /p tags together since some caption titles are missing,
      # in bold tags or have very long titles that should be split.
      ## use node() or * to avoid pasting /title and /p sentences without a space ()
      f2 <- sapply(z, function(x) paste(xml_text(xml_find_all(x, "./caption/*")), collapse=" "))
      names(f2) <- f1
      x1 <- sapply(f2, tokenizers::tokenize_sentences)
      figs <- dplyr::bind_rows(
         lapply(x1, function(z) tibble::tibble(sentence = 1:length(z), text=z)), .id="label")
   }else{
      figs <- NULL
   }
   ### Tables
   z  <- xml_find_all(doc, "//table-wrap")
   if (length(z) > 0) {
      n <- length(z)
      message("Found ", n, ifelse(n>1, " tables", " table"))
      ## should have label and caption?
      f1 <- sapply(z, function(x) xml_text(xml_find_first(x, "./label")))
      # some with long subcaptions
      f2 <- sapply(z, function(x) paste( xml_text(xml_find_all(x, "./caption/*")), collapse=" "))
      names(f2) <- f1
      x1 <- sapply(f2, tokenizers::tokenize_sentences)
      tbls <- dplyr::bind_rows(
         lapply(x1, function(z) tibble::tibble(sentence = 1:length(z), text=z)), .id="label")
   }else{
      tbls <- NULL
   }
   ### Supplements
   z <-  xml_find_all(doc, "//supplementary-material")
   if(length(z) > 0){
      n <- length(z)
      message("Found ", n, ifelse(n>1, " supplements", " supplement"))
      ## BMC has labels in caption title (Additional file 1) and start of paragraph (Figure S1)
      f1 <- sapply(z, function(x) xml_text(xml_find_first(x, "./label")))
      ## use ./caption to avoid media/caption tags...
      f2 <- sapply(z, function(x) paste( xml_text(xml_find_all(x, "./caption/*")), collapse=" "))
      # mBio with /p tags only
      if(all(f2 == "")) f2 <- sapply(z, function(x) xml_text(xml_find_all(x, "./p")))
      #  text in media/ tag
      if(is.na(f1[1]) & length(f2[[1]]) == 0){
         message(" No supplement /caption or /p tag to parse")
         sups <- NULL
      }else{
         ## remove period to avoid splitting (DOC), (XLSX), etc into new sentence.
         f2 <- gsub("\\.( \\([A-Z]+\\))", "\\1", f2)
         x1 <- sapply(f2, tokenizers::tokenize_sentences, USE.NAMES=FALSE)
         if(all(is.na(f1))){
            y <- sapply(x1, function(x) x[1])
            ## if all have more than 1 sentence, then use first for label if all are less than 40 characters?
            if(all(sapply(x1, length)>1) & all( nchar(y) < 40)  ){
                f1 <- y
                x1 <- sapply(x1, function(x) x[-1])
            }else{
               message(" Missing supplement label tag, using File S1 to ", length(z))
               f1 <- paste0("File S", 1:length(z))
            }
         }
         names(x1) <- f1
         sups <- dplyr::bind_rows(
            lapply(x1, function(z) tibble::tibble(sentence = 1:length(z), text=z)), .id="label")
      }
   }else{
     sups <- NULL
   }
   x <- dplyr::bind_rows(list(figure= figs, table = tbls, supplement = sups), .id="tag")
   if(nrow(x) == 0) message("No tags found")
   x
}
