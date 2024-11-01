test_that("testing differential proportions works", {
  Block <- c(1, 1, 2, 3, 3, 4, 1, 1, 2, 3, 3, 4)
  Treat <- factor(rep(c("ctrl", "drug"), each = 6))
  Time <- rep(rep(1:2, each = 3), 2)
  nbarcodes <- 50
  nsamples <- 12
  count <- matrix(rnorm(nbarcodes * nsamples), nbarcodes, nsamples) |> abs()
  rownames(count) <- paste0("Barcode", 1:nbarcodes)
  Barbie <- createBarbie(count, data.frame(Treat = Treat, Time = Time))

  resultStat <- testDiffProp(
    Barbie = Barbie,
    mycontrasts = c(-1, 1, 0),
    contrastLevels = c("ctrl", "drug"),
    designMatrix = model.matrix(~ 0 + Treat + Time),
    transformation = "asin-sqrt",
    block = Block
  )
  expect_equal(rownames(resultStat), rownames(Barbie$proportion))

  resultStat2 <- testDiffProp(
    Barbie = Barbie,
    mycontrasts = c(0, 0, 1),
    designMatrix = model.matrix(~ 0 + Treat + Time),
    transformation = "asin-sqrt",
    block = Block
  )
  expect_equal(rownames(resultStat2), rownames(Barbie$proportion))
  
})

test_that("testing differential occurrence works", {
  Block <- c(1, 1, 2, 3, 3, 4, 1, 1, 2, 3, 3, 4)
  Treat <- factor(rep(c("ctrl", "drug"), each = 6))
  Time <- rep(rep(1:2, each = 3), 2)
  nbarcodes <- 50
  nsamples <- 12
  count <- matrix(rnorm(nbarcodes * nsamples), nbarcodes, nsamples) |> abs()
  rownames(count) <- paste0("Barcode", 1:nbarcodes)
  Barbie <- createBarbie(count, data.frame(Treat = Treat, Time = Time))

  resultStat <- testDiffOcc(
    Barbie = Barbie,
    regularization = "firth",
    mycontrasts = c(-1, 1, 0),
    contrastLevels = c("ctrl", "drug"),
    designMatrix = model.matrix(~ 0 + Treat + Time)
  )
  expect_equal(rownames(resultStat), rownames(Barbie$occurrence))
  
  ## check one factor
  resultStat <- testDiffOcc(
    Barbie = Barbie,
    regularization = "firth",
    mycontrasts = c(-1, 1),
    contrastLevels = c("ctrl", "drug"),
    designMatrix = model.matrix(~ 0 + Treat)
  )
  
  resultStat <- testDiffOcc(
    Barbie = Barbie,
    regularization = "firth",
    mycontrasts = c(1),
    designMatrix = model.matrix(~ 0 + Time)
  )
  
  ## this will cause warings, because of 
  resultStat <- testDiffOcc(
    Barbie = Barbie,
    regularization = "firth",
    mycontrasts = c(1, 0, 0),
    designMatrix = model.matrix(~ 0+ Time + Treat)
  )

})

test_that("barcode test extracting correct arguments, dispatching right function", {
  Block <- c(1, 1, 2, 3, 3, 4, 1, 1, 2, 3, 3, 4)
  Treat <- factor(rep(c("ctrl", "drug"), each = 6))
  Time <- rep(rep(seq_len(2), each = 3), 2)
  nbarcodes <- 50
  nsamples <- 12
  count <- matrix(rnorm(nbarcodes * nsamples), nbarcodes, nsamples) |> abs()
  rownames(count) <- paste0("Barcode", seq_len(nbarcodes))
  Barbie <- createBarbie(count, data.frame(Treat = Treat, Time = Time))

  testBB1 <- testBarcodeBias(Barbie, sampleGroups = "Treat")
  testBB11 <- testBarcodeBias(
    Barbie,
    sampleGroups = "Treat",
    contrastLevels = c("ctrl", "drug")
  )
  testBB111 <- testBarcodeBias(
    Barbie,
    sampleGroups = "Treat",
    contrastLevels = c("drug", "ctrl")
  )
  expect_equal(
    testBB11$testBarcodes$diffProp_Treat$results$direction,
    testBB111$testBarcodes$diffProp_Treat$results$direction
  )

  testBB1111 <- testBarcodeBias(Barbie,
    sampleGroups = "Treat", contrastLevels = c("drug", "ctrl"),
    designFormula = formula("~0 + Treat + Time")
  )
  testBB11111 <- testBarcodeBias(Barbie,
    sampleGroups = "Treat", contrastLevels = c("drug", "ctrl"),
    designMatrix = model.matrix(~ 0 + Treat + Time)
  )
  expect_equal(
    testBB1111$testBarcodes$diffProp_Treat$result,
    testBB11111$testBarcodes$diffProp_Treat$result
  )
  
  ## confirm `targets` is updated; design matrix and formula are updated accordingly
  testBB12 <- testBarcodeBias(Barbie,
    sampleGroups = "Treat", contrastLevels = c("drug", "ctrl"),
    targets = data.frame(Treat = Treat)
  )
  expect_equal(colnames(testBB12$testBarcodes$diffProp_Treat$targets), "Treat")
  expect_equal(
    as.character(testBB12$testBarcodes$diffProp_Treat$methods$formula), 
    "~0 + Treat")
  
  ## with specified `designMatrix` used for test, should expect not using default formula
  testBB13 <- testBarcodeBias(Barbie,
    sampleGroups = "Treat", contrastLevels = c("drug", "ctrl"),
    designMatrix = model.matrix(~ 0 + Treat)
  )
  expect_equal(testBB13$testBarcodes$diffProp_Treat$methods$formula, "NA")
  expect_equal(
    testBB13$testBarcodes$diffProp_Treat$methods$design, 
    model.matrix(~ 0 + Treat), ignore_attr=TRUE)
  
  ## with specified `designFormula`, should expect updated formula and `designMatrix`
  testBB14 <- testBarcodeBias(Barbie,
    sampleGroups = "Treat", contrastLevels = c("drug", "ctrl"),
    designFormula = formula("~ 0 + Treat")
  )
  expect_equal(
    testBB14$testBarcodes$diffProp_Treat$methods$design, 
    model.matrix(~ 0 + Treat), ignore_attr=TRUE)

  testBB2 <- testBarcodeBias(Barbie, sampleGroups = "Time")

  testBB3 <- testBarcodeBias(
    Barbie, sampleGroups = "Time", method = "diffOcc",
    designFormula = formula("~ 0 + Time + Treat"))
  
  testBB4 <- testBarcodeBias(
    Barbie, sampleGroups = "Time", method = "diffOcc",
    designFormula = formula("~ 0 + Time"))

  testBB <- testBarcodeBias(Barbie, sampleGroups = rep(seq_len(4), each = 3))
})
