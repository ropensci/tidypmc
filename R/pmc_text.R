#' Split section paragraphs into sentences
#'
#' Split section paragraph tags into a table with subsection titles and sentences
#' using \code{tokenize_sentences}
#'
#' @param pmc \code{xml_document} from PMC
#'
#' @return a tibble with section, paragraph and sentence number and text
#'
#' @note Subsections may be nested to arbitrary depths and this function will return the
#' entire path to the subsection title as a delimited string, eg. "Results; Predicted
#' functions; Pathogenicity".  Any tables, figures and formulas that are nested in
#' section paragraphs are removed.
#'
#' @author Chris Stubben
#'
#' @examples
#' # doc <- europepmc::epmc_ftxt("PMC2231364")
#' doc <- read_xml(system.file("extdata/PMC2231364.xml", package = "tidypmc"))
#' txt <- pmc_text(doc)
#' txt
#' dplyr::count(txt, section, sort=TRUE)
#'
#' @export

pmc_text <- function(pmc){
   ## create new document to remove nodes
   doc <- xml_new_root(pmc)
   z <- vector("list")
   ## Main title
   z[["Title"]] <- xml_text(xml_find_all(doc, "//front//article-title"), trim=TRUE)
   ## Abstract
   z[["Abstract"]] <- xml_text(xml_find_all(doc, "//abstract[not(@abstract-type='summary')]//p"))
   ## Author summary
   author_sum <- xml_text(xml_find_all(doc, "//abstract[@abstract-type='summary']/title"))
   if(length(author_sum) > 0){
      z[[author_sum]] <- xml_text(xml_find_all(doc, "//abstract[@abstract-type='summary']//p") )
   }

   ## check for tables, figures, formula within <sec/p> tags
   n <-  xml_find_all(doc, "//sec/p/table-wrap")
   if(length(n) > 0){
        message("Note: removing table-wrap nested in sec/p tag")
        xml_remove(n)
   }
   n <-  xml_find_all(doc, "//sec/p/fig")
   if(length(n) > 0){
        message("Note: removing fig nested in sec/p tag")
         xml_remove(n)
   }
   # often with very long MathType encoding strings (not in tags and displays with formula)
   n <- xml_find_all(doc, "//sec/p/disp-formula")
   if(length(n) > 0){
        message("Note: removing disp-formula nested in sec/p tag")
         xml_remove(n)
   }
   ## DROP any sections with supplementary materials (often with nested sections missing titles )
   n <-  xml_find_all(doc, "//body//sec[@sec-type='supplementary-material']")
   if(length(n) > 0) xml_remove(n)
   ## Add brackets to numbered references with superscript tags
   bib <- xml_find_all(doc, "//sup/xref[@ref-type='bibr']")
   if( length(bib)>0){
      message("Adding brackets to numbered references in /sup tags")
      xml_text(bib) <- paste0(" [", xml_text(bib), "]")
   }

   ## parse text from Sections
   sec <- xml_find_all(doc, "//body//sec")
   if(length(sec) == 0){
      message("NOTE: No sections found, using all text in main body/p")
      z[["[Main]"]] <- xml_text(xml_find_all(doc, "//body/p"))
   }else{
      ## Emerging infectious diseases has both body/p and body/sec
      intro <- xml_text(xml_find_all(doc, "//body/p"))
      if(length(intro) > 0){
         message("NOTE: Body has both /p and /sec child tags - untitled Introduction?")
         z[["[Introduction]"]] <- xml_text(xml_find_all(doc, "//body/p"))
      }
      # /sec should have both title and p?
      sec <- xml_find_all(doc, "//body//sec")
      ## section titles
      t1 <- xml_text(xml_find_all(doc, xpath= "//body//sec/title"))
      ## indentation level of subsections
      n <- stringr::str_count(xml_path( xml_find_all(doc, xpath= "//body//sec/title")), "/")
      ## full path to subsection title
      path <- path_string(t1, n)
      ## section paragraphs (get sec/p and not any //p)
      secP  <- lapply(sec, function(x) xml_text( xml_find_all(x, "./p")))
      if(length(path) != length(secP)) message("Warning: some sections are missing /title tags")
      minP <- min(length(path), length(secP))
      ##LOOP through subsections and skip sections missing /p tags
      for(i in 1: minP ){
         subT <- path[i]
         subT <- gsub("\\.$", "", subT)
         # in case of nested sec tags,  replace "; ; ; "
         subT <- gsub("[; ]{3,}", "; ", subT)
         if(length(secP[[i]]) > 0){
              ## don't split Fig. 1 into two sentences, probably many others (et al. ??)
              p1 <- lapply(secP[[i]], function(x) gsub("([ (][Ff]ig)\\.", "\\1", x))
              z[[ subT ]] <- p1
          }
      }
   }
   x <- lapply(z, tokenizers::tokenize_sentences)
   x1 <- lapply(x, function(y) dplyr::bind_rows(
            lapply(y, function(z) if(length(z)>0) tibble::tibble(sentence = 1:length(z), text=z)),
              .id="paragraph"))
   x <- dplyr::bind_rows(x1, .id="section") %>% dplyr::mutate(paragraph = as.integer(paragraph))
  # replace en dash or em dash to separate ranges
   x$text <- gsub("\u2011|\u2012|\u2013|\u2014", "-", x$text)
   ## if brackets added to superscripted references
   x$text <- gsub("]- \\[", "-", x$text)
   x
}
