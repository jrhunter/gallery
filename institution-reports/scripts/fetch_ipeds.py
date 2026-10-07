"""Pull an IPEDS snapshot from the Urban Institute Education Data Portal.

Writes one Parquet file per table into data/. The reports never touch the
network: they query these files with DuckDB, so a render is reproducible from
the committed snapshot. Re-run this script only to refresh the snapshot.

    python scripts/fetch_ipeds.py                # 2013-2023
    python scripts/fetch_ipeds.py 2015 2023      # first and last year

Docs: https://educationdata.urban.org/documentation/colleges.html
"""

import json
import sys
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import duckdb
import pandas as pd

API = "https://educationdata.urban.org/api/v1/college-university/ipeds"
DATA = Path(__file__).resolve().parents[1] / "data"

DIRECTORY_COLUMNS = [
    "unitid", "year", "inst_name", "city", "state_abbr", "inst_control",
    "institution_level", "sector", "hbcu", "degree_granting",
    "cc_basic_2021", "url_school",
]


def fetch(path: str) -> list[dict]:
    """Return every record for one endpoint, following the API's paging."""
    url, records = f"{API}/{path}", []
    while url:
        for attempt in range(4):
            try:
                with urllib.request.urlopen(url, timeout=180) as resp:
                    payload = json.load(resp)
                break
            except OSError:
                if attempt == 3:
                    raise
                time.sleep(5 * (attempt + 1))
        records += payload["results"]
        url = payload["next"]
    print(f"  {path}  ->  {len(records):,} rows", flush=True)
    return records


def fetch_years(template: str, years: range) -> pd.DataFrame:
    with ThreadPoolExecutor(max_workers=4) as pool:
        pages = pool.map(fetch, [template.format(year=y) for y in years])
    return pd.DataFrame([row for page in pages for row in page])


def write(name: str, df: pd.DataFrame) -> None:
    out = DATA / f"{name}.parquet"
    duckdb.sql(f"COPY (SELECT * FROM df ORDER BY ALL) TO '{out}' (FORMAT parquet)")
    print(f"wrote {out.relative_to(DATA.parent)} ({len(df):,} rows)")


def main() -> None:
    first, last = (int(a) for a in sys.argv[1:3]) if len(sys.argv) >= 3 else (2013, 2023)
    years = range(first, last + 1)
    DATA.mkdir(exist_ok=True)

    # Institution characteristics, latest year only.
    directory = pd.DataFrame(fetch(f"directory/{last}/"))[DIRECTORY_COLUMNS]
    write("directory", directory)

    # Graduation rates for the bachelor's-seeking cohort (subcohort 2) at 150%
    # of normal time. All years for the total; race/ethnicity for the latest.
    grad_total = fetch_years("grad-rates/{year}/?subcohort=2&sex=99&race=99", years)
    grad_race = pd.DataFrame(fetch(f"grad-rates/{last}/?subcohort=2&sex=99"))
    grad = pd.concat([grad_total, grad_race[grad_race["race"] != 99]])
    write("grad_rates", grad)

    # Total fall headcount: all levels of study, all students.
    write("fall_enrollment", fetch_years(
        "fall-enrollment/{year}/99/race/sex/?race=99&sex=99&ftpt=99", years))

    # First-to-second-year retention of full-time first-time students.
    write("fall_retention", fetch_years("fall-retention/{year}/?ftpt=1", years))


if __name__ == "__main__":
    main()
