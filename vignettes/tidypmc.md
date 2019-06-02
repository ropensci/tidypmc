Introduction to tidypmc
================
Chris Stubben
June 1, 2019

The `tidypmc` package parses XML documents in the Open Access subset of [Pubmed Central](https://europepmc.org). Download the full text using `pmc_xml`.

``` r
doc <- pmc_xml("PMC2231364")
doc
#  {xml_document}
#  <article article-type="research-article" xmlns:xlink="http://www.w3.org/1999/xlink">
#  [1] <front>\n  <journal-meta>\n    <journal-id journal-id-type="nlm-ta"> ...
#  [2] <body>\n  <sec>\n    <title>Background</title>\n    <p><italic>Yersi ...
#  [3] <back>\n  <ack>\n    <sec>\n      <title>Acknowledgements</title>\n  ...
```

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

`pmc_text` splits paragraphs into sentences and removes any tables, figures or formulas that are nested within paragraph tags, replaces superscripted references with brackets, adds carets and underscores to other superscripts and subscripts and includes the full path to the subsection title.

``` r
library(tidypmc)
library(dplyr)
txt <- pmc_text(doc)
txt
#  # A tibble: 194 x 4
#     section    paragraph sentence text                                                               
#     <chr>          <int>    <int> <chr>                                                              
#   1 Title              1        1 Comparative transcriptomics in Yersinia pestis: a global view of e…
#   2 Abstract           1        1 Environmental modulation of gene expression in Yersinia pestis is …
#   3 Abstract           1        2 Using cDNA microarray technology, we have analyzed the global gene…
#   4 Abstract           2        1 To provide us with a comprehensive view of environmental modulatio…
#   5 Abstract           2        2 Almost all known virulence genes of Y. pestis were differentially …
#   6 Abstract           2        3 Clustering enabled us to functionally classify co-expressed genes,…
#   7 Abstract           2        4 Collections of operons were predicted from the microarray data, an…
#   8 Abstract           2        5 Several regulatory DNA motifs, probably recognized by the regulato…
#   9 Abstract           3        1 The comparative transcriptomics analysis we present here not only …
#  10 Background         1        1 Yersinia pestis is the etiological agent of plague, alternatively …
#  # … with 184 more rows
count(txt, section)
#  # A tibble: 21 x 2
#     section                                                  n
#     <chr>                                                <int>
#   1 Abstract                                                 8
#   2 Authors' contributions                                   6
#   3 Background                                              20
#   4 Conclusion                                               3
#   5 Methods; Clustering analysis                             7
#   6 Methods; Collection of microarray expression data       17
#   7 Methods; Discovery of regulatory DNA motifs              8
#   8 Methods; Gel mobility shift analysis of Fur binding     13
#   9 Methods; Operon prediction                               5
#  10 Methods; Verification of predicted operons by RT-PCR     7
#  # … with 11 more rows
```

`pmc_caption` splits figure, table and supplementary material captions into sentences.

``` r
cap1 <- pmc_caption(doc)
#  Found 5 figures
#  Found 4 tables
#  Found 3 supplements
filter(cap1, sentence == 1)
#  # A tibble: 12 x 4
#     tag      label               sentence text                                                       
#     <chr>    <chr>                  <int> <chr>                                                      
#   1 figure   Figure 1                   1 Environmental modulation of expression of virulence genes. 
#   2 figure   Figure 2                   1 RT-PCR analysis of potential operons.                      
#   3 figure   Figure 3                   1 Schematic representation of the clustered microarray data. 
#   4 figure   Figure 4                   1 Graphical representation of the consensus patterns by moti…
#   5 figure   Figure 5                   1 EMSA analysis of the binding of Fur protein to promoter DN…
#   6 table    Table 1                    1 Stress-responsive operons in Y. pestis predicted from micr…
#   7 table    Table 2                    1 Classification of the gene members of the cluster II in Fi…
#   8 table    Table 3                    1 Motif discovery for the clustering genes                   
#   9 table    Table 4                    1 Designs for expression profiling of Y. pestis              
#  10 supplem… Additional file 1 …        1 Growth curves of Y. pestis strain 201 under different cond…
#  11 supplem… Additional file 2 …        1 All the transcriptional changes of 4005 genes of Y. pestis…
#  12 supplem… Additional file 3 …        1 List of oligonucleotide primers used in this study.
```

`pmc_table` formats tables by collapsing multiline headers, expanding rowspan and colspan attributes and adding subheadings into a new column.

``` r
tab1 <- pmc_table(doc)
#  Parsing 4 tables
#  Adding footnotes to Table 1
sapply(tab1, nrow)
#  Table 1 Table 2 Table 3 Table 4 
#       39      23       4      34
tab1[[1]]
#  # A tibble: 39 x 5
#     subheading           `Potential operon (r … `Gene ID`  `Putative or predicted fu… `Reference (s)`
#     <chr>                <chr>                  <chr>      <chr>                      <chr>          
#   1 Iron uptake or heme… yfeABCD operon* (r > … YPO2439-2… Transport/binding chelate… yfeABCD [54]   
#   2 Iron uptake or heme… hmuRSTUV operon (r > … YPO0279-0… Transport/binding hemin    hmuRSTUV [55]  
#   3 Iron uptake or heme… ysuJIHG* (r > 0.95)    YPO1529-1… Iron uptake                -              
#   4 Iron uptake or heme… sufABCDS* (r > 0.90)   YPO2400-2… Iron-regulated Fe-S clust… -              
#   5 Iron uptake or heme… YPO1854-1856* (r > 0.… YPO1854-1… Iron uptake or heme synth… -              
#   6 Sulfur metabolism    tauABCD operon (r > 0… YPO0182-0… Transport/binding taurine  tauABCD [56]   
#   7 Sulfur metabolism    ssuEADCB operon (r > … YPO3623-3… Sulphur metabolism         ssu operon [57]
#   8 Sulfur metabolism    cys operon (r > 0.92)  YPO3010-3… Cysteine synthesis         -              
#   9 Sulfur metabolism    YPO1317-1319 (r > 0.9… YPO1317-1… Sulfur metabolism?         -              
#  10 Sulfur metabolism    YPO4109-4111 (r > 0.9… YPO4109-4… Sulfur metabolism?         -              
#  # … with 29 more rows
```

Captions and footnotes are added as attributes.

``` r
attributes(tab1[[1]])
#  $names
#  [1] "subheading"                     "Potential operon (r value)"    
#  [3] "Gene ID"                        "Putative or predicted function"
#  [5] "Reference (s)"                 
#  
#  $row.names
#   [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32
#  [33] 33 34 35 36 37 38 39
#  
#  $class
#  [1] "tbl_df"     "tbl"        "data.frame"
#  
#  $caption
#  [1] "Stress-responsive operons in Y. pestis predicted from microarray expression data"
#  
#  $footnotes
#  [1] "'r' represents the correlation coefficient of adjacent genes; '*' represent the defined operon has the similar expression pattern in two other published microarray datasets [7, 21]; '?' inferred functions of uncharacterized genes; '-' means the corresponding operons have not been experimentally validated in other bacteria."
```

Use `collapse_rows` to join column names and cell values in a semi-colon delimited string (and then search using functions in the next section).

``` r
collapse_rows(tab1, na.string="-")
#  # A tibble: 100 x 3
#     table     row text                                                                               
#     <chr>   <int> <chr>                                                                              
#   1 Table 1     1 subheading=Iron uptake or heme synthesis; Potential operon (r value)=yfeABCD opero…
#   2 Table 1     2 subheading=Iron uptake or heme synthesis; Potential operon (r value)=hmuRSTUV oper…
#   3 Table 1     3 subheading=Iron uptake or heme synthesis; Potential operon (r value)=ysuJIHG* (r >…
#   4 Table 1     4 subheading=Iron uptake or heme synthesis; Potential operon (r value)=sufABCDS* (r …
#   5 Table 1     5 subheading=Iron uptake or heme synthesis; Potential operon (r value)=YPO1854-1856*…
#   6 Table 1     6 subheading=Sulfur metabolism; Potential operon (r value)=tauABCD operon (r > 0.90)…
#   7 Table 1     7 subheading=Sulfur metabolism; Potential operon (r value)=ssuEADCB operon (r > 0.97…
#   8 Table 1     8 subheading=Sulfur metabolism; Potential operon (r value)=cys operon (r > 0.92); Ge…
#   9 Table 1     9 subheading=Sulfur metabolism; Potential operon (r value)=YPO1317-1319 (r > 0.97); …
#  10 Table 1    10 subheading=Sulfur metabolism; Potential operon (r value)=YPO4109-4111 (r > 0.90); …
#  # … with 90 more rows
```

`pmc_reference` extracts the id, pmid, authors, year, title, journal, volume, pages, and DOIs from reference tags.

``` r
ref1 <- pmc_reference(doc)
#  Found 76 citation tags
ref1
#  # A tibble: 76 x 9
#        id pmid   authors                  year title                 journal   volume pages doi      
#     <int> <chr>  <chr>                   <int> <chr>                 <chr>     <chr>  <chr> <chr>    
#   1     1 89938… Perry RD, Fetherston JD  1997 Yersinia pestis--eti… Clin Mic… 10     35-66 <NA>     
#   2     2 16053… Hinnebusch BJ            2005 The evolution of fle… Curr Iss… 7      197-… <NA>     
#   3     3 64693… Straley SC, Harmon PA    1984 Yersinia pestis grow… Infect I… 45     655-… <NA>     
#   4     4 15557… Huang XZ, Lindler LE     2004 The pH 6 antigen is … Infect I… 72     7212… 10.1128/…
#   5     5 15721… Pujol C, Bliska JB       2005 Turning Yersinia pat… Clin Imm… 114    216-… 10.1016/…
#   6     6 12732… Rhodius VA, LaRossa RA   2003 Uses and pitfalls of… Curr Opi… 6      114-… 10.1016/…
#   7     7 15342… Motin VL, Georgescu AM…  2004 Temporal global chan… J Bacter… 186    6298… 10.1128/…
#   8     8 15557… Han Y, Zhou D, Pang X,…  2004 Microarray analysis … Microbio… 48     791-… <NA>     
#   9     9 15777… Han Y, Zhou D, Pang X,…  2005 DNA microarray analy… Microbes… 7      335-… 10.1016/…
#  10    10 15808… Han Y, Zhou D, Pang X,…  2005 Comparative transcri… Res Micr… 156    403-… 10.1016/…
#  # … with 66 more rows
```

Finally, `pmc_metadata` saves journal and article metadata to a list.

``` r
pmc_metadata(doc)
#  $PMCID
#  [1] "PMC2231364"
#  
#  $Title
#  [1] "Comparative transcriptomics in Yersinia pestis: a global view of environmental modulation of gene expression"
#  
#  $Authors
#  [1] "Yanping Han, Jingfu Qiu, Zhaobiao Guo, He Gao, Yajun Song, Dongsheng Zhou, Ruifu Yang"
#  
#  $Year
#  [1] 2007
#  
#  $Journal
#  [1] "BMC Microbiology"
#  
#  $Volume
#  [1] "7"
#  
#  $Pages
#  [1] "96"
#  
#  $`Published online`
#  [1] "2007-10-29"
#  
#  $`Date received`
#  [1] "2007-6-2"
#  
#  $DOI
#  [1] "10.1186/1471-2180-7-96"
#  
#  $Publisher
#  [1] "BioMed Central"
```

Searching text
--------------

There are a few functions to search within the `pmc_text` or collapsed `pmc_table` output. `separate_text` uses the [stringr](https://stringr.tidyverse.org/) package to extract any matching regular expression.

``` r
separate_text(txt, "[ATCGN]{5,}")
#  # A tibble: 9 x 5
#    match       section                       paragraph sentence text                                 
#    <chr>       <chr>                             <int>    <int> <chr>                                
#  1 ACGCAATCGT… Results and Discussion; Comp…         2        3 A 16 basepair (bp) box (5'-ACGCAATCG…
#  2 AAACGTTTNC… Results and Discussion; Comp…         2        4 It is very similar to the E. coli Pu…
#  3 TGATAATGAT… Results and Discussion; Comp…         2        5 A 21 bp box (5'-TGATAATGATTATCATTATC…
#  4 GATAATGATA… Results and Discussion; Comp…         2        6 It is a 10-1-10 inverted repeat that…
#  5 TGANNNNNNT… Results and Discussion; Comp…         2        7 A 15 bp box (5'-TGANNNNNNTCAA-3') wa…
#  6 TTGATN      Results and Discussion; Comp…         2        8 It is a part of the E. coli Fnr box …
#  7 NATCAA      Results and Discussion; Comp…         2        8 It is a part of the E. coli Fnr box …
#  8 GTTAATTAA   Results and Discussion; Comp…         3        4 The ArcA regulator can recognize a r…
#  9 GTTAATTAAT… Results and Discussion; Comp…         3        5 An ArcA-box-like sequence (5'-GTTAAT…
```

A few wrappers search pre-defined patterns and add an extra step to expand matched ranges. `separate_refs` matches references within brackets using `\\[[0-9, -]+\\]` and expands ranges like `[7-9]`.

``` r
x <- separate_refs(txt)
x
#  # A tibble: 93 x 6
#        id match section   paragraph sentence text                                                    
#     <dbl> <chr> <chr>         <int>    <int> <chr>                                                   
#   1     1 [1]   Backgrou…         1        1 Yersinia pestis is the etiological agent of plague, alt…
#   2     2 [2]   Backgrou…         1        3 To produce a transmissible infection, Y. pestis coloniz…
#   3     3 [3]   Backgrou…         1        9 However, a few bacilli are taken up by tissue macrophag…
#   4     4 [4,5] Backgrou…         1       10 Residence in this niche also facilitates the bacteria's…
#   5     5 [4,5] Backgrou…         1       10 Residence in this niche also facilitates the bacteria's…
#   6     6 [6]   Backgrou…         2        1 A DNA microarray is able to determine simultaneous chan…
#   7     7 [7-9] Backgrou…         2        2 We and others have measured the gene expression profile…
#   8     8 [7-9] Backgrou…         2        2 We and others have measured the gene expression profile…
#   9     9 [7-9] Backgrou…         2        2 We and others have measured the gene expression profile…
#  10    10 [10]  Backgrou…         2        2 We and others have measured the gene expression profile…
#  # … with 83 more rows
filter(x, id == 8)
#  # A tibble: 5 x 6
#       id match    section                         paragraph sentence text                            
#    <dbl> <chr>    <chr>                               <int>    <int> <chr>                           
#  1     8 [7-9]    Background                              2        2 We and others have measured the…
#  2     8 [8-13,1… Background                              2        4 In order to acquire more regula…
#  3     8 [7-13,1… Results and Discussion                  2        1 Recently, many signature expres…
#  4     8 [7-9]    Results and Discussion; Virule…         3        1 As described previously, expres…
#  5     8 [8-10]   Methods; Collection of microar…         1        6 The genome-wide transcriptional…
```

`separate_genes` expands microbial gene operons like `hmsHFRS` into four separate genes.

``` r
separate_genes(txt)
#  # A tibble: 103 x 6
#     gene  match  section                         paragraph sentence text                             
#     <chr> <chr>  <chr>                               <int>    <int> <chr>                            
#   1 purR  PurR   Abstract                                2        5 Several regulatory DNA motifs, p…
#   2 phoP  PhoP   Background                              2        3 We also identified the regulons …
#   3 ompR  OmpR   Background                              2        3 We also identified the regulons …
#   4 oxyR  OxyR   Background                              2        3 We also identified the regulons …
#   5 csrA  CsrA   Results and Discussion                  1        3 After the determination of the C…
#   6 slyA  SlyA   Results and Discussion                  1        3 After the determination of the C…
#   7 phoPQ PhoPQ  Results and Discussion                  1        3 After the determination of the C…
#   8 hmsH  hmsHF… Results and Discussion; Virule…         3        3 For example, the hemin storage l…
#   9 hmsF  hmsHF… Results and Discussion; Virule…         3        3 For example, the hemin storage l…
#  10 hmsR  hmsHF… Results and Discussion; Virule…         3        3 For example, the hemin storage l…
#  # … with 93 more rows
```

Finally, `separate_tags` expands locus tag ranges.

``` r
collapse_rows(tab1, na="-") %>%
  separate_tags("YPO")
#  # A tibble: 270 x 5
#     id      match      table    row text                                                             
#     <chr>   <chr>      <chr>  <int> <chr>                                                            
#   1 YPO2439 YPO2439-2… Table…     1 subheading=Iron uptake or heme synthesis; Potential operon (r va…
#   2 YPO2440 YPO2439-2… Table…     1 subheading=Iron uptake or heme synthesis; Potential operon (r va…
#   3 YPO2441 YPO2439-2… Table…     1 subheading=Iron uptake or heme synthesis; Potential operon (r va…
#   4 YPO2442 YPO2439-2… Table…     1 subheading=Iron uptake or heme synthesis; Potential operon (r va…
#   5 YPO0279 YPO0279-0… Table…     2 subheading=Iron uptake or heme synthesis; Potential operon (r va…
#   6 YPO0280 YPO0279-0… Table…     2 subheading=Iron uptake or heme synthesis; Potential operon (r va…
#   7 YPO0281 YPO0279-0… Table…     2 subheading=Iron uptake or heme synthesis; Potential operon (r va…
#   8 YPO0282 YPO0279-0… Table…     2 subheading=Iron uptake or heme synthesis; Potential operon (r va…
#   9 YPO0283 YPO0279-0… Table…     2 subheading=Iron uptake or heme synthesis; Potential operon (r va…
#  10 YPO1529 YPO1529-1… Table…     3 subheading=Iron uptake or heme synthesis; Potential operon (r va…
#  # … with 260 more rows
```

### Using `xml2`

The `pmc_*` functions use the [xml2](https://github.com/r-lib/xml2) package for parsing and may fail in some situations, so it helps to know how to parse `xml_documents`. Use `cat` and `as.character` to view nodes returned by `xml_find_all`.

``` r
library(xml2)
refs <- xml_find_all(doc, "//ref")
refs[1]
#  {xml_nodeset (1)}
#  [1] <ref id="B1">\n  <citation citation-type="journal">\n    <person-group person-group-type="aut ...
cat(as.character(refs[1]))
#  <ref id="B1">
#    <citation citation-type="journal">
#      <person-group person-group-type="author">
#        <name>
#          <surname>Perry</surname>
#          <given-names>RD</given-names>
#        </name>
#        <name>
#          <surname>Fetherston</surname>
#          <given-names>JD</given-names>
#        </name>
#      </person-group>
#      <article-title>Yersinia pestis--etiologic agent of plague</article-title>
#      <source>Clin Microbiol Rev</source>
#      <year>1997</year>
#      <volume>10</volume>
#      <fpage>35</fpage>
#      <lpage>66</lpage>
#      <pub-id pub-id-type="pmid">8993858</pub-id>
#    </citation>
#  </ref>
```

Many journals use superscripts for references cited so they usually appear after words like `response12` below.

``` r
# doc1 <- pmc_xml("PMC6385181")
doc1 <- read_xml(system.file("extdata/PMC6385181.xml", package = "tidypmc"))
gsub(".*\\. ", "", xml_text( xml_find_all(doc1, "//sec/p"))[2])
#  [1] "RNA-seq identifies the most relevant genes and RT-qPCR validates its results9, especially in the field of environmental and host adaptation10,11 and antimicrobial response12."
```

Find the tags using `xml_find_all` and then update the nodes by adding brackets or other text.

``` r
bib <- xml_find_all(doc1, "//xref[@ref-type='bibr']")
bib[1]
#  {xml_nodeset (1)}
#  [1] <xref ref-type="bibr" rid="CR1">1</xref>
xml_text(bib) <- paste0(" [", xml_text(bib), "]")
bib[1]
#  {xml_nodeset (1)}
#  [1] <xref ref-type="bibr" rid="CR1"> [1]</xref>
```

The text is now separated from the reference. Note the `pmc_text` function adds the brackets by default.

``` r
gsub(".*\\. ", "", xml_text( xml_find_all(doc1, "//sec/p"))[2])
#  [1] "RNA-seq identifies the most relevant genes and RT-qPCR validates its results [9], especially in the field of environmental and host adaptation [10], [11] and antimicrobial response [12]."
```

Genes, species and many other terms are often included within italic tags. You can mark these nodes using the same code above or simply list all the names in italics and search text or tables for matches, for example three letter gene names in text below.

``` r
x <- xml_name(xml_find_all(doc, "//*"))
tibble::tibble(tag=x) %>%
  dplyr::count(tag, sort=TRUE)
#  # A tibble: 84 x 2
#     tag               n
#     <chr>         <int>
#   1 td              398
#   2 given-names     388
#   3 name            388
#   4 surname         388
#   5 italic          235
#   6 pub-id          129
#   7 tr              117
#   8 xref            108
#   9 year             80
#  10 article-title    77
#  # … with 74 more rows
it <- xml_text(xml_find_all(doc, "//body//italic"), trim=TRUE)
it2 <- tibble::tibble(italic=it) %>%
  dplyr::count(italic, sort=TRUE)
it2
#  # A tibble: 111 x 2
#     italic          n
#     <chr>       <int>
#   1 Y. pestis      43
#   2 hmuRSTUV        5
#   3 nrdHIEF         5
#   4 sufABCDSE       5
#   5 tauABCD         5
#   6 yfeABCD         5
#   7 E. coli         4
#   8 in vitro        4
#   9 rps-rpm-rpl     4
#  10 ssuEADCB        4
#  # … with 101 more rows
dplyr::filter(it2, nchar(italic) == 3)
#  # A tibble: 23 x 2
#     italic     n
#     <chr>  <int>
#   1 fur        3
#   2 cis        2
#   3 cys        2
#   4 glg        2
#   5 nap        2
#   6 nuo        2
#   7 psp        2
#   8 ure        2
#   9 ybt        2
#  10 ace        1
#  # … with 13 more rows
separate_text(txt, c("adk", "gmk",  "rho", "tmk"))
#  No match to \badk\b|\bgmk\b|\brho\b|\btmk\b
#  NULL
```
