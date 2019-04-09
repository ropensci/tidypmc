context("Parse text")

doc <- read_xml(system.file("extdata/PMC2231364.xml", package = "tidypmc"))
txt <- pmc_text(doc)
doc2 <- read_xml("<p>This is some text</p>")

test_that("path string formats", {
   x <- c("carnivores", "bears", "polar", "grizzly", "cats", "tiger")
   n <- c(1,2,3,3,2,3)
   expect_is(path_string(x, n), "character")
   expect_error(path_string(n, x))
})

test_that("pmc_text works", {
    expect_is(txt, "tbl_df")
    expect_error(pmc_text("a vector") )
    expect_equal(pmc_text(doc2), NULL)
})
