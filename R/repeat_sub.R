#' Repeat table subheadings
#'
#' Repeat table subheadings in a new column
#'
#' Identifies subheadings in a data frame by checking for rows with a non-empty
#' first column and all other columns are empty. Removes subheader rows and
#' repeats values down a new column.
#'
#' @param x a tibble with subheadings
#' @param column new column name, default subheading
#' @param first add subheader as first column, default TRUE
#'
#' @return a tibble
#'
#' @author Chris Stubben
#'
#' @examples
#' x <- data.frame(genes=c("Up", "aroB", "glnP", "Down", "ndhA","pyrF"),
#'    fold_change=c(NA,2.5,1.7, NA,-3.1, -2.6))
#' x
#' repeat_sub(x)
#' repeat_sub(x, "regulated", first=FALSE)
#' @export

repeat_sub <- function(x, column="subheading", first =TRUE){
   if(!is.data.frame(x)){
       stop("x should be a table")
   }
   if(ncol(x) == 1){
        message("Only one column in table")
   }else{
      ## columns 2 to ncol(x) should be empty
      ## \u00A0 is non-breaking space
      n <- apply(x[,-1, FALSE], 1,
             function(z) all(is.na(z) | z == "NA"| z == ""| z == "\u00A0"))
      if(sum(n) == 0){
         message("No subheaders found")
      }else if( sum(diff(which(n)) == 1) > 1){
         ## check for consecutive subheaders (and then probably not subheaders)
         ## SEE PMC3334355
         message("Too many subheaders in consecutive rows")
      }else if(which(n)[1] != 1){
         message("No subheader in row 1")
      }else{
         # keep copy of original table
         y <- x
          ## add unlist()  for tibbles
         x[[column]] <- rep(unlist(x[n,1]), times= diff(c(which(n), nrow(x)+1)))
         # drop rows with subheader only
         y <- x[!n,]
         # rownames(y)<-NULL
         y <- suppressMessages( readr::type_convert(y))
         if(first) y <- y[, c( ncol(y), seq_len(ncol(y)-1)) ]
         x <- y
      }
   }
   x
}
