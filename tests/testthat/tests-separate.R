context("Search text")

doc <- read_xml(system.file("extdata/PMC2231364.xml", package = "tidypmc"))
txt <- pmc_text(doc)

test_that("Separate text", {
 expect_is(separate_text(txt, "[ATCGN]{5,}"), "tbl_df")
 expect_equal(separate_text(txt, "missing string"), NULL)
})

test_that("Separate refs", {
 expect_is(separate_refs(txt), "tbl_df")
 # no refs in Abstract
 a1 <- separate_refs(dplyr::filter(txt, section=="Abstract"))
 expect_equal(a1, NULL)
})

test_that("Separate genes", {
 expect_is(separate_genes(txt), "tbl_df")
 a1 <- separate_genes(dplyr::filter(txt, section=="Conclusion"))
 expect_equal(a1, NULL)
})

test_that("Separate locus tags", {
 expect_is(separate_tags(txt, "YPO"), "tbl_df")
 a1 <- separate_tags(dplyr::filter(txt, section=="Abstract"), "YPO")
 expect_equal(a1, NULL)
})
