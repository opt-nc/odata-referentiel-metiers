# `odata-referentiel-metiers`

## 📖 Context
This repository contains the generation pipeline for the OPT-NC job reference framework.
The project transforms structured business data into a DuckDB database, then generates AsciiDoc and PDF documents.

## 🎯 What the Project Does
- Loads business data from `src/duck.sql` and `src/sqlite.sql` into a DuckDB and a SQLite database.
- Automatically builds a directory of professions, job families, and skills.
- Writes an AsciiDoc file (`data/output/doc/referentiel_metiers.adoc`).
- Produces documentation files and CSV exports.

## 💡 Why This Project Exists
Automated generation helps maintain a single source of truth, ensures consistency across job descriptions, and reduces the risk of manual errors.
By reusing a database and a Python script to produce the documentation, the reference framework can be updated simply by modifying the source data.

## 📂 Repository Structure
- `src/duck.sql`: SQL script to build the DuckDB database
- `src/sqlite.sql`: SQL script to build the SQLite file
- `src/generate-adoc.py`: Python script that reads DuckDB and generates the AsciiDoc file
- `data/input/`: CSV files and input data
- `data/output/csv/`: Generated CSV exports
- `data/output/doc/`: Generated documentation (AsciiDoc and PDF)
- `etc/themes/pdf-theme.yml`: PDF formatting theme for Asciidoctor
- `Taskfile.yml`: Execute automated tasks with only one command line

## ⚙️ Prerequisites
- Python 3.14.5+
- `duckdb` to load the main database
- `uv` to execute tasks (`pip install uv`)
- `sqlite3` command-line interface
- `schemacrawler` to generate database schema documentation
- `asciidoctor-pdf` to convert AsciiDoc into PDF
- `task` (not strictly necessary, but useful to avoid typing long commands)

## 🚀 How to Generate the Documentation files
1. Install the `uv` dependency:

```bash
pip install uv
```

2. Initialize the project and add the DuckDB dependency:

```bash
uv init --bare
uv add -r requirements.txt
```

3. Build the DuckDB and SQLite databases:

```bash
mkdir -p dist
mkdir -p data/output
duckdb dist/ref-metiers-opt-nc.duckdb < src/duck.sql
sqlite3 dist/ref-metiers-opt-nc.sqlite < src/sqlite.sql
```

4. Generate the complete documentation (using Taskfile is recommended):

```bash
task doc
```

OR OTHERWISE, you can generate the Documentation files with a single command:
```bash
task
```

## 📦 What the Generation Produces
- `dist/ref-metiers-opt-nc.duckdb` : Built DuckDB database
- `dist/ref-metiers-opt-nc.sqlite` : Built SQLite database
- `data/output/doc/referentiel_metiers.adoc` : AsciiDoc source of the reference framework
- `dist/ref-metiers-opt-nc-schema.html` : HTML documentation of the schema
- `dist/ref-metiers-opt-nc-schema.png` : PNG image of the schema
- `dist/ref-metiers-opt-nc-schema.pdf` : PDF format of the schema
- `data/output/doc/referentiel_metiers.pdf` : Final PDF document (via Asciidoctor)
- And the exported CSVs from DuckDB located in `data/output/csv/`

## 🛠️ And you can also modify the Reference Framework !
- Update the CSV sources in `data/input/` or the SQL in `src/duck.sql`
- Run `uv task duckdb` or `task duckdb` to rebuild the database
- Run `uv task doc` or `task doc` to regenerate the documents

## Notes
- The `src/generate-adoc.py` script reads the DuckDB database and builds a structured document featuring job families, active professions, and skills classified by group.
- This makes the generation reproducible and maintains a clear history of data sources and the final output.
