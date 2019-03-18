#' \code{tidypmc} package
#'
#' Parse full text XML documents from PMC
#'
#' See the Github page for details at \url{https://github.com/cstubben/tidypmc}
#'
#' @docType package
#' @name tidypmc
#' @importFrom dplyr %>%
#' @import xml2
#' @keywords internal
NULL

##  R CMD check error from https://github.com/jennybc/googlesheets/blob/master/R/googlesheets.R
if(getRversion() >= "2.15.1")  utils::globalVariables(c("paragraph"))
