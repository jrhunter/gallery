# Data visualization gallery

Work samples by James Robert Hunter.

## Contents

1. [Survey of Law Student Well-Being dashboard](#survey-of-law-student-well-being-dashboard)
2. [NAEP state comparisons](#naep-state-comparisons)
3. [IPEDS institution outcome reports](#ipeds-institution-outcome-reports)
4. [Research example](#research-example)

## Survey of Law Student Well-Being dashboard

An interactive Shiny dashboard, hosted by AccessLex.

**[Open the dashboard](https://accesslex.shinyapps.io/wellbeing/)**

## NAEP state comparisons

An interactive page asking which differences in 2024 state NAEP scores are
statistically meaningful. Users pick a state, a subject, and grade; the pageshows which states
scored significantly higher or lower, the range of ranks those differences
support, whether the state has recovered since 2019, and how scores moved from
the 10th to the 90th percentile. Built with R, Quarto, and Observable Plot,
using significance tests published by NCES.

**[Open the page](https://jrhunter.github.io/gallery/naep-differences/)** ·
[Source](https://github.com/jrhunter/gallery/blob/main/naep-differences/index.qmd)

<iframe src="https://jrhunter.github.io/gallery/naep-differences/"
        title="NAEP state comparisons"
        width="100%" height="700" style="border: 1px solid #d0d7de;"></iframe>

## IPEDS institution outcome reports

One parameterized Quarto report, rendered automatically once per institution.
Each report compares a four-year college or university with its national peers
on graduation, retention, and enrollment. The data is public IPEDS data, queried
with SQL in DuckDB and charted with Altair. The index below links to a report
for each of 27 Maryland institutions.

**[Open the reports](https://jrhunter.github.io/gallery/institution-reports/reports/index.html)** ·
[Source](https://github.com/jrhunter/gallery/tree/main/institution-reports)

<iframe src="https://jrhunter.github.io/gallery/institution-reports/reports/index.html"
        title="IPEDS institution outcome reports"
        width="100%" height="700" style="border: 1px solid #d0d7de;"></iframe>

## Research example

A reproducible R Markdown analysis asking whether educational attainment
predicts wages, using the Mroz (1987) data on married women's labor supply. It
covers data checks, the analytic sample, figures, and regression results, with
tables and figures built to Section 508 accessibility standards.

**[Open the analysis](https://jrhunter.github.io/gallery/Research-example/Hunter-code-sample.html)** ·
[Source](https://github.com/jrhunter/gallery/blob/main/Research-example/Hunter-code-sample.Rmd)

<iframe src="https://jrhunter.github.io/gallery/Research-example/Hunter-code-sample.html"
        title="Research example: education and wages"
        width="100%" height="700" style="border: 1px solid #d0d7de;"></iframe>
