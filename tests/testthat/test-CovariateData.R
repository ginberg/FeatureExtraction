# This file covers the code in CovariateData.R. View coverage for this file using
#library(testthat); library(FeatureExtraction)
#covr::file_report(covr::file_coverage("R/CovariateData.R", "tests/testthat/test-CovariateData.R"))

connectionDetails <- Eunomia::getEunomiaConnectionDetails()
Eunomia::createCohorts(connectionDetails)

test_that("test CovariateData Class on Empty", {

  #create 4 scenarios of Covariate Data
  #1) error (non class), 2) covariate data, 3) aggregatedCovariate Data,
  #4) temporalCovariate Data

  errCovData <- list()

  covData <- FeatureExtraction:::createEmptyCovariateData(cohortId = 9999,
                                                          aggregated = FALSE,
                                                          temporal = FALSE)
  aggCovData <- FeatureExtraction:::createEmptyCovariateData(cohortId = 9999,
                                                             aggregated = TRUE,
                                                             temporal = FALSE)

  tempCovData <- FeatureExtraction:::createEmptyCovariateData(cohortId = 9999,
                                                                aggregated = FALSE,
                                                                temporal = TRUE)

  #check that objects are covariate Data class
  expect_false(isCovariateData(errCovData))
  expect_true(isCovariateData(covData))
  expect_true(isCovariateData(aggCovData))
  expect_true(isCovariateData(tempCovData))

  #check that objects are aggregate covariate data class
  expect_error(isAggregatedCovariateData(errCovData))
  expect_false(isAggregatedCovariateData(covData))
  expect_true(isAggregatedCovariateData(aggCovData))
  expect_false(isAggregatedCovariateData(tempCovData))


  #check that objects are temporal covariate data class
  expect_error(isTemporalCovariateData(errCovData))
  expect_false(isTemporalCovariateData(covData))
  expect_false(isTemporalCovariateData(aggCovData))
  expect_true(isTemporalCovariateData(tempCovData))

  Andromeda::close(covData)
  Andromeda::close(aggCovData)
  Andromeda::close(tempCovData)
})

test_that("test saveCovariateData", {
  saveFileTest <- tempfile("covDatSave")
  settings <- createDefaultCovariateSettings()
  covariateData <- getDbCovariateData(connectionDetails = connectionDetails,
                                      cdmDatabaseSchema = "main",
                                      cohortDatabaseSchema = "main",
                                      cohortId = 1,
                                      covariateSettings = settings,
                                      aggregated = FALSE)
  #create error for test
  errCovData <- list()

  expect_error(saveCovariateData()) #empty call error
  expect_error(saveCovariateData(covariateData)) #no file error
  expect_error(saveCovariateData(errCovData, file = saveFileTest)) #non covariateData class error
  expect_message(saveCovariateData(covariateData, file = saveFileTest),
                        "Disconnected Andromeda. This data object can no longer be used")
  Andromeda::close(covariateData)
  unlink(saveFileTest)
})

test_that("test summary call for covariateData class", {
  settings <- createDefaultCovariateSettings()
  covariateData <- getDbCovariateData(connectionDetails = connectionDetails,
                                      cdmDatabaseSchema = "main",
                                      cohortDatabaseSchema = "main",
                                      cohortId = 1,
                                      covariateSettings = settings,
                                      aggregated = FALSE)

  sumOut <- summary(covariateData)
  Andromeda::close(covariateData)
  expect_equal(sumOut$metaData$cohortId, 1L)
})

test_that("test loadCovariateData", {
  expect_error(loadCovariateData("errorPath"))
})

test_that("Test exit/warning conditions", {
  # Empty Directory test
  tempDir <- tempdir()
  expect_error(loadCovariateData(file = tempDir))
  on.exit(unlink(tempDir))
  
  # ReadOnly parameter depreciated  
  cvData <- FeatureExtraction:::createEmptyCovariateData(cohortId = 1, aggregated = FALSE, temporal = FALSE)
  tempFile <- tempfile()
  tempFileName <- paste0(tempFile, ".zip")
  saveCovariateData(cvData, tempFileName)
  expect_warning(loadCovariateData(file = tempFileName, readOnly = TRUE))
  on.exit(unlink(tempFileName))
  on.exit(rm(cvData))
})

test_that("Test show method", {
  cvData <- FeatureExtraction:::createEmptyCovariateData(cohortId = 1, aggregated = FALSE, temporal = FALSE)
  expect_invisible(show(cvData))
  on.exit(rm(cvData))
})

unlink(connectionDetails$server())