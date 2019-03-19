tidypmc
================
March 18, 2019

The `tidypmc` package parses XML documents in the Open Access subset of [Pubmed Central](https://europepmc.org). Download the full text using the [europepmc](https://github.com/ropensci/europepmc) package.

``` r
library(europepmc)
doc <- epmc_ftxt("PMC2231364")
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

`pmc_text` splits paragraphs into sentences and includes the full path to the subsection title.

``` r
library(tidypmc)
library(dplyr)
txt <- pmc_text(doc)
#  Note: removing disp-formula nested in sec/p tag
txt
#  # A tibble: 194 x 4
#     section    paragraph sentence text                                                                                                                           
#     <chr>          <int>    <int> <chr>                                                                                                                          
#   1 Title              1        1 Comparative transcriptomics in Yersinia pestis: a global view of environmental modulation of gene expression                   
#   2 Abstract           1        1 Environmental modulation of gene expression in Yersinia pestis is critical for its life style and pathogenesis.                
#   3 Abstract           1        2 Using cDNA microarray technology, we have analyzed the global gene expression of this deadly pathogen when grown under differe…
#   4 Abstract           2        1 To provide us with a comprehensive view of environmental modulation of global gene expression in Y. pestis, we have analyzed t…
#   5 Abstract           2        2 Almost all known virulence genes of Y. pestis were differentially regulated under multiple environmental perturbations.        
#   6 Abstract           2        3 Clustering enabled us to functionally classify co-expressed genes, including some uncharacterized genes.                       
#   7 Abstract           2        4 Collections of operons were predicted from the microarray data, and some of these were confirmed by reverse-transcription poly…
#   8 Abstract           2        5 Several regulatory DNA motifs, probably recognized by the regulatory protein Fur, PurR, or Fnr, were predicted from the cluste…
#   9 Abstract           3        1 The comparative transcriptomics analysis we present here not only benefits our understanding of the molecular determinants of …
#  10 Background         1        1 Yersinia pestis is the etiological agent of plague, alternatively growing in fleas or warm-blood mammals [1].                  
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
filter(cap1, sentence==1)
#  # A tibble: 12 x 4
#     tag        label                        sentence text                                                                                                     
#     <chr>      <chr>                           <int> <chr>                                                                                                    
#   1 figure     Figure 1                            1 Environmental modulation of expression of virulence genes.                                               
#   2 figure     Figure 2                            1 RT-PCR analysis of potential operons.                                                                    
#   3 figure     Figure 3                            1 Schematic representation of the clustered microarray data.                                               
#   4 figure     Figure 4                            1 Graphical representation of the consensus patterns by motif search.                                      
#   5 figure     Figure 5                            1 EMSA analysis of the binding of Fur protein to promoter DNA probes.                                      
#   6 table      Table 1                             1 Stress-responsive operons in Y. pestis predicted from microarray expression data                         
#   7 table      Table 2                             1 Classification of the gene members of the cluster II in Figure 3                                         
#   8 table      Table 3                             1 Motif discovery for the clustering genes                                                                 
#   9 table      Table 4                             1 Designs for expression profiling of Y. pestis                                                            
#  10 supplement Additional file 1 Figure S1.        1 Growth curves of Y. pestis strain 201 under different conditions.                                        
#  11 supplement Additional file 2 Table S1.         1 All the transcriptional changes of 4005 genes of Y. pestis in response to 25 environmental perturbations.
#  12 supplement Additional file 3 Table S2.         1 List of oligonucleotide primers used in this study.
```

`pmc_table` formats tables by collapsing multiline headers, expanding rowspan and colspan attributes and adding subheadings into a new column.

``` r
tab1 <- pmc_table(doc)
#  Found 4 tables
#  Adding footnotes to Table 1
sapply(tab1, nrow)
#  Table 1 Table 2 Table 3 Table 4 
#       39      23       4      34
tab1[[1]]
#  # A tibble: 39 x 5
#     subheading                    `Potential operon (r value)` `Gene ID`    `Putative or predicted function`      `Reference (s)`
#     <chr>                         <chr>                        <chr>        <chr>                                 <chr>          
#   1 Iron uptake or heme synthesis yfeABCD operon* (r > 0.91)   YPO2439-2442 Transport/binding chelated iron       yfeABCD [54]   
#   2 Iron uptake or heme synthesis hmuRSTUV operon (r > 0.90)   YPO0279-0283 Transport/binding hemin               hmuRSTUV [55]  
#   3 Iron uptake or heme synthesis ysuJIHG* (r > 0.95)          YPO1529-1532 Iron uptake                           -              
#   4 Iron uptake or heme synthesis sufABCDS* (r > 0.90)         YPO2400-2404 Iron-regulated Fe-S cluster assembly? -              
#   5 Iron uptake or heme synthesis YPO1854-1856* (r > 0.97)     YPO1854-1856 Iron uptake or heme synthesis?        -              
#   6 Sulfur metabolism             tauABCD operon (r > 0.90)    YPO0182-0185 Transport/binding taurine             tauABCD [56]   
#   7 Sulfur metabolism             ssuEADCB operon (r > 0.97)   YPO3623-3627 Sulphur metabolism                    ssu operon [57]
#   8 Sulfur metabolism             cys operon (r > 0.92)        YPO3010-3015 Cysteine synthesis                    -              
#   9 Sulfur metabolism             YPO1317-1319 (r > 0.97)      YPO1317-1319 Sulfur metabolism?                    -              
#  10 Sulfur metabolism             YPO4109-4111 (r > 0.90)      YPO4109-4111 Sulfur metabolism?                    -              
#  # … with 29 more rows
```

Captions and footnotes are added as attributes.

``` r
attributes(tab1[[1]])
#  $names
#  [1] "subheading"                     "Potential operon (r value)"     "Gene ID"                        "Putative or predicted function"
#  [5] "Reference (s)"                 
#  
#  $row.names
#   [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39
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
#   1 Table 1     1 subheading=Iron uptake or heme synthesis; Potential operon (r value)=yfeABCD operon* (r > 0.91); Gene ID=YPO2439-2442; Putative or predicted function=Transport/bi…
#   2 Table 1     2 subheading=Iron uptake or heme synthesis; Potential operon (r value)=hmuRSTUV operon (r > 0.90); Gene ID=YPO0279-0283; Putative or predicted function=Transport/bi…
#   3 Table 1     3 subheading=Iron uptake or heme synthesis; Potential operon (r value)=ysuJIHG* (r > 0.95); Gene ID=YPO1529-1532; Putative or predicted function=Iron uptake         
#   4 Table 1     4 subheading=Iron uptake or heme synthesis; Potential operon (r value)=sufABCDS* (r > 0.90); Gene ID=YPO2400-2404; Putative or predicted function=Iron-regulated Fe-…
#   5 Table 1     5 subheading=Iron uptake or heme synthesis; Potential operon (r value)=YPO1854-1856* (r > 0.97); Gene ID=YPO1854-1856; Putative or predicted function=Iron uptake or…
#   6 Table 1     6 subheading=Sulfur metabolism; Potential operon (r value)=tauABCD operon (r > 0.90); Gene ID=YPO0182-0185; Putative or predicted function=Transport/binding taurine…
#   7 Table 1     7 subheading=Sulfur metabolism; Potential operon (r value)=ssuEADCB operon (r > 0.97); Gene ID=YPO3623-3627; Putative or predicted function=Sulphur metabolism; Refe…
#   8 Table 1     8 subheading=Sulfur metabolism; Potential operon (r value)=cys operon (r > 0.92); Gene ID=YPO3010-3015; Putative or predicted function=Cysteine synthesis            
#   9 Table 1     9 subheading=Sulfur metabolism; Potential operon (r value)=YPO1317-1319 (r > 0.97); Gene ID=YPO1317-1319; Putative or predicted function=Sulfur metabolism?          
#  10 Table 1    10 subheading=Sulfur metabolism; Potential operon (r value)=YPO4109-4111 (r > 0.90); Gene ID=YPO4109-4111; Putative or predicted function=Sulfur metabolism?          
#  # … with 90 more rows
```

`pmc_reference` extracts the id, pmid, authors, year, title, journal, volume, pages, and DOIs from reference tags.

``` r
ref1 <- pmc_reference(doc)
#  Found 76 citation tags
ref1
#  # A tibble: 76 x 9
#        id pmid   authors                                                year title                                        journal     volume pages  doi          
#     <int> <chr>  <chr>                                                 <int> <chr>                                        <chr>       <chr>  <chr>  <chr>        
#   1     1 89938… Perry RD, Fetherston JD                                1997 Yersinia pestis--etiologic agent of plague   Clin Micro… 10     35-66  <NA>         
#   2     2 16053… Hinnebusch BJ                                          2005 The evolution of flea-borne transmission in… Curr Issue… 7      197-2… <NA>         
#   3     3 64693… Straley SC, Harmon PA                                  1984 Yersinia pestis grows within phagolysosomes… Infect Imm… 45     655-6… <NA>         
#   4     4 15557… Huang XZ, Lindler LE                                   2004 The pH 6 antigen is an antiphagocytic facto… Infect Imm… 72     7212-… 10.1128/IAI.…
#   5     5 15721… Pujol C, Bliska JB                                     2005 Turning Yersinia pathogenesis outside in: s… Clin Immun… 114    216-2… 10.1016/j.cl…
#   6     6 12732… Rhodius VA, LaRossa RA                                 2003 Uses and pitfalls of microarrays for studyi… Curr Opin … 6      114-1… 10.1016/S136…
#   7     7 15342… Motin VL, Georgescu AM, Fitch JP, Gu PP, Nelson DO, …  2004 Temporal global changes in gene expression … J Bacteriol 186    6298-… 10.1128/JB.1…
#   8     8 15557… Han Y, Zhou D, Pang X, Song Y, Zhang L, Bao J, Tong …  2004 Microarray analysis of temperature-induced … Microbiol … 48     791-8… <NA>         
#   9     9 15777… Han Y, Zhou D, Pang X, Zhang L, Song Y, Tong Z, Bao …  2005 DNA microarray analysis of the heat- and co… Microbes I… 7      335-3… 10.1016/j.mi…
#  10    10 15808… Han Y, Zhou D, Pang X, Zhang L, Song Y, Tong Z, Bao …  2005 Comparative transcriptome analysis of Yersi… Res Microb… 156    403-4… 10.1016/j.re…
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
#  $`Published online`
#  [1] "2007-10-29"
#  
#  $`Date received`
#  [1] "2007-6-2"
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
#    match           section                                          paragraph sentence text                                                                      
#    <chr>           <chr>                                                <int>    <int> <chr>                                                                     
#  1 ACGCAATCGTTTTC… Results and Discussion; Computational discovery…         2        3 A 16 basepair (bp) box (5'-ACGCAATCGTTTTCNT-3') was detected in the upstr…
#  2 AAACGTTTNCGT    Results and Discussion; Computational discovery…         2        4 It is very similar to the E. coli PurR box (5'-ANGMAAACGTTTNCGTK-3') [47].
#  3 TGATAATGATTATC… Results and Discussion; Computational discovery…         2        5 A 21 bp box (5'-TGATAATGATTATCATTATCA-3') was found for the 19 genes in c…
#  4 GATAATGATAATCA… Results and Discussion; Computational discovery…         2        6 It is a 10-1-10 inverted repeat that resembles the E. coli Fur box (5'-GA…
#  5 TGANNNNNNTCAA   Results and Discussion; Computational discovery…         2        7 A 15 bp box (5'-TGANNNNNNTCAA-3') was found within the upstream regions o…
#  6 TTGATN          Results and Discussion; Computational discovery…         2        8 It is a part of the E. coli Fnr box (5'-AAWTTGATNWMNATCAAWWWW-3') [45].   
#  7 NATCAA          Results and Discussion; Computational discovery…         2        8 It is a part of the E. coli Fnr box (5'-AAWTTGATNWMNATCAAWWWW-3') [45].   
#  8 GTTAATTAA       Results and Discussion; Computational discovery…         3        4 The ArcA regulator can recognize a relatively conservative sequence (5'-G…
#  9 GTTAATTAATGT    Results and Discussion; Computational discovery…         3        5 An ArcA-box-like sequence (5'-GTTAATTAATGT-3') was found in the upstream …
```

A few wrappers search pre-defined patterns and add an extra step to expand matched ranges. `separate_refs` matches references within brackets using `\\[[0-9, -]+\\]` and expands ranges like `[7-9]`.

``` r
x <- separate_refs(txt)
x
#  # A tibble: 93 x 6
#        id match section    paragraph sentence text                                                                                                               
#     <dbl> <chr> <chr>          <int>    <int> <chr>                                                                                                              
#   1     1 [1]   Background         1        1 Yersinia pestis is the etiological agent of plague, alternatively growing in fleas or warm-blood mammals [1].      
#   2     2 [2]   Background         1        3 To produce a transmissible infection, Y. pestis colonizes the flea midgut and forms a biofilm in the proventricula…
#   3     3 [3]   Background         1        9 However, a few bacilli are taken up by tissue macrophages, providing a fastidious and unoccupied niche for Y. pest…
#   4     4 [4,5] Background         1       10 Residence in this niche also facilitates the bacteria's resistance to phagocytosis [4,5].                          
#   5     5 [4,5] Background         1       10 Residence in this niche also facilitates the bacteria's resistance to phagocytosis [4,5].                          
#   6     6 [6]   Background         2        1 A DNA microarray is able to determine simultaneous changes in all the genes of a cell at the mRNA level [6].       
#   7     7 [7-9] Background         2        2 We and others have measured the gene expression profiles of Y. pestis in response to a variety of stimulating cond…
#   8     8 [7-9] Background         2        2 We and others have measured the gene expression profiles of Y. pestis in response to a variety of stimulating cond…
#   9     9 [7-9] Background         2        2 We and others have measured the gene expression profiles of Y. pestis in response to a variety of stimulating cond…
#  10    10 [10]  Background         2        2 We and others have measured the gene expression profiles of Y. pestis in response to a variety of stimulating cond…
#  # … with 83 more rows
filter(x, id==8)
#  # A tibble: 5 x 6
#       id match      section                                      paragraph sentence text                                                                         
#    <dbl> <chr>      <chr>                                            <int>    <int> <chr>                                                                        
#  1     8 [7-9]      Background                                           2        2 We and others have measured the gene expression profiles of Y. pestis in res…
#  2     8 [8-13,15]  Background                                           2        4 In order to acquire more regulatory information, all available microarray da…
#  3     8 [7-13,15,… Results and Discussion                               2        1 Recently, many signature expression profiles of Y. pestis have been reported…
#  4     8 [7-9]      Results and Discussion; Virulence genes in …         3        1 As described previously, expression profiles of Y. pestis showed that almost…
#  5     8 [8-10]     Methods; Collection of microarray expressio…         1        6 The genome-wide transcriptional changes upon the environmental perturbations…
```

`separate_genes` expands microbial gene operons like `hmsHFRS` into four separate genes.

``` r
separate_genes(txt)
#  # A tibble: 104 x 6
#     gene  match  section                                        paragraph sentence text                                                                          
#     <chr> <chr>  <chr>                                              <int>    <int> <chr>                                                                         
#   1 purR  PurR   Abstract                                               2        5 Several regulatory DNA motifs, probably recognized by the regulatory protein …
#   2 phoP  PhoP   Background                                             2        3 We also identified the regulons controlled by each of the regulatory proteins…
#   3 ompR  OmpR   Background                                             2        3 We also identified the regulons controlled by each of the regulatory proteins…
#   4 oxyR  OxyR   Background                                             2        3 We also identified the regulons controlled by each of the regulatory proteins…
#   5 csrA  CsrA   Results and Discussion                                 1        3 After the determination of the CsrA, SlyA, and PhoPQ regulons in Samonella ty…
#   6 slyA  SlyA   Results and Discussion                                 1        3 After the determination of the CsrA, SlyA, and PhoPQ regulons in Samonella ty…
#   7 phoP  PhoPQ  Results and Discussion                                 1        3 After the determination of the CsrA, SlyA, and PhoPQ regulons in Samonella ty…
#   8 phoQ  PhoPQ  Results and Discussion                                 1        3 After the determination of the CsrA, SlyA, and PhoPQ regulons in Samonella ty…
#   9 hmsH  hmsHF… Results and Discussion; Virulence genes in re…         3        3 For example, the hemin storage locus, hmsHFRS [23], was repressed by temperat…
#  10 hmsF  hmsHF… Results and Discussion; Virulence genes in re…         3        3 For example, the hemin storage locus, hmsHFRS [23], was repressed by temperat…
#  # … with 94 more rows
```

Finally, `separate_tags` expands locus tag ranges.

``` r
collapse_rows(tab1, na="-") %>% separate_tags("YPO")
#  # A tibble: 270 x 5
#     id      match       table     row text                                                                                                                                                               
#     <chr>   <chr>       <chr>   <int> <chr>                                                                                                                                                              
#   1 YPO2439 YPO2439-24… Table 1     1 subheading=Iron uptake or heme synthesis; Potential operon (r value)=yfeABCD operon* (r > 0.91); Gene ID=YPO2439-2442; Putative or predicted function=Transport/bi…
#   2 YPO2440 YPO2439-24… Table 1     1 subheading=Iron uptake or heme synthesis; Potential operon (r value)=yfeABCD operon* (r > 0.91); Gene ID=YPO2439-2442; Putative or predicted function=Transport/bi…
#   3 YPO2441 YPO2439-24… Table 1     1 subheading=Iron uptake or heme synthesis; Potential operon (r value)=yfeABCD operon* (r > 0.91); Gene ID=YPO2439-2442; Putative or predicted function=Transport/bi…
#   4 YPO2442 YPO2439-24… Table 1     1 subheading=Iron uptake or heme synthesis; Potential operon (r value)=yfeABCD operon* (r > 0.91); Gene ID=YPO2439-2442; Putative or predicted function=Transport/bi…
#   5 YPO0279 YPO0279-02… Table 1     2 subheading=Iron uptake or heme synthesis; Potential operon (r value)=hmuRSTUV operon (r > 0.90); Gene ID=YPO0279-0283; Putative or predicted function=Transport/bi…
#   6 YPO0280 YPO0279-02… Table 1     2 subheading=Iron uptake or heme synthesis; Potential operon (r value)=hmuRSTUV operon (r > 0.90); Gene ID=YPO0279-0283; Putative or predicted function=Transport/bi…
#   7 YPO0281 YPO0279-02… Table 1     2 subheading=Iron uptake or heme synthesis; Potential operon (r value)=hmuRSTUV operon (r > 0.90); Gene ID=YPO0279-0283; Putative or predicted function=Transport/bi…
#   8 YPO0282 YPO0279-02… Table 1     2 subheading=Iron uptake or heme synthesis; Potential operon (r value)=hmuRSTUV operon (r > 0.90); Gene ID=YPO0279-0283; Putative or predicted function=Transport/bi…
#   9 YPO0283 YPO0279-02… Table 1     2 subheading=Iron uptake or heme synthesis; Potential operon (r value)=hmuRSTUV operon (r > 0.90); Gene ID=YPO0279-0283; Putative or predicted function=Transport/bi…
#  10 YPO1529 YPO1529-15… Table 1     3 subheading=Iron uptake or heme synthesis; Potential operon (r value)=ysuJIHG* (r > 0.95); Gene ID=YPO1529-1532; Putative or predicted function=Iron uptake         
#  # … with 260 more rows
```

### Using `xml2`

The `pmc_*` functions use the [xml2](https://github.com/r-lib/xml2) package for parsing and may fail in some situations, so it helps to know how to parse `xml_documents`. Use `cat` and `as.character` to view nodes returned by `xml_find_all`.

``` r
refs <- xml_find_all(doc, "//ref")
refs[1]
#  {xml_nodeset (1)}
#  [1] <ref id="B1">\n  <citation citation-type="journal">\n    <person-group person-group-type="author">\n      <name>\n        <surname>Perry</surname>\n        <given-names>RD</given-names>\n       ...
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

Many journals use superscripts for references cited so they usually appear at the end of a sentence.

``` r
# doc1 <- epmc_ftxt("PMC6385181")
doc1 <- read_xml(system.file("extdata/PMC6385181.xml", package = "tidypmc"))
txt1 <- pmc_text(doc1)
txt1$text[16]
#  [1] "In 2017, at least 64 patients succumbed during an outbreak in Madagascar3."
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

You can now find references using the default pattern.

``` r
txt1b <- pmc_text(doc1)
txt1b$text[16]
#  [1] "In 2017, at least 64 patients succumbed during an outbreak in Madagascar [3]."
separate_refs(txt1b)
#  # A tibble: 86 x 6
#        id match section     paragraph sentence text                                                                                                                                                      
#     <dbl> <chr> <chr>           <int>    <int> <chr>                                                                                                                                                     
#   1     1 [1]   Introducti…         1        1 Plague is a fatal disease caused by the Gram-negative bacterium Yersinia pestis [1] which has been responsible for approximately 200 million deaths in th…
#   2     2 [2]   Introducti…         1        2 Between 2010 and 2015, the World Health Organization (WHO) reported more than 3200 cases with more than 500 deaths [2].                                   
#   3     3 [3]   Introducti…         1        3 In 2017, at least 64 patients succumbed during an outbreak in Madagascar [3].                                                                             
#   4     1 [1]   Introducti…         1        7 At this stage, bacteria are transmissible by air, causing deadly primary pneumonic presentations [1].                                                     
#   5     4 [4]   Introducti…         1        9 Therefore, it is not surprising that temperature controls several biological processes playing a key role in the colonization of both the mammalian host …
#   6     5 [5]   Introducti…         1       10 In fact, previous comparative transcriptomic and proteomic studies have shown that many genes are differentially expressed when temperature increases fro…
#   7     6 [6]   Introducti…         2        1 Reverse transcription quantitative real-time polymerase chain reaction (RT-qPCR) is a widespread [6] gold standard [7] technique to explore transcription…
#   8     7 [7]   Introducti…         2        1 Reverse transcription quantitative real-time polymerase chain reaction (RT-qPCR) is a widespread [6] gold standard [7] technique to explore transcription…
#   9     8 [8]   Introducti…         2        2 It is often the easiest and the most cost effective solution to measure the genes’ expression [8] and to understand complex regulatory networks.          
#  10     7 [7]   Introducti…         2        3 Moreover, the expansion of the RNA sequencing (RNA-seq) did not replace the RT-qPCR because these two techniques work complementarily [7].                
#  # … with 76 more rows
```
