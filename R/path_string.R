#' Print a hierarchical path string
#'
#' Print a hierarchical path string from a vector of names and levels
#'
#' @param x a vector of names
#' @param n a vector of numbers with indentation level
#'
#' @return a character vector
#'
#' @note Used by \code{\link{pmc_text}} to print full path to subsection title
#'
#' @author Chris Stubben
#'
#' @examples
#' x <- c("carnivores", "bears", "polar", "grizzly", "cats", "tiger", "rodents")
#' n <- c(1,2,3,3,2,3,1)
#' path_string(x, n)
#'
#' @export

path_string<-function(x,n){
   n2 <- length(n)
   if(is.factor(x)) x <- as.character(x)
   if(!is.numeric(n)) stop("n should be a vector of numbers")
   if(n2 != length(x)) stop("x and n should be the same length")
   z <- vector("list", n2)
   if(min(n) > 1) n <- n - min(n) + 1
   ## start with empty vector
   path <- ""
   for(i in seq_len(n2)){
      ## add name at position n[i]
      path[n[i]] <- x[i]
      ## drop names if n[i] decreases
      path <- path[seq_len(n[i])]
      ### paste together names
      z[[i]] <- paste(path, collapse="; ")
   }
   z  <- unlist(z)
   ## check if any NA?
   z <- gsub("NA; ", "", z)
   z
}
