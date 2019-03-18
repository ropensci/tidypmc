#' Separate references cited in full text into multiple rows
#'
#' Separates comma-delimited numeric strings and expands ranges like 7-9 into new rows
#'
#' @param txt a table
#' @param pattern regular expression to match references, default "\\[[0-9, -]+\\]"
#' @param column column name, default "match"
#'
#' @return a tibble
#'
#' @author Chris Stubben
#'
#' @examples
#' x <- data.frame(row=1, text = "some important studies [7-9,15]")
#' separate_refs(x)
#'
#' @export

separate_refs <- function(txt, pattern="\\[[0-9, -]+\\]", column = "text"){
   x <- separate_text(txt, pattern, column)
    # remove brackets or extra spaces
   y <- gsub("\\[|\\]| ]+", "", x$match)
   ## split commas
   y <- strsplit(y,",")
   ## split ranges
   z <- lapply(y, strsplit, "-")
   ## apply seq if length is 2
   y <- lapply(z, function(x) unlist(
          lapply(x, function(x1)
            if(length(x1)==2) seq(x1[1],x1[2]) else as.numeric(x1))))
   n <- sapply(y, length)
   dplyr::bind_cols( id = unlist(y), x[ rep(1:nrow(x), n), ])
}
