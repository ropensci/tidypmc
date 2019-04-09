#' Convert table nodes to tibbles
#'
#' Convert PMC XML table nodes into a list of tibbles
#'
#' @param doc \code{xml_document} from PMC
#'
#' @return a list of tibbles
#'
#' @note Saves the caption and footnotes as attributes and collapses multiline
#' headers, expands all rowspan and colspan attributes and adds
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
   if(class(doc)[1] != "xml_document"){
        stop("doc should be an xml_document from PMC")
   }
   twn  <- length(xml_find_all(doc, "//table-wrap"))
   ## Avoid table-wrap without table node .. link to image only
   z  <- xml_find_all(doc, "//table-wrap/table/..")
   if (length(z) == 0) {
      message("No tables found")
      if(twn > 0) message("Table-wrap with link to image?")
      tbls <- NULL
   }else{
        tbl_nodes <- xml_find_all(z, "./table")
        message("Parsing ", length(z), " tables")
        if(twn > length(z)){
            message(twn-length(n), " /table-wrap with link to image?")
        }
        ## START table function
        #  t1 <- xml_find_all(doc, "//table")[1]
        tbls <- lapply(tbl_nodes, function(t1){
           #PARSE HEADER
           x <- xml_find_all(t1, ".//thead/tr")
           # cat(as.character(x))
           ## missing header
           if(length(x) == 0){
              thead<-NA
           ## 1 header row...
           }else if(length(x) == 1 ){
              colspan <- as.numeric( xml_attr(
                     xml_find_all(x, ".//td|.//th"), "colspan", default="1"))
              thead <- xml_text( xml_find_all(x, ".//td|.//th"))
              # repeat across colspan
              if( any(colspan>1) ){
                thead <- rep(thead, colspan)
              }
           # mutliline header - collapse into single row
           # SEE  tables 1 and 2 in PMC3109299
           }else{
               nr <- length(x)
               nc <- max(vapply(x, function(y) sum(as.numeric( xml_attr(
                     xml_find_all(y, ".//td|.//th"), "colspan", default="1"))),
                       double(1)))
               c2 <- data.frame(matrix(NA, nrow = nr , ncol =  nc ))
               for (i in seq_len(nr)){
                  rowspan <- as.numeric( xml_attr(
                   xml_find_all(x[[i]], ".//td|.//th"), "rowspan", default="1"))
                  colspan <- as.numeric( xml_attr(
                   xml_find_all(x[[i]], ".//td|.//th"), "colspan", default="1"))
                  thead <- xml_text( xml_find_all(x[[i]], ".//td|.//th"))
                  if( any(colspan>1) ){
                     thead   <- rep(thead, colspan)
                     rowspan <- rep(rowspan, colspan)
                  }
                  # fill values into empty cells
                  n <- which(is.na(c2[i,]))
                  ## truncate to avoid warning - see PMC3119406
                  if(length(thead) != length(n)) thead <- thead[seq_along(n)]
                  c2[ i ,n] <- thead
                  if( any(rowspan > 1) ){
                     for(j in seq_along(rowspan)){
                        if(rowspan[j] > 1){
                           ## repeat value down column
                           c2[(i+1):(i+ (rowspan[j] -1)), n[j]] <- thead[j]
                        }
                     }
                  }
               }
               ## COLLAPSE into single row...
               ## some rowspans may extend past nr!  see table 1 PMC3109299
               if(nrow(c2) > nr) c2<- c2[seq_len(nr), ]
                  ## collaps3 column names and row values uses ";" as separator
                  thead <- apply(c2, 2, function(x)
                                        paste(unique(x), collapse=": "))
                   # some mutliline rows with horizontal lines only
                  thead <- gsub(": : ", ": ", thead)
                  thead <- gsub("^: ", "", thead)
                  thead <- gsub(": $", "", thead)
               }
            #-------------------------------------------------------------------
            #PARSE TABLE
            # Do not repeat values with colspans across rows (usually table
            # subheaders). Repeats values with rowspan down columns  - since
            # single rows are often needed

            x <- xml_find_all(t1, ".//tbody/tr")
            # number of rows
            nr <- length(x)
            nc <- max(vapply(x, function(y) sum(as.numeric(xml_attr(
                  xml_find_all(y, ".//td|.//th"), "colspan", default="1"))),
                    double(1)))
            c2 <- data.frame(matrix(NA, nrow = nr , ncol =  nc ))

            for (i in seq_len(nr)){
               ## some table use //th  see table1 PMC3031304
               rowspan <- xml_attr(
                  xml_find_all(x[[i]], ".//td|.//th"), "rowspan", default="1")
               colspan <- xml_attr(
                  xml_find_all(x[[i]], ".//td|.//th"), "colspan", default="1")
              # PMC6358641 with rowspan=""
               rowspan <- as.numeric( ifelse(rowspan=="", 1, rowspan))
               colspan <- as.numeric( ifelse(colspan=="", 1, colspan))
               val <- xml_text( xml_find_all(x[[i]], ".//td|.//th"))
                 # NO-BREAK, EN or EM SPACE
               val <- gsub("\u00A0|\u2002|\u2003", " ", val)
               val <- trimws(val)

               if(any(colspan > 1) ){
                  val  <- rep(val, colspan)
                  ##  only display subheader in column 1?
                  val[-1][val[-1] == val[-length(val)]] <- NA
                  rowspan <- rep(rowspan, colspan)
               }
               # fill values into empty cells
               n <- which(is.na(c2[i,]))

               # some tables have extra td tags  see table 2  PMC3109299
               # <td align="left" rowspan="1" colspan="1"/>
               # truncate to avoid warning??
               if(length(val) != length(n) ){
                  val<-val[seq_along(n) ]
                  }
               c2[ i ,n] <- val
               if( any(rowspan > 1) ){
                     for(j in seq_along(rowspan)){
                        if(rowspan[j] > 1){
                        ## repeat value down column
                        c2[ (i+1):(i+ ( rowspan[j] -1) ), n[j] ]   <- val[j]
                     }
                  }
               }
            }
         x <- c2
         #-------------------------------------

         if(!is.na( thead[1] )){
             thead[thead==""] <- "X"
             tbn <- ncol(x)
             thn <- length(thead)
             if(tbn != thn){
          message("Warning: number of column in /thead and /tbody do not match")
                if(tbn > thn ){
                  thead <- append(thead, rep("X", tbn-thn ))
                 }else{
                 ## see table 3 from PMC3020393
                  thead <- thead[seq_len(tbn)]
                }
             }
             thead <- gsub("\n", " ", thead)
             thead <- make.unique(thead)
             colnames(x) <- thead
         }
         #DELETE empty rows  -
         if(nrow(x) > 1){
            nX <- apply(x, 1, function(y) sum(! (is.na(y) | y=="") ))
            x  <- x[nX != 0,, FALSE]  # use FALSE in case only 1 column in TABLE
         }
         # FIX column typess
         ## errors if newlines and tabs in cells (or colnames!)
         colnames(x) <- gsub("\n *", "", colnames(x))
         x <- tibble::as_tibble(x)
         x <- suppressMessages(repeat_sub(x))
         x
      })
      ### END table functino
      #----------------------------------------------------
      ## should have label and caption?
      f1 <- vapply(z, function(x) xml_text(
             xml_find_first(x, "./label")), character(1))
      f2 <- vapply(z, function(x) xml_text(
             xml_find_first(x, "./caption")), character(1))

      # check length... some table-wrap with more than 1 /table tag
      if(length(f1) == length(tbls)){
         names(tbls) <- f1
      }
      else{
          message("Number of /table nodes is not the sampe as /table-wrap")
       }
      if(length(f2) == length(tbls)){
         for(i in seq_along(tbls))
         attr(tbls[[i]], "caption") <- f2[i]
      }
      ## footnotes
      fn <- vapply(z, function(x)
             xml_text(xml_find_first(x, "./table-wrap-foot")), character(1))
      n <- which(!is.na(fn))
      if(length(n) > 0){
         message("Adding footnotes to Table ", paste(n, collapse=","))
         for(i in n){
            attr(tbls[[i]], "footnotes") <- fn[i]
         }
      }
  }
  tbls
}
