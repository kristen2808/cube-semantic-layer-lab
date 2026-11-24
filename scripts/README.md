# Scripts

Start PostgreSQL using the [quick start](../README.md). Run the following from the repo root.

```sh
python3 scripts/dataset.py import
python3 scripts/dataset.py validate
```

[dataset.py](dataset.py) downloads the pinned Microsoft files and checks SHA-256 on every run, including cache hits. Downloads are stored in `.cache/adventureworksdw/`, which Git ignores. If a checksum fails, check the reported file and remove that cached copy to download it again.

The import uses one transaction to create the schema, load the files, and validate the data. A failed import rolls back. Running it again with the same revision uses temporary tables and checks the existing data. An existing schema marked for a different revision or with no revision marker stops the import. To load a fresh copy, use a separate empty database.

Source files use UTF-8 and pipe separators. Empty fields become SQL `NULL`. The script reports the 287 standalone NULs in each of `spanishproductname` and `frenchproductname` and maps them to empty strings. It rejects unexpected NULs, invalid UTF-8 or image hex, and incorrect field counts.

## Expected results

[validate.sql](../db/validate.sql) checks row counts and primary key uniqueness in all ten tables and checks all 12 foreign-key relationships.

| Check | Expected |
|---|---:|
| Sales order lines | 60,398 |
| `SUM(salesamount)` | 29,358,677.2207 |
| `SUM(orderquantity)` | 60,398 |
