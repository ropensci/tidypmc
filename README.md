
[![Build Status](https://travis-ci.org/ropensci/tidypmc.svg?branch=master)](https://travis-ci.org/ropensci/tidypmc) [![Coverage status](https://codecov.io/gh/ropensci/tidypmc/branch/master/graph/badge.svg)](https://codecov.io/github/ropensci/tidypmc?branch=master) [![](https://badges.ropensci.org/290_status.svg)](https://github.com/ropensci/software-review/issues/290)

tidypmc
=======

The [Open Access subset](https://europepmc.org/downloads/openaccess) of [Pubmed Central](https://europepmc.org) (PMC) includes 2.5 million articles from biomedical and life sciences journals. The full text XML files are freely available for text mining from the [REST service](https://europepmc.org/RestfulWebService) or [FTP site](https://europepmc.org/ftp/oa/) but can be challenging to parse. For example, section tags are nested to arbitrary depths, formulas and tables may return incomprehensible text blobs and superscripted references are pasted at the end of words. The functions in the `tidypmc` package are intended to return readable text and maintain the document structure, so gene names and other terms can be associated with specific sections, paragraphs, sentences or table rows.

Installation
------------

Use [remotes](https://github.com/r-lib/remotes) to install the package.

``` r
remotes::install_github("ropensci/tidypmc")
```

Load XML
--------

Download a single XML document like [PMC2231364](https://www.ebi.ac.uk/europepmc/webservices/rest/PMC2231364/fullTextXML) from the [REST service](https://europepmc.org/RestfulWebService) using the `pmc_xml` function.

``` r
library(tidypmc)
library(tidyverse)
doc <- pmc_xml("PMC2231364")
doc
#  {xml_document}
#  <article article-type="research-article" xmlns:xlink="http://www.w3.org/1999/xlink">
#  [1] <front>\n  <journal-meta>\n    <journal-id journal-id-type="nlm-ta">BMC Microbiol</journal-id ...
#  [2] <body>\n  <sec>\n    <title>Background</title>\n    <p><italic>Yersinia pestis </italic>is th ...
#  [3] <back>\n  <ack>\n    <sec>\n      <title>Acknowledgements</title>\n      <p>We thank Dr. Chen ...
```

The [europepmc](https://github.com/ropensci/europepmc) package includes additional functions to search PMC and download full text. Be sure to include the `OPEN_ACCESS` field in the search since these are the only articles with full text XML available.

``` r
library(europepmc)
yp <- epmc_search("title:(Yersinia pestis virulence) OPEN_ACCESS:Y")
#  19 records found, returning 19
select(yp, pmcid, pubYear, title) %>%
  print(n=5)
#  # A tibble: 19 x 3
#    pmcid      pubYear title                                                                          
#    <chr>      <chr>   <chr>                                                                          
#  1 PMC5505154 2017    Crystal structure of Yersinia pestis virulence factor YfeA reveals two polyspe…
#  2 PMC3521224 2012    Omics strategies for revealing Yersinia pestis virulence.                      
#  3 PMC2704395 2009    Involvement of the post-transcriptional regulator Hfq in Yersinia pestis virul…
#  4 PMC2736372 2009    The NlpD lipoprotein is a novel Yersinia pestis virulence factor essential for…
#  5 PMC3109262 2011    A comprehensive study on the role of the Yersinia pestis virulence markers in …
#  # … with 14 more rows
```

Save all 19 results to a list of XML documents using the `epmc_ftxt` or `pmc_xml` function.

``` r
docs <- map(yp$pmcid, epmc_ftxt)
```

See the [PMC FTP vignette](https://github.com/ropensci/tidypmc/blob/master/vignettes/pmcftp.md) for details on parsing the large XML files on the [FTP site](https://europepmc.org/ftp/oa/) with 10,000 articles each.

Parse XML
---------

The package includes five functions to parse the `xml_document`.

<table>
<colgroup>
<col width="17%" />
<col width="82%" />
</colgroup>
<thead>
<tr class="header">
<th align="left">R function</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left"><code>pmc_text</code></td>
<td align="left">Split section paragraphs into sentences with full path to subsection titles</td>
</tr>
<tr class="even">
<td align="left"><code>pmc_caption</code></td>
<td align="left">Split figure, table and supplementary material captions into sentences</td>
</tr>
<tr class="odd">
<td align="left"><code>pmc_table</code></td>
<td align="left">Convert table nodes into a list of tibbles</td>
</tr>
<tr class="even">
<td align="left"><code>pmc_reference</code></td>
<td align="left">Format references cited into a tibble</td>
</tr>
<tr class="odd">
<td align="left"><code>pmc_metadata</code></td>
<td align="left">List journal and article metadata in front node</td>
</tr>
</tbody>
</table>

The `pmc_text` function uses the [tokenizers](https://lincolnmullen.com/software/tokenizers/) package to split section paragraphs into sentences. The function also removes any tables, figures or formulas that are nested within paragraph tags, replaces superscripted references with brackets, adds carets and underscores to other superscripts and subscripts and includes the full path to the subsection title.

``` r
txt <- pmc_text(doc)
#  Note: removing disp-formula nested in sec/p tag
txt
#  # A tibble: 194 x 4
#     section    paragraph sentence text                                                                         
#     <chr>          <int>    <int> <chr>                                                                        
#   1 Title              1        1 Comparative transcriptomics in Yersinia pestis: a global view of environment…
#   2 Abstract           1        1 Environmental modulation of gene expression in Yersinia pestis is critical f…
#   3 Abstract           1        2 Using cDNA microarray technology, we have analyzed the global gene expressio…
#   4 Abstract           2        1 To provide us with a comprehensive view of environmental modulation of globa…
#   5 Abstract           2        2 Almost all known virulence genes of Y. pestis were differentially regulated …
#   6 Abstract           2        3 Clustering enabled us to functionally classify co-expressed genes, including…
#   7 Abstract           2        4 Collections of operons were predicted from the microarray data, and some of …
#   8 Abstract           2        5 Several regulatory DNA motifs, probably recognized by the regulatory protein…
#   9 Abstract           3        1 The comparative transcriptomics analysis we present here not only benefits o…
#  10 Background         1        1 Yersinia pestis is the etiological agent of plague, alternatively growing in…
#  # … with 184 more rows
count(txt, section, sort=TRUE)
#  # A tibble: 21 x 2
#     section                                                                                                   n
#     <chr>                                                                                                 <int>
#   1 Results and Discussion; Clustering analysis and functional classification of co-expressed gene clust…    22
#   2 Background                                                                                               20
#   3 Results and Discussion; Virulence genes in response to multiple environmental stresses                   20
#   4 Methods; Collection of microarray expression data                                                        17
#   5 Results and Discussion; Computational discovery of regulatory DNA motifs                                 16
#   6 Methods; Gel mobility shift analysis of Fur binding                                                      13
#   7 Results and Discussion; Verification of predicted operons by RT-PCR                                      10
#   8 Abstract                                                                                                  8
#   9 Methods; Discovery of regulatory DNA motifs                                                               8
#  10 Methods; Clustering analysis                                                                              7
#  # … with 11 more rows
```

Load the [tidytext](https://www.tidytextmining.com/) package for further text processing.

``` r
library(tidytext)
x1 <- unnest_tokens(txt, word, text) %>%
  anti_join(stop_words) %>%
  filter(!word %in% 1:100)
#  Joining, by = "word"
filter(x1, str_detect(section, "^Results"))
#  # A tibble: 1,269 x 4
#     section                paragraph sentence word         
#     <chr>                      <int>    <int> <chr>        
#   1 Results and Discussion         1        1 comprehensive
#   2 Results and Discussion         1        1 analysis     
#   3 Results and Discussion         1        1 sets         
#   4 Results and Discussion         1        1 microarray   
#   5 Results and Discussion         1        1 expression   
#   6 Results and Discussion         1        1 data         
#   7 Results and Discussion         1        1 dissect      
#   8 Results and Discussion         1        1 bacterial    
#   9 Results and Discussion         1        1 adaptation   
#  10 Results and Discussion         1        1 environments 
#  # … with 1,259 more rows
filter(x1, str_detect(section, "^Results")) %>%
  count(word, sort = TRUE)
#  # A tibble: 595 x 2
#     word           n
#     <chr>      <int>
#   1 genes         45
#   2 cluster       24
#   3 expression    21
#   4 pestis        21
#   5 data          19
#   6 dna           15
#   7 gene          15
#   8 figure        13
#   9 fur           12
#  10 operons       12
#  # … with 585 more rows
```

The `pmc_table` function formats tables by collapsing multiline headers, expanding rowspan and colspan attributes and adding subheadings into a new column.

``` r
tbls <- pmc_table(doc)
#  Parsing 4 tables
#  Adding footnotes to Table 1
map_int(tbls, nrow)
#  Table 1 Table 2 Table 3 Table 4 
#       39      23       4      34
tbls[[1]]
#  # A tibble: 39 x 5
#     subheading              `Potential operon (r va… `Gene ID`   `Putative or predicted functi… `Reference (s)`
#     <chr>                   <chr>                    <chr>       <chr>                          <chr>          
#   1 Iron uptake or heme sy… yfeABCD operon* (r > 0.… YPO2439-24… Transport/binding chelated ir… yfeABCD [54]   
#   2 Iron uptake or heme sy… hmuRSTUV operon (r > 0.… YPO0279-02… Transport/binding hemin        hmuRSTUV [55]  
#   3 Iron uptake or heme sy… ysuJIHG* (r > 0.95)      YPO1529-15… Iron uptake                    -              
#   4 Iron uptake or heme sy… sufABCDS* (r > 0.90)     YPO2400-24… Iron-regulated Fe-S cluster a… -              
#   5 Iron uptake or heme sy… YPO1854-1856* (r > 0.97) YPO1854-18… Iron uptake or heme synthesis? -              
#   6 Sulfur metabolism       tauABCD operon (r > 0.9… YPO0182-01… Transport/binding taurine      tauABCD [56]   
#   7 Sulfur metabolism       ssuEADCB operon (r > 0.… YPO3623-36… Sulphur metabolism             ssu operon [57]
#   8 Sulfur metabolism       cys operon (r > 0.92)    YPO3010-30… Cysteine synthesis             -              
#   9 Sulfur metabolism       YPO1317-1319 (r > 0.97)  YPO1317-13… Sulfur metabolism?             -              
#  10 Sulfur metabolism       YPO4109-4111 (r > 0.90)  YPO4109-41… Sulfur metabolism?             -              
#  # … with 29 more rows
```

Use `collapse_rows` to join column names and cell values in a semi-colon delimited string (and then search using functions in the next section).

``` r
collapse_rows(tbls, na.string="-")
#  # A tibble: 100 x 3
#     table     row text                                                                                         
#     <chr>   <int> <chr>                                                                                        
#   1 Table 1     1 subheading=Iron uptake or heme synthesis; Potential operon (r value)=yfeABCD operon* (r > 0.…
#   2 Table 1     2 subheading=Iron uptake or heme synthesis; Potential operon (r value)=hmuRSTUV operon (r > 0.…
#   3 Table 1     3 subheading=Iron uptake or heme synthesis; Potential operon (r value)=ysuJIHG* (r > 0.95); Ge…
#   4 Table 1     4 subheading=Iron uptake or heme synthesis; Potential operon (r value)=sufABCDS* (r > 0.90); G…
#   5 Table 1     5 subheading=Iron uptake or heme synthesis; Potential operon (r value)=YPO1854-1856* (r > 0.97…
#   6 Table 1     6 subheading=Sulfur metabolism; Potential operon (r value)=tauABCD operon (r > 0.90); Gene ID=…
#   7 Table 1     7 subheading=Sulfur metabolism; Potential operon (r value)=ssuEADCB operon (r > 0.97); Gene ID…
#   8 Table 1     8 subheading=Sulfur metabolism; Potential operon (r value)=cys operon (r > 0.92); Gene ID=YPO3…
#   9 Table 1     9 subheading=Sulfur metabolism; Potential operon (r value)=YPO1317-1319 (r > 0.97); Gene ID=YP…
#  10 Table 1    10 subheading=Sulfur metabolism; Potential operon (r value)=YPO4109-4111 (r > 0.90); Gene ID=YP…
#  # … with 90 more rows
```

The other three `pmc` functions are described in the package [vignette](https://github.com/ropensci/tidypmc/blob/master/vignettes/tidypmc.md).

Searching text
--------------

There are a few functions to search within the `pmc_text` or collapsed `pmc_table` output. `separate_text` uses the [stringr](https://stringr.tidyverse.org/) package to extract any regular expression or vector of words.

``` r
separate_text(txt, "[ATCGN]{5,}")
#  # A tibble: 9 x 5
#    match        section                         paragraph sentence text                                        
#    <chr>        <chr>                               <int>    <int> <chr>                                       
#  1 ACGCAATCGTT… Results and Discussion; Comput…         2        3 A 16 basepair (bp) box (5'-ACGCAATCGTTTTCNT…
#  2 AAACGTTTNCGT Results and Discussion; Comput…         2        4 It is very similar to the E. coli PurR box …
#  3 TGATAATGATT… Results and Discussion; Comput…         2        5 A 21 bp box (5'-TGATAATGATTATCATTATCA-3') w…
#  4 GATAATGATAA… Results and Discussion; Comput…         2        6 It is a 10-1-10 inverted repeat that resemb…
#  5 TGANNNNNNTC… Results and Discussion; Comput…         2        7 A 15 bp box (5'-TGANNNNNNTCAA-3') was found…
#  6 TTGATN       Results and Discussion; Comput…         2        8 It is a part of the E. coli Fnr box (5'-AAW…
#  7 NATCAA       Results and Discussion; Comput…         2        8 It is a part of the E. coli Fnr box (5'-AAW…
#  8 GTTAATTAA    Results and Discussion; Comput…         3        4 The ArcA regulator can recognize a relative…
#  9 GTTAATTAATGT Results and Discussion; Comput…         3        5 An ArcA-box-like sequence (5'-GTTAATTAATGT-…
```

A few wrappers search pre-defined patterns and add an extra step to expand matched ranges. `separate_refs` matches references within brackets using `\\[[0-9, -]+\\]` and expands ranges like `[7-9]`.

``` r
separate_refs(txt)
#  # A tibble: 93 x 6
#        id match section   paragraph sentence text                                                              
#     <dbl> <chr> <chr>         <int>    <int> <chr>                                                             
#   1     1 [1]   Backgrou…         1        1 Yersinia pestis is the etiological agent of plague, alternatively…
#   2     2 [2]   Backgrou…         1        3 To produce a transmissible infection, Y. pestis colonizes the fle…
#   3     3 [3]   Backgrou…         1        9 However, a few bacilli are taken up by tissue macrophages, provid…
#   4     4 [4,5] Backgrou…         1       10 Residence in this niche also facilitates the bacteria's resistanc…
#   5     5 [4,5] Backgrou…         1       10 Residence in this niche also facilitates the bacteria's resistanc…
#   6     6 [6]   Backgrou…         2        1 A DNA microarray is able to determine simultaneous changes in all…
#   7     7 [7-9] Backgrou…         2        2 We and others have measured the gene expression profiles of Y. pe…
#   8     8 [7-9] Backgrou…         2        2 We and others have measured the gene expression profiles of Y. pe…
#   9     9 [7-9] Backgrou…         2        2 We and others have measured the gene expression profiles of Y. pe…
#  10    10 [10]  Backgrou…         2        2 We and others have measured the gene expression profiles of Y. pe…
#  # … with 83 more rows
```

`separate_genes` will find microbial genes like tauD (with a capitalized 4th letter) and expand operons like `tauABCD` into four genes. `separate_tags` will find and expand locus tag ranges below.

``` r
collapse_rows(tbls, na="-") %>%
  separate_tags("YPO") %>%
  filter(id == "YPO1855")
#  # A tibble: 3 x 5
#    id      match        table    row text                                                                      
#    <chr>   <chr>        <chr>  <int> <chr>                                                                     
#  1 YPO1855 YPO1854-1856 Table…     5 subheading=Iron uptake or heme synthesis; Potential operon (r value)=YPO1…
#  2 YPO1855 YPO1854-1856 Table…    21 subheading=Category C: Hypothetical; Gene ID=YPO1854-1856; Description=Pu…
#  3 YPO1855 YPO1854-YPO… Table…     2 Cluster=Cluster II; Genes or operons for motif discovery=hmuRSTUV, YPO068…
```

See the [vignette](https://github.com/ropensci/tidypmc/blob/master/vignettes/tidypmc.md) for more details including code to parse XML documents using the [xml2](https://github.com/r-lib/xml2) package. The [PMC FTP vignette](https://github.com/ropensci/tidypmc/blob/master/vignettes/pmcftp.md) has details on parsing XML files at the Europe PMC [FTP site](https://europepmc.org/ftp/oa/).

### Community Guidelines

This project is released with a [Contributor Code of Conduct](CONDUCT.md). By participating in this project you agree to abide by its terms. Feedback, bug reports, and feature requests are welcome [here](https://github.com/ropensci/tidypmc/issues).
