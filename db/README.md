# Database

Docker Compose runs PostgreSQL 17 using `postgres:17-bookworm`, which supports Apple Silicon. The container is `cube-semantic-layer-lab-postgres-1`. Use `docker compose ps` to check that it is healthy.

Data lives in `cube-semantic-layer-lab_pgdata`. Running `docker compose down --volumes` deletes the volume and its data. Database credentials in `.env` are applied when PostgreSQL first initializes the volume.

## Source and schema

The dataset comes from the [official Microsoft AdventureWorksDW install files](https://github.com/microsoft/sql-server-samples/tree/b47eadc85277f72843647223cde53aa1b85ffcb8/samples/databases/adventure-works/data-warehouse-install-script). [source.json](source.json) pins the revision and SHA-256 checksums. Microsoft provides the sample under the [MIT license](MICROSOFT-LICENSE.txt).

[schema.sql](schema.sql) defines ten tables in `awdw`. Each row in `factinternetsales` is an order line, keyed by `(salesordernumber, salesorderlinenumber)`. The fact links to products, customers, territories, currencies, promotions, and the date dimension for order, due, and ship dates. Product categories and customer geography are included.

Table and column names use lowercase. Imported keys keep their original values and use no sequences. Text uses PostgreSQL collation. SQL Server `money` maps to `numeric(19,4)`, `float` to `double precision`, `datetime` to `timestamp(3) without time zone`, `tinyint` to a checked `smallint`, and `bit` to `boolean`. Image bytes are stored as `bytea`.

## DBeaver

Create a PostgreSQL connection with host `127.0.0.1`. Use the port, database, user, and password from `.env`. The default port, database, and user are `5432`, `adventureworksdw`, and `awdw`. If port `5432` is busy, set `POSTGRES_PORT=5433` in `.env` and use that port in DBeaver. Open the `awdw` schema after import.

See the [quick start](../README.md) and [import guide](../scripts/README.md).
