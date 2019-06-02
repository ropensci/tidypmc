Parsing Europe PMC FTP files
================
Chris Stubben
June 1, 2019

The [Europe PMC FTP](https://europepmc.org/ftp/oa/) includes 2.5 million open access articles separated into files with 10K articles each. Download and unzip a recent series of PMC ids and load into R using the `readr` package. A sample file with the first 10 articles is included in the `tidypmc` package.

``` r
library(readr)
pmcfile <- system.file("extdata/PMC6358576_PMC6358589.xml", package = "tidypmc")
pmc <- read_lines(pmcfile)
```

Find the start of the article nodes.

``` r
a1 <- grep("^<article ", pmc)
head(a1)
#  [1]  2 30 38 52 62 69
n <- length(a1)
n
#  [1] 10
```

Read a single article by collapsing the lines into a new line separated string.

``` r
library(xml2)
x1 <- paste(pmc[2:29], collapse="\n")
doc <- read_xml(x1)
doc
#  {xml_document}
#  <article article-type="case-report" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:mml="http://www.w3.org/1998/Math/MathML">
#  [1] <front>\n  <journal-meta>\n    <journal-id journal-id-type="nlm-ta">ACG Case Rep J</journal-i ...
#  [2] <body>\n  <sec sec-type="intro" id="sec1">\n    <title>Introduction</title>\n    <p>Bezoars a ...
#  [3] <back>\n  <ref-list>\n    <title>References</title>\n    <ref id="B1">\n      <label>1.</labe ...
```

Loop through the articles and save the metadata and text below. All 10K articles takes about 10 minutes to run on a Mac laptop and returns 1.7M sentences.

``` r
library(tidypmc)
a1 <- c(a1, length(pmc))
met1 <- vector("list", n)
txt1 <- vector("list", n)
for(i in seq_len(n)){
  doc <- read_xml(paste(pmc[a1[i]:(a1[i+1]-1)], collapse="\n"))
  m1 <- pmc_metadata(doc)
  id <- m1$PMCID
  message("Parsing ", i, ". ", id)
  met1[[i]] <- m1
  txt1[[i]] <- pmc_text(doc)
}
#  Parsing 1. PMC6358576
#  Parsing 2. PMC6358577
#  Parsing 3. PMC6358578
#  Parsing 4. PMC6358579
#  Parsing 5. PMC6358580
#  Parsing 6. PMC6358581
#  Parsing 7. PMC6358585
#  Note: removing table-wrap nested in sec/p tag
#  Note: removing fig nested in sec/p tag
#  Parsing 8. PMC6358587
#  Note: removing table-wrap nested in sec/p tag
#  Note: removing fig nested in sec/p tag
#  Parsing 9. PMC6358588
#  Note: removing fig nested in sec/p tag
#  Parsing 10. PMC6358589
#  Note: removing table-wrap nested in sec/p tag
#  Note: removing fig nested in sec/p tag
```

Combine the list of metadata and text into tables.

``` r
library(dplyr)
met <- bind_rows(met1)
names(txt1) <- met$PMCID
txt <- bind_rows(txt1, .id="PMCID")
met
#  # A tibble: 10 x 12
#     PMCID Title Authors  Year Journal Volume Pages `Published onli… `Date received` DOI   Publisher
#     <chr> <chr> <chr>   <int> <chr>   <chr>  <chr> <chr>            <chr>           <chr> <chr>    
#   1 PMC6… Endo… Dana B…  2018 ACG Ca… 5      e87   2018-12-5        2018-7-8        10.1… American…
#   2 PMC6… Chro… Scott …  2018 ACG Ca… 5      e94   2018-12-5        2018-5-5        10.1… American…
#   3 PMC6… Bile… Steffi…  2018 ACG Ca… 5      e88   2018-12-5        2018-5-7        10.1… American…
#   4 PMC6… New … Gordon…  2018 ACG Ca… 5      e92   2018-12-5        2018-3-3        10.1… American…
#   5 PMC6… Bile… Michae…  2018 ACG Ca… 5      e89   2018-12-5        2017-11-3       10.1… American…
#   6 PMC6… Fuso… Akshay…  2018 ACG Ca… 5      e99   2018-12-19       2018-3-8        10.1… American…
#   7 PMC6… Chor… Marcia…  2019 Genes … 20     56-68 2018-1-24        2017-9-1        10.1… Nature P…
#   8 PMC6… The … Tao Zh…  2019 Spinal… 57     141-… 2018-8-8         2017-12-19      10.1… Nature P…
#   9 PMC6… Natu… Marjol…  2019 Molecu… 20     115-… 2018-12-16       2018-10-22      10.1… Elsevier 
#  10 PMC6… Pred… Yury O…  2019 Molecu… 20     63-78 2018-11-16       2018-9-10       10.1… Elsevier 
#  # … with 1 more variable: Issue <chr>
txt
#  # A tibble: 1,083 x 5
#     PMCID    section    paragraph sentence text                                                      
#     <chr>    <chr>          <int>    <int> <chr>                                                     
#   1 PMC6358… Title              1        1 Endoscopic versus Surgical Intervention for Jejunal Bezoa…
#   2 PMC6358… Abstract           1        1 Bezoar-induced small bowel obstruction is a rare entity, …
#   3 PMC6358… Abstract           1        2 The cornerstone of treatment for intestinal bezoars has b…
#   4 PMC6358… Abstract           1        3 We present a patient with obstructive jejunal phytobezoar…
#   5 PMC6358… Introduct…         1        1 Bezoars are aggregates of undigested foreign material tha…
#   6 PMC6358… Introduct…         1        2 There are currently four classifications of bezoars: phyt…
#   7 PMC6358… Introduct…         1        3 Endoscopic treatment of bezoars causing intestinal obstru…
#   8 PMC6358… Case Repo…         1        1 A 60-year old diabetic woman with a past cholecystectomy …
#   9 PMC6358… Case Repo…         1        2 Physical examination revealed mild diffuse abdominal tend…
#  10 PMC6358… Case Repo…         1        3 Computed tomography (CT) of the abdomen and pelvis reveal…
#  # … with 1,073 more rows
```
