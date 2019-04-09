context("Parse tables")

doc <- read_xml(system.file("extdata/PMC2231364.xml", package = "tidypmc"))
doc2 <- read_xml("<p>This is some text</p>")
t1 <- pmc_table(doc)


test_that("pmc_table works", {
    expect_is(t1, "list")
    expect_error(pmc_table("a vector") )
    expect_equal(pmc_text(doc2), NULL)
})

test_that("collapse rows works", {
    expect_is(collapse_rows(t1), "tbl_df")
    expect_is(collapse_rows(t1[[1]]), "tbl_df")
    expect_error(collapse_rows("a vector") )
})

test_that("repeat subheading works", {
    expect_is(repeat_sub(t1[[1]]), "tbl_df")
    expect_error(repeat_sub("a vector") )
})
