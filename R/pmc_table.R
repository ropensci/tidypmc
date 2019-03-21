#' Convert table nodes to tibbles
#'
#' Convert PMC XML table nodes into a list of tibbles
#'
#' @param doc \code{xml_document} from PMC
#'
#' @return a list of tibbles
#'
#' @note Saves the caption and footnotes as attributes and collapses multiline headers,
#' expands all rowspan and colspan attributes and adds
#' subheadings to column one.
#'
#' @author Chris Stubben
#'
#' @examples
#' # doc <- europepmc::epmc_ftxt("PMC2231364")
#' doc <- read_xml(system.file("extdata/PMC2231364.xml", package = "tidypmc"))
#' x <- pmc_table(doc)
#' sapply(x, dim)
#' x
#' attributes(x[[1]])
#'
#' @export

pmc_table  <- function(doc){
   z  <- xml_find_all(doc, "//table-wrap")
   if (length(z) == 0) {
      message("No tables found")
      tbls <- NULL
   }else{
      tbl_nodes <- xml_find_all(z, "./table")
      ## some table tags are missing
      ## SEE https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2211553/table/ppat-0040009-t001/
      if(length(tbl_nodes)==0){
         message("Found ", length(z), " /table-wrap tags")
         message(" No /table tags found - possible link to image?")
         tbls <- NULL
      }else{
        message("Found ", length(z), " tables")
        tbls <- lapply(tbl_nodes, function(t1){
           #PARSE HEADER
           x <- xml_find_all(t1, ".//thead/tr")
           # cat(as.character(x))
           ## missing header
           if(length(x) == 0){
              thead<-NA
           ## 1 header row...
           }else if(length(x) == 1 ){
              colspan <- as.numeric( xml_attr( xml_find_all(x, ".//td|.//th"), "colspan", default="1"))
              thead <- xml_text( xml_find_all(x, ".//td|.//th"))
              # repeat across colspan
              if( any(colspan>1) ){
                thead <- make.unique(rep(thead, colspan))
              }
           # mutliline header - collapse into single row
           # SEE  tables 1 and 2 in https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3109299
           }else{
               nr <- length(x)
               c2 <- data.frame()
               for (i in 1:nr){
                  rowspan <- as.numeric( xml_attr( xml_find_all(x[[i]], ".//td|.//th"), "rowspan", default="1"))
                  colspan <- as.numeric( xml_attr( xml_find_all(x[[i]], ".//td|.//th"), "colspan", default="1"))
                  thead <- xml_text( xml_find_all(x[[i]], ".//td|.//th"))
                  if( any(colspan>1) ){
                     thead   <- rep(thead, colspan)
                     rowspan <- rep(rowspan, colspan)
                  }
                  ## create empty data.frame
                  if(i == 1){
                     nc <- length(thead)
                     c2 <- data.frame(matrix(NA, nrow = nr , ncol =  nc ))
                  }
                  # fill values into empty cells
                  n <- which(is.na(c2[i,]))
                  ## truncate to avoid warning - see PMC3119406
                  if(length(thead ) != length(n) )  thead <- thead[1: length(n) ]
                  c2[ i ,n] <- thead
                  if( any(rowspan > 1) ){
                     for(j in 1:length( rowspan ) ){
                        if(rowspan[j] > 1){
                           ## repeat value down column
                           c2[ (i+1):(i+ ( rowspan[j] -1) ) , n[j] ]   <- thead[j]
                        }
                     }
                  }
               }
               ## COLLAPSE into single row...
               ## some rowspans may extend past nr!  see table 1 PMC3109299
               if(nrow(c2) > nr) c2<- c2[1:nr, ]
                  ## collapsing column names and row values uses ";" as separator
                  thead <- apply(c2, 2, function(x) paste(unique(x), collapse=": "))
                  thead <- gsub(": : ", ": ", thead)  # some mutliline rows with horizontal lines only
                  thead <- gsub("^: ", "", thead)
                  thead <- gsub(": $", "", thead)
               }
            #--------------------------------------------------------------------
            #PARSE TABLE
            ## Do not repeat values with colspans across rows (usually table subheaders)
            ## Repeats values with rowspan down columns  - since single rows are often needed

            x <- xml_find_all(t1, ".//tbody/tr")
            # number of rows
            nr <- length(x)
            for (i in 1:nr){
               ## some table use //th  see table1 PMC3031304
               rowspan <- as.numeric( xml_attr( xml_find_all(x[[i]], ".//td|.//th"), "rowspan", default="1"))
               colspan <- as.numeric( xml_attr( xml_find_all(x[[i]], ".//td|.//th"), "colspan", default="1"))
               val <- xml_text( xml_find_all(x[[i]], ".//td|.//th"))
               val <- gsub("\u00A0|\u2002|\u2003", " ", val)  # NO-BREAK, EN or EM SPACE
               val <- gsub("^ +| +$", "", val)  # trim

               if(any(colspan > 1) ){
                  val  <- rep(val, colspan)
                  ##  only display subheader in column 1?
                  val[-1][val[-1] == val[-length(val)]] <- NA
                  rowspan <- rep(rowspan, colspan)
               }

               # not sure how to get # columns? - could check header if present ... length(thead)
               # OR  check every row (but some rows may have extra columns)
               # nc <- max( sapply(x, function(y) sum( xpathSApply(y, ".//td", xmlGetAttr, "colspan", 1)) ) )
               # this just uses # columns IN first row
               ## create empty data.frame
               if(i == 1){
                  nc <- length(val)
                     c2 <- data.frame(matrix(NA, nrow = nr , ncol =  nc ))
                  }

               # fill values into empty cells
               n <- which(is.na(c2[i,]))

               # some tables have extra td tags  see table 2  PMC3109299
               # <td align="left" rowspan="1" colspan="1"/>
               # truncate to avoid warning.... may lose data???
               if(length(val) != length(n) )  val<-val[1: length(n) ]
               c2[ i ,n] <- val
               if( any(rowspan > 1) ){
                     for(j in 1:length( rowspan ) ){
                        if(rowspan[j] > 1){
                        ## repeat value down column
                        c2[ (i+1):(i+ ( rowspan[j] -1) ) , n[j] ]   <- val[j]
                     }
                  }
               }
            }
         x <- c2
         if( !is.na( thead[1] )){
             ## see table 3 from PMC3020393  -more colnames than columns
             colnames(x) <- thead[1:ncol(x)]
         }
         #DELETE empty rows  -
         if(nrow(x)>1){
            nX <- apply(x, 1, function(y) sum(! (is.na(y) | y=="") ))
            x  <- x[nX != 0,, FALSE]   # use FALSE in case only 1 column in TABLE
         }
         # FIX column typess
         ## errors if newlines and tabs in cells (or colnames!)
         colnames(x) <- gsub("\n *", "", colnames(x))
         x <- tibble::as_tibble(x)
         x <- suppressMessages(repeat_sub(x))
         x
      })
      #----------------------------------------------------
      ## should have label and caption?
      f1 <- sapply(z, function(x) xml_text(xml_find_first(x, "./label")))
      f2 <- sapply(z, function(x) xml_text(xml_find_first(x, "./caption")))

      # check length... some table-wrap with more than 1 /table tag
      if(length(f1) == length(tbls)) names(tbls) <- f1
      else{message("Number of /table nodes is not the sampe as /table-wrap")}
      if(length(f2) == length(tbls)){
         for(i in 1:length(tbls))
         attr(tbls[[i]], "caption") <- f2[i]
      }
      ## footnotes
      fn <- sapply(z, function(x) xml_text(xml_find_first(x, "./table-wrap-foot")))
      n <- which(!is.na(fn))
      if(length(n) > 0){
         message("Adding footnotes to Table ", paste(n, collapse=","))
         for(i in n){
            attr(tbls[[i]], "footnotes") <- fn[i]
         }
      }
    }
  }
  tbls
}
