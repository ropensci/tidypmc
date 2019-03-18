#' Separate locus tag mentioned in full text into multiple rows
#'
#' Separates locus tags and expands ranges like YPO1970-74 into new rows
#'
#' @param txt a table
#' @param pattern regular expression to match locus tags like YPO[0-9-]+ or just
#'  the locus tag prefix like YPO.
#' @param column column name to search, default "text"
#'
#' @return a tibble with locus tag, matching text and rows.
#'
#' @author Chris Stubben
#'
#' @examples
#' x <- data.frame(row=1, text = "some genes like YPO1002 and YPO1970-74")
#' separate_tags(x, "YPO")
#'
#' @export

separate_tags <- function(txt, pattern, column = "text"){
   ## if prefix only (no numbers)  also match YPO1854-YPO1856?
   # if(!grepl("[0-9]", pattern)) pattern <- paste0(pattern, "[0-9-]+")
   if(!grepl("[0-9]", pattern)) pattern <- paste0(pattern, "[0-9", pattern, "-]+")
   x <- separate_text(txt, pattern, column)
   ## avoid YPO1854-YPO1856-YPO1858
   if(any(str_count(x$match, "-") > 1)) stop("pattern matches 3 or more tags")
   if(any(grepl("-$", x$match))) x$match <- gsub("-$", "", x$match)
   # Expand range if matching "-"
   y <- lapply(x$match, function(id){
      if(grepl("-", id)){
         pre <- stringr::str_extract(id, "^[^0-9]+")
         ## split range
         x <- strsplit(gsub("[^0-9-]", "", id), "-")[[1]]
         n <- nchar(x[1])
         x <- as.numeric(x)
         ## check if 2nd number is less than 1st... YPO1970-80
         if(x[2] < x[1]) x[2] <- paste0(substring(x[1], 1, nchar(x[1])- nchar(x[2])), x[2])
         id <- seq(x[1],x[2])
         id <- stringr::str_pad(id, n, pad="0")
         id <- paste0(pre, id)
      }
      id
   })
   n <- sapply(y, length)
   dplyr::bind_cols( id = unlist(y), x[ rep(1:nrow(x), n), ])
}
