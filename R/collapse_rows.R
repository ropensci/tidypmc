#' Collapse a list of PubMed Central tables
#'
#' Collapse rows into a semi-colon delimited list with column names and cell
#' values
#'
#' @param pmc a list of tables, usually from \code{\link{pmc_table}}
#' @param na.string  additional cell values to skip, default is NA and ""
#'
#' @return A tibble with table and row number and collapsed text
#'
#' @author Chris Stubben
#'
#' @examples
#' x <- data.frame(
#'   genes = c("aroB", "glnP", "ndhA", "pyrF"),
#'   fold_change = c(2.5, 1.7, -3.1, -2.6)
#' )
#' collapse_rows(list(`Table 1` = x))
#' @export

collapse_rows <- function(pmc, na.string) {
  if (is.null(pmc)) {
    cr1 <- NULL
  } else {
    if (class(pmc)[1] != "list") pmc <- list(Table = pmc)
    if (!is.data.frame(pmc[[1]])) {
      stop("pmc should be a list of tables from pmc_table")
    }
    n1 <- length(pmc)
    tbls <- vector("list", n1)
    names(tbls) <- names(pmc)
    for (i in seq_len(n1)) {
      x <- data.frame(pmc[[i]], check.names = FALSE)
      y <- names(x)
      n <- nrow(x)
      if (nrow(x) == 0) {
        tbls[[i]] <- NULL
      } else {
        ## convert factors to character
        f1 <- vapply(x, is.factor, logical(1))
        if (any(f1)) for (k in which(f1)) x[, k] <- as.character(x[, k])
        # combine (and skip empty fields)
        cx <- vector("character", n)
        for (j in seq_len(n)) {
          n2 <- is.na(x[j, ]) | as.character(x[j, ]) == "" | x[j, ] == "\u00A0"
          if (!missing(na.string)) n2 <- n2 | as.character(x[j, ]) == na.string
          rowx <- paste(paste(y[!n2], x[j, !n2], sep = "="), collapse = "; ")
          cx[j] <- rowx
        }
        z <- tibble::tibble(row = seq_along(cx), text = cx)
        tbls[[i]] <- z
      }
    }
    cr1 <- dplyr::bind_rows(tbls, .id = "table")
  }
  cr1
}
