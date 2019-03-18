#' Collapse a list of PMC tables
#'
#' Collapses rows into a semi-colon delimited list with column names and cell values
#'
#' @param pmc a list of tables from \code{\link{pmc_table}}
#' @param na.string  additional cell values to skip, default is NA and ""
#'
#' @return A tibble with table and row number and collapsed text
#'
#' @author Chris Stubben
#'
#' @examples
#' x <- data.frame(genes=c("Up", "aroB", "glnP", "Down", "ndhA","pyrF"),
#'      fold_change=c(NA,2.5,1.7, NA,-3.1, -2.6))
#' collapse_rows(x)
#'
#' @export

collapse_rows <- function(pmc, na.string){
   if(!is.list(pmc)) pmc <- list(Table= pmc)
   n1 <- length(pmc)
   tbls <- vector("list", n1)
   names(tbls) <- names(pmc)
   for(i in 1:n1){
      x <- data.frame(pmc[[i]], check.names = FALSE)
      y <- names(x)
      n <- nrow(x)
      ## convert factors to character?
      f1 <- sapply(x, is.factor)
      if(any(f1)) for(k in which(f1)) x[,k] <- as.character(x[,k])
      # combine (and skip empty fields)
      cx <- vector("character", n)
      # TO DO - replace loop?
      for(j in 1: n ){
         n2 <- is.na(x[j,]) | as.character(x[j,]) == ""  | x[j,] == "\u00A0"
         if(!missing(na.string)  ) n2 <- n2 | as.character(x[j,] ) == na.string
         rowx <- paste(paste(y[!n2], x[j, !n2], sep="="), collapse="; ")
         cx[j] <-rowx
      }
      z <- tibble::tibble(row= 1:length(cx), text=cx)
      tbls[[i]] <- z
   }
   dplyr::bind_rows(tbls, .id="table")
}
