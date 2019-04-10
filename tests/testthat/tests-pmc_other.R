context("Parse other")

doc <-xml2::read_xml(system.file("extdata/PMC2231364.xml", package = "tidypmc"))
doc2 <- xml2::read_xml("<p>This is some text</p>")

test_that("pmc_caption works", {
    expect_is(pmc_caption(doc), "tbl_df")
    expect_error(pmc_caption("a vector") )
    expect_equal(pmc_caption(doc2), NULL)
})

test_that("pmc_reference works", {
    expect_is(pmc_reference(doc), "tbl_df")
    expect_error(pmc_reference("a vector") )
    expect_equal(pmc_reference(doc2), NULL)
})

test_that("pmc_metadata works", {
    expect_is(pmc_metadata(doc), "list")
    expect_error(pmc_metadata("a vector") )
    expect_equal(pmc_metadata(doc2), NULL)
})

test_that("pmc_xml works", {
    expect_error(pmc_xml("not ID"))
})
