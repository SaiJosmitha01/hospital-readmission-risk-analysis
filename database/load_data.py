"""Load the cleaned hospital encounter dataset into a local SQLite database."""

from pathlib import Path
import sqlite3

import pandas as pd


# Resolve every path from this script's location so it works from any directory.
PROJECT_ROOT = Path(__file__).resolve().parents[1]
CLEANED_CSV_PATH = PROJECT_ROOT / "data" / "processed" / "diabetic_data_cleaned.csv"
DATABASE_PATH = PROJECT_ROOT / "database" / "hospital_readmission.db"
TABLE_NAME = "encounters"


def validate_source_data(df: pd.DataFrame) -> None:
    """Validate the cleaned DataFrame before loading it into SQLite."""
    required_columns = {"encounter_id", "patient_nbr", "readmitted"}
    missing_columns = sorted(required_columns - set(df.columns))

    if missing_columns:
        raise ValueError(
            "The cleaned CSV is missing required columns: "
            + ", ".join(missing_columns)
        )

    if not df["encounter_id"].is_unique:
        duplicate_count = int(df["encounter_id"].duplicated().sum())
        raise ValueError(
            "encounter_id must be unique before loading into SQLite. "
            f"Found {duplicate_count:,} duplicate encounter_id values."
        )


def load_and_validate_database(df: pd.DataFrame) -> None:
    """Load the DataFrame into SQLite and validate the resulting table."""
    # SQLite is a lightweight relational database stored in a single local file.
    # A connection is the active link Python uses to send commands to the database.
    connection = sqlite3.connect(DATABASE_PATH)

    try:
        # A table stores related records in rows and fields in columns.
        df.to_sql(TABLE_NAME, connection, if_exists="replace", index=False)

        # Validate after loading to confirm the database matches the source DataFrame.
        total_rows = connection.execute(
            f'SELECT COUNT(*) FROM "{TABLE_NAME}"'
        ).fetchone()[0]
        total_columns = len(
            connection.execute(f'PRAGMA table_info("{TABLE_NAME}")').fetchall()
        )
        unique_encounters = connection.execute(
            f'SELECT COUNT(DISTINCT encounter_id) FROM "{TABLE_NAME}"'
        ).fetchone()[0]
        unique_patients = connection.execute(
            f'SELECT COUNT(DISTINCT patient_nbr) FROM "{TABLE_NAME}"'
        ).fetchone()[0]
        readmitted_counts = connection.execute(
            f"""
            SELECT readmitted, COUNT(*) AS encounter_count
            FROM "{TABLE_NAME}"
            GROUP BY readmitted
            ORDER BY encounter_count DESC
            """
        ).fetchall()

        print(f"Total rows in {TABLE_NAME}: {total_rows:,}")
        print(f"Total columns in {TABLE_NAME}: {total_columns:,}")
        print(f"Distinct encounter_id values: {unique_encounters:,}")
        print(f"Distinct patient_nbr values: {unique_patients:,}")
        print("Readmitted category counts:")
        for category, count in readmitted_counts:
            print(f"  {category}: {count:,}")

        if total_rows != len(df):
            raise RuntimeError(
                "SQLite row-count validation failed: "
                f"the DataFrame has {len(df):,} rows, but the database table has "
                f"{total_rows:,} rows."
            )
    finally:
        connection.close()


def main() -> None:
    """Read, validate, load, and verify the cleaned encounter data."""
    if not CLEANED_CSV_PATH.is_file():
        raise FileNotFoundError(
            "Cleaned CSV not found. Run the approved Phase 3 cleaning notebook first: "
            f"{CLEANED_CSV_PATH}"
        )

    df = pd.read_csv(CLEANED_CSV_PATH)
    validate_source_data(df)
    load_and_validate_database(df)

    print(f"Database path: {DATABASE_PATH}")
    print("SQLite database created and validated successfully.")


if __name__ == "__main__":
    main()
