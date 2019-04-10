#' Separate all matching text into multiple rows
#'
#' @param txt a tibble, usually results from \code{pmc_text}
#' @param pattern either a regular expression or a vector of words to find in
#' text
#' @param column column name, default "text"
#'
#' @return a tibble
#'
#' @note passed to \code{grepl} and \code{str_extract_all}
#'
#' @author Chris Stubben
#'
#' @examples
#' # doc <- europepmc::epmc_ftxt("PMC2231364")
#' doc <- xml2::read_xml(system.file("extdata/PMC2231364.xml",
#'         package = "tidypmc"))
#' txt <- pmc_text(doc)
#' separate_text(txt, "[ATCGN]{5,}")
#' separate_text(txt, "\\([A-Z]{3,6}s?\\)")
#' # pattern can be a vector of words
#' separate_text(txt, c("hmu", "ybt", "yfe", "yfu"))
#' # wrappers for separate_text with extra step to expand matched ranges
#' separate_refs(txt)
#' separate_genes(txt)
#' separate_tags(txt, "YPO")
#'
#' @export

separate_text <- function(txt, pattern, column = "text"){
   if(!is.data.frame(txt)) stop("txt should be a tibble")
   if(!column %in% names(txt)) stop("column ", column, " is not found in table")
   ## paste words into | delimited string with word boundaries
   if(length(pattern) > 1){
       pattern <- paste0("\\b", paste(pattern, collapse = "\\b|\\b"), "\\b")
   }
   x <- dplyr::filter(txt, grepl(pattern, txt[[column]]))
   if(nrow(x) == 0){
      message("No match to ", pattern)
      txt2 <- NULL
   }else{
      y <- stringr::str_extract_all(x[[column]], pattern)
      y <- lapply(y, unique)
      n <- vapply(y, length, integer(1))
      txt2 <- dplyr::bind_cols(match = unlist(y), x[rep(seq_len(nrow(x)), n),])
   }
   txt2
}
