import os
import pandas as pd
from sqlalchemy import create_engine, text

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg2://postgres:postgres@localhost:5432/msat_traceability"
)

QUERY = """
SELECT
    supplier_name,
    total_lots,
    failed_lots,
    lot_failure_rate_pct,
    deviation_count,
    DENSE_RANK() OVER (
        ORDER BY lot_failure_rate_pct DESC, deviation_count DESC
    ) AS supplier_risk_rank
FROM vw_supplier_quality_scorecard
ORDER BY supplier_risk_rank;
"""

def main() -> None:
    engine = create_engine(DATABASE_URL)
    with engine.connect() as connection:
        scorecard = pd.read_sql(text(QUERY), connection)

    print(scorecard.to_string(index=False))
    scorecard.to_csv("supplier_quality_scorecard.csv", index=False)
    print("\nCreated supplier_quality_scorecard.csv")

if __name__ == "__main__":
    main()
