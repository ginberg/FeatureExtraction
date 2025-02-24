# View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/Normalization.R", "tests/testthat/test-tidyCovariates.R"))

connectionDetails <- Eunomia::getEunomiaConnectionDetails()

test_that("Test exit conditions ", {
  # Covariate Data object check
  expect_error(tidyCovariateData(covariateData = list()))
  # CovariateData object closed
  cvData <- FeatureExtraction:::createEmptyCovariateData(cohortId = 1,
                                                         aggregated = FALSE, 
                                                         temporal = FALSE)
  Andromeda::close(cvData)
  expect_error(tidyCovariateData(covariateData = cvData))
  # CovariateData aggregated
  cvData <- FeatureExtraction:::createEmptyCovariateData(cohortId = 1, 
                                                         aggregated = TRUE, 
                                                         temporal = FALSE)
  expect_error(tidyCovariateData(covariateData = cvData))
})

test_that("Test empty covariateData", {
  cvData <- FeatureExtraction:::createEmptyCovariateData(cohortId = 1,
                                                         aggregated = FALSE,
                                                         temporal = FALSE)
  result <- tidyCovariateData(covariateData = cvData)
  expect_equal(length(result$covariates$covariateId), length(cvData$covariates$covariateId))
})

test_that("tidyCovariates works", {
  # Generate some data:
  createCovariate <- function(i, analysisId) {
    return(tibble(covariateId = rep(i * 1000 + analysisId, i),
                          covariateValue = rep(1,i)))
  }
  covariates <- lapply(1:10, createCovariate, analysisId = 1)
  covariates <- do.call("rbind", covariates)
  covariates$rowId <- 1:nrow(covariates)
  metaData <- list(populationSize = nrow(covariates))
  frequentCovariate <- createCovariate(40, analysisId = 2)
  frequentCovariate$rowId <- sample.int(metaData$populationSize, nrow(frequentCovariate), replace = FALSE)
  infrequentCovariate <- createCovariate(1, analysisId = 3)
  infrequentCovariate$rowId <- sample.int(metaData$populationSize, nrow(infrequentCovariate), replace = FALSE)
  covariates <- rbind(covariates, frequentCovariate, infrequentCovariate)

  covariateRef <- tibble(covariateId = c(1:10 * 1000 + 1, 40002, 1003),
                                 analysisId = c(rep(1, 10), 2, 3))

  covariateData <- Andromeda::andromeda(covariates = covariates,
                                        covariateRef = covariateRef)
  attr(covariateData, "metaData") <- metaData
  class(covariateData) <- "CovariateData"

  tidy <- tidyCovariateData(covariateData, minFraction = 0.1, normalize = TRUE, removeRedundancy = TRUE)

  # Test: most prevalent covariate in analysis 1 is dropped:
  expect_true(nrow(filter(tidy$covariates, covariateId == 10001) %>% collect()) == 0)

  # Test: infrequent covariate in analysis 1 isn't dropped:
  expect_true(nrow(filter(tidy$covariates, covariateId == 1001) %>% collect()) != 0)

  # Test: infrequent covariate is dropped:
  expect_true(nrow(filter(tidy$covariates, covariateId == 1003) %>% collect()) == 0)

  # Test: frequent covariate isn't dropped:
  expect_true(nrow(filter(tidy$covariates, covariateId == 40002) %>% collect()) != 0)
})

test_that("tidyCovariateData on Temporal Data", {
  Eunomia::createCohorts(connectionDetails)
  covariateSettings <- createTemporalCovariateSettings(useDrugExposure = TRUE,
                                                       temporalStartDays = -2:-1,
                                                       temporalEndDays = -2:-1)
  covariateData <- getDbCovariateData(connectionDetails,
                                      cdmDatabaseSchema = "main",
                                      cohortId = 1,
                                      covariateSettings = covariateSettings)
  tidy <- tidyCovariateData(covariateData)
  expect_equal(length(tidy$analysisRef$analysisId), length(covariateData$analysisRef$analysisId))
})

unlink(connectionDetails$server())