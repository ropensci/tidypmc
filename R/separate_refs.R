#' Separate references cited into multiple rows
#'
#' Separates references cited in brackets or parentheses into multiple rows and splits
#' the comma-delimited numeric strings and expands ranges like 7-9 into new rows
#'
#' @param txt a table
#' @param column column name, default "text"
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

separate_refs <- function(txt, column = "text"){
   pattern="(\\(|\\[)[0-9, -]+(\\]|\\))"
   x <- separate_text(txt, pattern, column)
    # remove any parentheses, spaces and brackets
   y <- gsub("[)( ]|\\]|\\[", "", x$match)
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
