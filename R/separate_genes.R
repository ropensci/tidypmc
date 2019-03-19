#' Separate genes and operons into multiple rows
#'
#' Separate genes and operons mentioned in full text into multiple rows
#'
#' @param txt a table
#' @param pattern regular expression to match genes, default is to match microbial
#' genes like AbcD, default [A-Za-z][a-z]{2}[A-Z0-9]+
#' @param genes an optional vector of genes, set pattern to NA to only match this list.
#' @param operon operon length, default 6. Split genes with 6 or more letters into
#' separate genes, for example AbcDEF is split into abcD, abcE and abcF.
#' @param column column name to search, default "text"
#'
#' @note Check for genes in italics using \code{xml_text(xml_find_all(doc, "//sec//p//italic"))}
#' and update the pattern or add additional genes as an optional vector if needed
#'
#' @return a tibble with gene name, matching text and rows.
#'
#' @author Chris Stubben
#'
#' @examples
#' x <- data.frame(row=1, text = "Genes like YacK, hmu and sufABC")
#' separate_genes(x)
#' #
#' separate_genes(x, genes="hmu")
#'
#' @export

separate_genes <- function(txt, pattern="\\b[A-Za-z][a-z]{2}[A-Z0-9]+\\b", genes, operon = 6, column = "text"){
   if(!missing(genes)){
         x1 <- paste0("\\b", paste(genes, collapse = "\\b|\\b"), "\\b")
         if(pattern %in% c("", NA)) {
             pattern <- x1
         }else{
             pattern <- paste(pattern, x1, sep="|")
        }
   }
   x <- separate_text(txt, pattern, column)
   if(any(nchar(x$match) >= operon) ){
      a1 <- tolower(substr(x$match, 1,3))
      a2 <- strsplit(substring(x$match, 4), "")
      y <- mapply(paste0, a1, a2)
      n <- sapply(y, length)
      x <- dplyr::bind_cols(gene = unlist(y), x[ rep(1:nrow(x), n), ])
   }else{
      x$gene <- paste0(tolower(substr(x$match, 1,1)), substring(x$match, 2))
      x <- x[, c(6,1:5)]
   }
   x
}
