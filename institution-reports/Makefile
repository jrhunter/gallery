PY := .venv/bin/python
STATE ?= MD

.PHONY: setup data reports clean

setup:            ## create the virtualenv and install dependencies
	python3 -m venv .venv
	$(PY) -m pip install -q -r requirements.txt

data:             ## refresh the IPEDS snapshot in data/ (needs network)
	$(PY) scripts/fetch_ipeds.py

reports:          ## render one report per institution, plus the index
	$(PY) scripts/render_all.py --state $(STATE)

clean:
	rm -rf reports report_files index_files *.quarto_ipynb
