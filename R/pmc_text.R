#' Split section paragraphs into sentences
#'
#' Split section paragraph tags into a table with subsection titles and
#' sentences using \code{tokenize_sentences}
#'
#' @param doc \code{xml_document} from PubMed Central
#'
#' @return a tibble with section, paragraph and sentence number and text
#'
#' @note Subsections may be nested to arbitrary depths and this function will
#' return the entire path to the subsection title as a delimited string like
#' "Results; Predicted functions; Pathogenicity".  Tables, figures and
#' formulas that are nested in section paragraphs are removed, superscripted
#' references are replaced with brackets, and any other superscripts or
#' subscripts are separared with ^ and _.
#'
#' @author Chris Stubben
#'
#' @examples
#' # doc <- pmc_xml("PMC2231364")
#' doc <- xml2::read_xml(system.file("extdata/PMC2231364.xml",
#'   package = "tidypmc"
#' ))
#' txt <- pmc_text(doc)
#' txt
#' dplyr::count(txt, section, sort = TRUE)
#' @export

pmc_text <- function(doc) {
  if (class(doc)[1] != "xml_document") {
    stop("doc should be an xml_document from PubMed Central")
  }
  ## create new document to remove nodes
  doc2 <- xml2::xml_new_root(doc)
  z <- vector("list")
  ## Main title
  t1 <- xml2::xml_text(xml2::xml_find_first(
    doc2, "//front//article-title"
  ), trim = TRUE)
  if (!is.na(t1)) z[["Title"]] <- t1
  ## Abstract
  a1 <- xml2::xml_text(xml2::xml_find_all(
    doc2, "//abstract[not(@abstract-type='summary')]//p"
  ))
  if (length(a1) > 0) z[["Abstract"]] <- a1

  ## Author summary
  author_sum <- xml2::xml_text(xml2::xml_find_all(
    doc2, "//abstract[@abstract-type='summary']/title"
  ))
  if (length(author_sum) > 0) {
    z[[author_sum]] <- xml2::xml_text(xml2::xml_find_all(
      doc2, "//abstract[@abstract-type='summary']//p"
    ))
  }
  if (length(z) == 0) {
    message("No title or abstract found. Not a PMC XML document?")
    x <- NULL
  } else {
    ## check for tables, figures, formula within <sec/p> tags
    n <- xml2::xml_find_all(doc2, "//sec/p/table-wrap")
    if (length(n) > 0) {
      message("Note: removing table-wrap nested in sec/p tag")
      xml2::xml_remove(n)
    }
    n <- xml2::xml_find_all(doc2, "//sec/p/fig")
    if (length(n) > 0) {
      message("Note: removing fig nested in sec/p tag")
      xml2::xml_remove(n)
    }
    # formulas may include very long MathType encoding strings
    n <- xml2::xml_find_all(doc2, "//sec/p/disp-formula")
    if (length(n) > 0) {
      message("Note: removing disp-formula nested in sec/p tag")
      xml2::xml_remove(n)
    }
    # DROP any sections with supplementary materials (often with nested
    # sections missing titles)
    n <- xml2::xml_find_all(
      doc2, "//body//sec[@sec-type='supplementary-material']"
    )
    if (length(n) > 0) xml2::xml_remove(n)
    ## Add brackets to numbered references with superscript tags
    add_bracket <- FALSE
    bib <- xml2::xml_find_all(doc2, "//sup//xref[@ref-type='bibr']")
    if (length(bib) > 0) {
      message("Adding brackets to numbered references in /sup tags")
      add_bracket <- TRUE
      xml2::xml_text(bib) <- paste0(" [", xml2::xml_text(bib), "]")
    }
    ## Add ^ and _ to /sup and /sub tags
    sup <- xml2::xml_find_all(doc2, "//sup[not(xref)]")
    if (length(sup) > 0) {
      xml2::xml_text(sup) <- paste0("^", xml2::xml_text(sup))
    }
    subs <- xml2::xml_find_all(doc2, "//sub")
    if (length(subs) > 0) {
      xml2::xml_text(subs) <- paste0("_", xml2::xml_text(subs))
    }

    ## parse text from Sections
    sec <- xml2::xml_find_all(doc2, "//body//sec")
    if (length(sec) == 0) {
      message("NOTE: No sections found, using all text in main body/p")
      z[["[Main]"]] <- xml2::xml_text(xml2::xml_find_all(doc2, "//body/p"))
    } else {
      ## Emerging infectious diseases has both body/p and body/sec
      intro <- xml2::xml_text(xml2::xml_find_all(doc2, "//body/p"))
      if (length(intro) > 0) {
        message(
          "NOTE: Body has both /p and /sec tags - untitled Introduction?"
        )
        z[["[Introduction]"]] <- xml2::xml_text(
          xml2::xml_find_all(doc2, "//body/p")
        )
      }
      # /sec should have both title and p?
      t1 <- xml2::xml_text(xml2::xml_find_all(doc2, "//body//sec/title"))
      # fix sections without title  ... PMC6360207
      if ("" %in% t1) {
        message("Missing ", sum(t1 == ""), " title in sec/p tag")
        t1[t1 == ""] <- "[untitled sec/p]"
      }
      ## indentation level of subsections
      n <- stringr::str_count(xml2::xml_path(
        xml2::xml_find_all(doc2, "//body//sec/title")
      ), "/")
      ## full path to subsection title
      path <- path_string(t1, n)
      ## section paragraphs (get sec/p and not any //p)
      secP <- lapply(sec, function(x) xml2::xml_text(
          xml2::xml_find_all(x, "./p")
        ))
      if (length(path) != length(secP)) {
        message("Warning: some sections are missing /title tags")
      }
      minP <- min(length(path), length(secP))
      ## LOOP through subsections and skip sections missing /p tags
      for (i in seq_len(minP)) {
        subT <- path[i]
        subT <- gsub("\\.$", "", subT)
        # in case of nested sec tags,  replace "; ; ; "
        subT <- gsub("[; ]{3,}", "; ", subT)
        if (length(secP[[i]]) > 0) {
          ## don't split Fig. 1 into two sentences, probably many others
          p1 <- lapply(
            secP[[i]],
            function(x) gsub("([ (][Ff]ig)\\.", "\\1", x)
          )
          z[[subT]] <- p1
        }
      }
    }
    x <- lapply(z, tokenizers::tokenize_sentences)
    x1 <- lapply(x, function(y) dplyr::bind_rows(
        lapply(y, function(z) if (length(z) > 0) {
            tibble::tibble(sentence = seq_along(z), text = z)
          }),
        .id = "paragraph"
      ))
    x <- dplyr::bind_rows(x1, .id = "section")
    x <- dplyr::mutate(x, paragraph = as.integer(paragraph))
    # replace en dash, em dash, etc to separate ranges
    x$text <- gsub("\u2011|\u2012|\u2013|\u2014", "-", x$text)
    ## FIX if brackets added to superscripted references
    if (add_bracket) x$text <- gsub("]- [", "-", x$text, fixed = TRUE)
  }
  x
}
