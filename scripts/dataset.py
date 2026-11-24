#!/usr/bin/env python3
"""Import or validate the pinned Microsoft AdventureWorksDW sample."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "db"
BASE_URL = "https://raw.githubusercontent.com/microsoft/sql-server-samples"
SOURCE_DIR = "samples/databases/adventure-works/data-warehouse-install-script"
CACHE = ROOT / ".cache" / "adventureworksdw"
PSQL = [
    "docker", "compose", "exec", "-T", "postgres", "sh", "-ec",
    'PGCLIENTENCODING=UTF8 exec psql -X -w -v ON_ERROR_STOP=1 '
    '-U "$POSTGRES_USER" -d "$POSTGRES_DB"',
]
COPY_ESCAPES = str.maketrans({"\\": r"\\", "\t": r"\t", "\r": r"\r", "\n": r"\n"})


def read_source(revision, name, expected_sha256):
    cache_dir = CACHE / revision
    cache_dir.mkdir(parents=True, exist_ok=True)
    path = cache_dir / f"{name}.csv"
    cached = path.exists()
    if cached:
        data = path.read_bytes()
    else:
        url = f"{BASE_URL}/{revision}/{SOURCE_DIR}/{name}.csv"
        with urlopen(url, timeout=60) as response:
            data = response.read()
    actual = hashlib.sha256(data).hexdigest()
    if actual != expected_sha256:
        location = str(path) if cached else url
        raise ValueError(f"SHA-256 mismatch for {location}: {actual} != {expected_sha256}")
    if not cached:
        with tempfile.NamedTemporaryFile(dir=cache_dir, delete=False) as output:
            temp_path = Path(output.name)
            try:
                output.write(data)
                output.close()
                temp_path.replace(path)
            finally:
                temp_path.unlink(missing_ok=True)
    return data


def write_copy(output, name, spec, data):
    expected_nuls = {int(col): count for col, count in spec.get("nul_as_empty", {}).items()}
    hex_columns = set(spec.get("hex_columns", []))
    nuls = Counter()
    lines = data.decode("utf-8", errors="strict").split("\n")
    if lines.pop() != "" or len(lines) != spec["rows"]:
        raise ValueError(f"{name}: expected {spec['rows']} LF-terminated records")
    output.write(f"COPY {name.lower()} FROM STDIN;\n")
    for row_number, line in enumerate(lines, 1):
        fields = line.removesuffix("\r").split("|")
        if len(fields) != spec["columns"]:
            raise ValueError(f"{name}:{row_number}: expected {spec['columns']} fields")
        encoded = []
        for column, value in enumerate(fields, 1):
            if value == "":
                encoded.append(r"\N")
                continue
            if "\0" in value:
                if value != "\0" or column not in expected_nuls:
                    raise ValueError(f"{name}:{row_number}:{column}: unexpected NUL")
                nuls[column] += 1
                value = ""
            if column in hex_columns:
                if re.fullmatch(r"(?:[0-9A-Fa-f]{2})+", value) is None:
                    raise ValueError(f"{name}:{row_number}:{column}: invalid binary hex")
                value = r"\x" + value
            encoded.append(value.translate(COPY_ESCAPES))
        output.write("\t".join(encoded) + "\n")
    if nuls != expected_nuls:
        raise ValueError(f"{name}: unexpected NUL counts {dict(nuls)}, expected {expected_nuls}")
    if nuls:
        print(f"{name}: mapped standalone NUL to empty text, counts by column {dict(nuls)}",
              file=sys.stderr)
    output.write("\\.\n")


def run_psql(sql):
    sql.seek(0)
    subprocess.run(PSQL, cwd=ROOT, stdin=sql, check=True)


def import_dataset():
    manifest = json.loads((DB / "source.json").read_text(encoding="utf-8"))
    revision = manifest["revision"]
    if not re.fullmatch(r"[0-9a-f]{40}", revision):
        raise ValueError("Expected a full source commit SHA")
    marker = f"Microsoft AdventureWorksDW {revision}"
    # Prepare and verify every input before sending any SQL to PostgreSQL.
    with tempfile.TemporaryFile(mode="w+", encoding="utf-8", newline="\n") as sql:
        sql.write(f"""BEGIN;
SET LOCAL DateStyle TO 'ISO, YMD';
SELECT pg_advisory_xact_lock(41917, 1);
SELECT EXISTS (
    SELECT FROM pg_catalog.pg_namespace WHERE nspname = 'awdw'
) AS schema_exists
\\gset
\\if :schema_exists
DO $$
BEGIN
    IF pg_catalog.obj_description('awdw'::regnamespace, 'pg_namespace')
        IS DISTINCT FROM '{marker}' THEN
        RAISE EXCEPTION 'Existing awdw schema is not marked as this dataset revision';
    END IF;
END
$$;
\\echo Dataset already imported. Validating existing data.
""")
        # psql cannot skip inline COPY payloads in a conditional branch.
        # On repeat imports, shadow the persistent tables with temporary ones.
        for name in manifest["tables"]:
            table = name.lower()
            sql.write(f"CREATE TEMP TABLE {table} (LIKE awdw.{table}) ON COMMIT DROP;\n")
        sql.write("\\else\n")
        sql.write((DB / "schema.sql").read_text(encoding="utf-8"))
        sql.write(f"COMMENT ON SCHEMA awdw IS '{marker}';\n\\endif\n")
        sql.write("SET LOCAL search_path TO pg_temp, awdw, pg_catalog;\n")
        for name, spec in manifest["tables"].items():
            data = read_source(revision, name, spec["sha256"])
            write_copy(sql, name, spec, data)
        sql.write((DB / "validate.sql").read_text(encoding="utf-8"))
        sql.write("COMMIT;\n")
        run_psql(sql)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("import", "validate"))
    args = parser.parse_args()
    try:
        if args.action == "import":
            import_dataset()
        else:
            with (DB / "validate.sql").open("rb") as sql:
                run_psql(sql)
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        sys.exit(f"{args.action} failed: {exc}")


if __name__ == "__main__":
    main()
