# `odata-referentiel-metiers`

[![CI - Génération des fichiers et Release](https://github.com/opt-nc/odata-referentiel-metiers/actions/workflows/release.yml/badge.svg?branch=main)](https://github.com/opt-nc/odata-referentiel-metiers/actions/workflows/release.yml)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![GitHub release](https://img.shields.io/github/v/release/opt-nc/odata-referentiel-metiers?label=release)](https://github.com/opt-nc/odata-referentiel-metiers/releases)
[![Python](https://img.shields.io/badge/python-3.14.5%2B-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![DuckDB](https://img.shields.io/badge/DuckDB-1.5.3%2B-FFF000?logo=duckdb&logoColor=000000)](https://duckdb.org/)
[![SchemaCrawler](https://img.shields.io/badge/SchemaCrawler-17.11.1%2B-326CE5)](https://www.schemacrawler.com/)
[![Pandoc](https://img.shields.io/badge/Pandoc-3.9.0.2%2B-2F6F9F?logo=pandoc&logoColor=white)](https://pandoc.org/)
[![Asciidoctor PDF](https://img.shields.io/badge/Asciidoctor%20PDF-2.3.15%2B-E40046?logo=asciidoctor&logoColor=white)](https://docs.asciidoctor.org/pdf-converter/latest/)
[![Hugo](https://img.shields.io/badge/Hugo-0.163.0%2B-FF4088?logo=hugo&logoColor=white)](https://gohugo.io/)
[![Task](https://img.shields.io/badge/Task-3.50.0%2B-29BEB0?logo=task&logoColor=white)](https://taskfile.dev/)

## 📖 Context
This repository contains the generation pipeline for the OPT-NC job reference framework.
The project transforms structured business data into DuckDB and SQLite databases, then generates AsciiDoc, PDF, EPUB, CSV exports, schema documentation, and a Hugo website.

## 🎯 What the Project Does
- Loads business data from `src/duck.sql` and `src/sqlite.sql` into a DuckDB and a SQLite database.
- Automatically builds a directory of professions, job families, and skills.
- Writes an AsciiDoc file (`data/output/docs/referentiel_metiers.adoc`).
- Produces PDF and EPUB documentation and CSV files.
- Generates a Hugo website in `site/public/`.

## 💡 Why This Project Exists
Automated generation helps maintain a single source of truth, ensures consistency across job descriptions, and reduces the risk of manual errors.
By reusing a database and a Python script to produce the documentation, the reference framework can be updated simply by modifying the source data.

## 📂 Repository Structure
- `src/duck.sql`: SQL script to build the DuckDB database
- `src/sqlite.sql`: SQL script to build the SQLite file
- `src/generate-adoc.py`: Python script that reads DuckDB and generates the AsciiDoc file
- `src/generate-md.py`: Python script that reads DuckDB and generates the Hugo Markdown site content
- `data/input/`: CSV files and input data
- `data/output/csv/`: Generated CSV exports
- `data/output/docs/`: Generated documentation (AsciiDoc and PDF)
- `etc/themes/pdf-theme.yml`: PDF formatting theme for Asciidoctor
- `Taskfile.yml`: Execute automated tasks with only one command line

## ⚙️ Prerequisites
- Python 3.14.5+
- `duckdb` (1.5.3+) to load the main database
- `uv` (0.11.15+) to execute tasks (`pip install uv`)
- `sqlite3` command-line interface
- `schemacrawler` (17.11.1+) to generate database schema documentation
- `asciidoctor-pdf` (2.3.15+) to convert AsciiDoc into PDF
- `pandoc` (3.9.0.2+) to convert AsciiDoc to PDF
- `hugo` (0.163.0+) to generate the website
- `task` (3.50.0+) (not strictly necessary, but useful to avoid typing long commands)

## 🚀 How to Generate the Documentation files
The easiest and recommended way to install dependencies and generate all the files is to use [Task](https://taskfile.dev/). You can do everything with a single command:

```bash
task
```

OR, if you prefer to run the steps individually :

1. Build the DuckDB and SQLite databases:

```bash
task duckdb
```

2. Generate the complete documentation (using Taskfile is recommended):

```bash
task docs
```

3. Generate the Hugo website:

```bash
task site
```

This command creates the Hugo site in `site/`, generates the Markdown pages with `src/generate-md.py`, installs the Relearn theme, then builds the static website in `site/public/`.

## 📦 What the Generation Produces
- `dist/ref-metiers-opt-nc.duckdb` : Built DuckDB database
- `dist/ref-metiers-opt-nc.sqlite` : Built SQLite database
- `data/output/docs/referentiel_metiers.adoc` : AsciiDoc source of the reference framework
- `dist/ref-metiers-opt-nc-schema.html` : HTML documentation of the schema
- `dist/ref-metiers-opt-nc-schema.png` : PNG image of the schema
- `dist/ref-metiers-opt-nc-schema.pdf` : PDF format of the schema
- `data/output/docs/referentiel_metiers.pdf` : Final PDF document (via Asciidoctor)
- `site/public/` : Generated Hugo website
- And the exported CSVs from DuckDB located in `data/output/csv/`

## 🛠️ And you can also modify the Reference Framework !
- Update the CSV sources in `data/input/` or the SQL in `src/duck.sql`
- Run `task duckdb` to rebuild the database
- Run `task docs` to regenerate the documents
- Run `task site` to regenerate the Hugo website

## Notes
- The `src/generate-adoc.py` script reads the DuckDB database and builds a structured document featuring job families, active professions, and skills classified by group.
- The `src/generate-md.py` script uses the same DuckDB source to generate the Hugo pages, so the website stays aligned with the PDF and EPUB documentation.
- This makes the generation reproducible and maintains a clear history of data sources and the final output.
