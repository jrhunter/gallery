# Data visualization gallery

Work samples by James Robert Hunter.

A version with embedded figures and reports may be found [here](https://jrhunter.github.io/gallery/).

## Contents

1. [Survey of Law Student Well-Being dashboard](#survey-of-law-student-well-being-dashboard)
2. [NAEP state comparisons](#naep-state-comparisons)
3. [IPEDS institution outcome reports](#ipeds-institution-outcome-reports)
4. [Reproducible R workflow](#reproducible-r-workflow)

## Survey of Law Student Well-Being dashboard

An interactive dashboard that allows users to visualize the results of the 2021 Survey of Law Student Well-Being, featuring filtering, stratification, and the ability to display how respondents answered specific items based on their answers to other items.

**[Open the dashboard](https://accesslex.shinyapps.io/wellbeing/)**

## NAEP state comparisons

An interactive page asking which differences in 2024 state NAEP scores are statistically meaningful. Users pick a state, a subject, and grade; the page shows which states
scored significantly higher or lower, the range of ranks those differences
support, whether the state has recovered since 2019, and how scores moved from the 10th to the 90th percentile. Built with R, Quarto, and Observable Plot,
using significance tests published by NCES.

**[Open the page](https://jrhunter.github.io/gallery/naep-differences/)** ·
[Source](https://github.com/jrhunter/gallery/blob/main/naep-differences/index.qmd)


## IPEDS institution outcome reports

Parameterized Quarto reports rendered for each of 27 higher education
institutions in Maryland. Each report compares a four-year college or
university with its national peers on graduation, retention, and enrollment.
Based on public IPEDS data, queried with SQL in DuckDB and charted with Altair. 

**[Open the reports](https://jrhunter.github.io/gallery/institution-reports/reports/index.html)** ·
[Source](https://github.com/jrhunter/gallery/tree/main/institution-reports)

## Reproducible R workflow

A reproducible R Markdown analysis asking whether educational attainment
predicts wages, using Thomas Mroz's ([1987](https://doi.org/10.2307/1911029)) data on married women's labor supply. Includes data checks, the analytic sample, figures, and regression results, with
tables and figures meant to be as conformant to Section 508 accessibility standards as possible.

**[Open the analysis](https://jrhunter.github.io/gallery/Research-example/Hunter-code-sample.html)** ·
[Source](https://github.com/jrhunter/gallery/blob/main/Research-example/Hunter-code-sample.Rmd)

