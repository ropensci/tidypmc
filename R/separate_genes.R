#' Separate genes and operons mentioned in full text into multiple rows
#'
#' @param txt a table
#' @param pattern regular expression to match genes, default is to match microbial
#' genes like AbcD, default [A-Za-z][a-z]{2}[A-Z]+
#' @param genes an optional vector of genes, set pattern to NA to only match this list.
#' @param column column name to search, default "text"
#'
#' @return a tibble with gene name, matching text and rows.
#'
#' @author Chris Stubben
#'
#' @examples
#' x <- data.frame(row=1, text = "Genes like YacK, hmu and sufABC")
#' separate_genes(x)
#' separate_genes(x, genes="hmu")
#'
#' @export

separate_genes <- function(txt, pattern="\\b[A-Za-z][a-z]{2}[A-Z]+\\b", genes, column = "text"){
   if(!missing(genes)){
         x1 <- paste0("\\b", paste(genes, collapse = "\\b|\\b"), "\\b")
         if(pattern %in% c("", NA)) {
             pattern <- x1
         }else{
             pattern <- paste(pattern, x1, sep="|")
        }
   }
   x <- separate_text(txt, pattern, column)
   a1 <- tolower(substr(x$match, 1,3))
   a2 <- strsplit(substring(x$match, 4), "")
   y <- mapply(paste0, a1, a2)
   n <- sapply(y, length)
   dplyr::bind_cols(gene = unlist(y), x[ rep(1:nrow(x), n), ])
}
