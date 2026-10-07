"""Render one report per institution, plus an index page that links them.

    python scripts/render_all.py              # every eligible institution in Maryland
    python scripts/render_all.py --state VA

Each report is report.qmd rendered with a different `unitid` parameter. The
list of institutions comes from the `report_universe` view in sql/model.sql.
Output goes to reports/.
"""

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "reports"
RSTUDIO_QUARTO = "/usr/lib/rstudio/resources/app/bin/quarto/bin/quarto"


def find_quarto() -> str:
    quarto = os.environ.get("QUARTO") or shutil.which("quarto")
    if not quarto and Path(RSTUDIO_QUARTO).exists():
        quarto = RSTUDIO_QUARTO
    if not quarto:
        sys.exit("Quarto not found. Install it from https://quarto.org or set QUARTO=/path/to/quarto.")
    return quarto


def render(quarto: str, source: str, output: str, *args: str) -> None:
    """Render one document into reports/, sharing one copy of the JS/CSS libraries."""
    env = {**os.environ, "QUARTO_PYTHON": sys.executable}
    subprocess.run(
        [quarto, "render", source, "--output", output, "--quiet", *args],
        cwd=ROOT, env=env, check=True,
    )
    shutil.move(ROOT / output, OUT / output)
    libs = ROOT / f"{Path(source).stem}_files"
    shutil.copytree(libs, OUT / libs.name, dirs_exist_ok=True)
    shutil.rmtree(libs)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--state", default="MD", help="two-letter state abbreviation (default: MD)")
    state = parser.parse_args().state.upper()

    os.chdir(ROOT)
    con = duckdb.connect()
    con.execute((ROOT / "sql" / "model.sql").read_text())
    institutions = con.execute(
        "SELECT unitid, inst_name, report_file FROM report_universe WHERE state_abbr = ? ORDER BY inst_name",
        [state],
    ).fetchall()
    if not institutions:
        sys.exit(f"No eligible institutions in {state}.")

    quarto = find_quarto()
    shutil.rmtree(OUT, ignore_errors=True)
    OUT.mkdir()

    for n, (unitid, name, report_file) in enumerate(institutions, start=1):
        print(f"[{n}/{len(institutions)}] {name}", flush=True)
        render(quarto, "report.qmd", report_file, "-P", f"unitid:{unitid}", "-M", f"title:{name}")

    print("index", flush=True)
    render(quarto, "index.qmd", "index.html", "-P", f"state:{state}")
    print(f"Done: {len(institutions)} reports in {OUT.relative_to(ROOT)}/ (open reports/index.html)")


if __name__ == "__main__":
    main()
