# Pull NAEP state estimates and NCES significance tests from the NAEP Data
# Service API into data/.
#
#   Rscript scripts/fetch_naep.R
#
# Writes three files:
#   data/estimates.csv          average score, achievement levels, and percentiles
#   data/state_comparisons.csv  latest year: every jurisdiction tested against every other
#   data/year_comparisons.csv   every jurisdiction's latest year tested against earlier years
#
# The significance results are NCES's own, as the API returns them. Nothing is
# re-estimated here: the API does not publish standard errors.
#
# API documentation: https://www.nationsreportcard.gov/api_endpoint.aspx

suppressPackageStartupMessages({
  library(httr)
  library(jsonlite)
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(readr)
})

API   <- "https://www.nationsreportcard.gov/Dataservice/GetAdhocData.aspx"
YEARS <- c(2003, 2005, 2007, 2009, 2011, 2013, 2015, 2017, 2019, 2022, 2024)
LATEST <- max(YEARS)

# National public, the 50 states, DC, and the Department of Defense schools
JURISDICTIONS <- c("NP", state.abb, "DC", "DS")

ASSESSMENTS <- tribble(
  ~subject,      ~subject_label, ~subscale, ~grade,
  "mathematics", "Mathematics",  "MRPCM",   4,
  "mathematics", "Mathematics",  "MRPCM",   8,
  "reading",     "Reading",      "RRPCM",   4,
  "reading",     "Reading",      "RRPCM",   8
)

STATS <- c(
  mean = "MN:MN", pct_basic = "ALC:AB", pct_proficient = "ALC:AP",
  p10 = "PC:P1", p25 = "PC:P2", p50 = "PC:P5", p75 = "PC:P7", p90 = "PC:P9"
)
PERCENTILES <- STATS[c("p10", "p25", "p50", "p75", "p90")]

naep_get <- function(type, subject, subscale, grade, years, stats) {
  query <- list(
    type = type, subject = subject, grade = grade, subscale = subscale,
    variable = "TOTAL",
    jurisdiction = paste(JURISDICTIONS, collapse = ","),
    stattype = paste(stats, collapse = ","),
    Year = paste(years, collapse = ",")
  )
  # I() stops httr from percent-encoding the commas and colons the API expects
  resp <- RETRY("GET", API, query = map(query, \(x) I(as.character(x))), timeout(900), times = 4, pause_base = 15)
  stop_for_status(resp)
  result <- fromJSON(content(resp, as = "text", encoding = "UTF-8"))$result
  if (!is.data.frame(result)) stop("NAEP API: ", result)
  message(sprintf("  %-15s %-11s grade %d: %s rows", type, subject, grade, format(nrow(result), big.mark = ",")))
  as_tibble(result)
}

# Run one request per assessment and stack the results, labeled.
each_assessment <- function(type, years, stats) {
  pmap(ASSESSMENTS, function(subject, subject_label, subscale, grade) {
    naep_get(type, subject, subscale, grade, years, stats) |>
      mutate(subject = subject_label, grade = grade)
  }) |>
    list_rbind()
}

stat_name <- function(code) names(STATS)[match(code, STATS)]
jurisdiction_name <- function(code, label) {
  case_when(code == "NP" ~ "National public", code == "DS" ~ "DoDEA", .default = label)
}

dir.create("data", showWarnings = FALSE)

# 1. Estimates -----------------------------------------------------------------
message("Estimates")
estimates <- each_assessment("data", YEARS, STATS) |>
  filter(isStatDisplayable == 1) |>
  transmute(
    subject, grade, year,
    code = jurisdiction,
    jurisdiction = jurisdiction_name(jurisdiction, jurisLabel),
    stat = stat_name(stattype),
    value = round(value, 2)
  ) |>
  pivot_wider(names_from = stat, values_from = value) |>
  select(subject, grade, year, code, jurisdiction, all_of(names(STATS))) |>
  arrange(subject, grade, year, code)
write_csv(estimates, "data/estimates.csv")

# 2. Jurisdiction against jurisdiction, latest year ----------------------------
# `result` describes the focal jurisdiction relative to the other one.
message("Cross-state comparisons")
state_comparisons <- each_assessment("sigacrossjuris", LATEST, STATS["mean"]) |>
  filter(isSigDisplayable == 1) |>
  transmute(
    subject, grade, year,
    focal = focalJurisdiction,
    other = targetJurisdiction,
    gap = round(gap, 2),
    result = tolower(sig)
  ) |>
  arrange(subject, grade, focal, other)
write_csv(state_comparisons, "data/state_comparisons.csv")

# 3. Latest year against earlier years -----------------------------------------
# The API returns every ordered pair of years; keep the latest year as focal.
# `result` describes the latest year relative to the earlier one.
message("Cross-year comparisons")
year_comparisons <- bind_rows(
  each_assessment("sigacrossyear", YEARS, STATS["mean"]),
  each_assessment("sigacrossyear", c(2019, 2022, LATEST), PERCENTILES)
) |>
  filter(focalYear == LATEST, isSigDisplayable == 1) |>
  transmute(
    subject, grade,
    code = jurisdiction,
    stat = stat_name(statType),
    year = focalYear,
    earlier_year = targetYear,
    gap = round(gap, 2),
    result = tolower(sig)
  ) |>
  arrange(subject, grade, code, stat, earlier_year)
write_csv(year_comparisons, "data/year_comparisons.csv")

message(sprintf(
  "Wrote %s estimates, %s cross-state tests, %s cross-year tests",
  format(nrow(estimates), big.mark = ","),
  format(nrow(state_comparisons), big.mark = ","),
  format(nrow(year_comparisons), big.mark = ",")
))
