-- 1. End-to-end batch traceability
SELECT *
FROM vw_batch_material_traceability
ORDER BY process_start_date, batch_number, material_code;

-- 2. Supplier ranking with DENSE_RANK and NTILE
SELECT
    *,
    DENSE_RANK() OVER (
        ORDER BY lot_failure_rate_pct DESC, deviation_count DESC
    ) AS supplier_risk_rank,
    NTILE(4) OVER (
        ORDER BY lot_failure_rate_pct, deviation_count
    ) AS supplier_quality_quartile
FROM vw_supplier_quality_scorecard;

-- 3. Rolling three-lot failure rate
WITH lot_quality AS (
    SELECT
        rm.material_name,
        ml.material_lot_id,
        ml.received_date,
        MAX(CASE WHEN qt.test_status = 'Fail' THEN 1 ELSE 0 END) AS failed_lot
    FROM raw_materials rm
    JOIN material_lots ml ON rm.material_id = ml.material_id
    LEFT JOIN quality_tests qt ON ml.material_lot_id = qt.material_lot_id
    GROUP BY rm.material_name, ml.material_lot_id, ml.received_date
)
SELECT
    material_name,
    material_lot_id,
    received_date,
    failed_lot,
    ROUND(
        AVG(failed_lot::NUMERIC) OVER (
            PARTITION BY material_name
            ORDER BY received_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) * 100, 2
    ) AS rolling_3_lot_failure_rate_pct
FROM lot_quality;

-- 4. Recurrent deviation detection using LAG
WITH ordered_deviations AS (
    SELECT
        deviation_number,
        deviation_category,
        opened_date,
        LAG(opened_date) OVER (
            PARTITION BY deviation_category ORDER BY opened_date
        ) AS previous_occurrence_date
    FROM deviations
)
SELECT
    *,
    opened_date - previous_occurrence_date AS days_since_prior_occurrence
FROM ordered_deviations;

-- 5. Batch-level material risk score
WITH batch_risk AS (
    SELECT
        b.batch_number,
        b.batch_status,
        COUNT(DISTINCT u.material_lot_id) AS material_lot_count,
        SUM(CASE WHEN qt.test_status = 'Fail' THEN 1 ELSE 0 END) AS failed_tests,
        COUNT(DISTINCT d.deviation_id) AS deviation_count,
        SUM(u.quantity_wasted) AS total_waste
    FROM manufacturing_batches b
    JOIN batch_material_usage u ON b.batch_id = u.batch_id
    JOIN material_lots ml ON u.material_lot_id = ml.material_lot_id
    LEFT JOIN quality_tests qt ON ml.material_lot_id = qt.material_lot_id
    LEFT JOIN deviations d ON b.batch_id = d.batch_id
    GROUP BY b.batch_number, b.batch_status
)
SELECT
    *,
    failed_tests * 4
      + deviation_count * 3
      + CASE WHEN total_waste > 10 THEN 2 ELSE 0 END AS material_risk_score,
    RANK() OVER (
        ORDER BY failed_tests * 4
          + deviation_count * 3
          + CASE WHEN total_waste > 10 THEN 2 ELSE 0 END DESC
    ) AS risk_rank
FROM batch_risk;

-- 6. Pareto analysis of deviation categories
WITH category_counts AS (
    SELECT deviation_category, COUNT(*) AS deviation_count
    FROM deviations
    GROUP BY deviation_category
),
pareto AS (
    SELECT
        *,
        SUM(deviation_count) OVER (
            ORDER BY deviation_count DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_count,
        SUM(deviation_count) OVER () AS total_count
    FROM category_counts
)
SELECT
    deviation_category,
    deviation_count,
    ROUND(100.0 * cumulative_count / total_count, 2) AS cumulative_percent
FROM pareto
ORDER BY deviation_count DESC;

-- 7. Recursive material genealogy for a selected batch
WITH RECURSIVE batch_genealogy AS (
    SELECT
        b.batch_number,
        ml.supplier_lot_number,
        rm.material_name,
        s.supplier_name,
        1 AS genealogy_level,
        ARRAY[b.batch_number, ml.supplier_lot_number]::TEXT[] AS genealogy_path
    FROM manufacturing_batches b
    JOIN batch_material_usage u ON b.batch_id = u.batch_id
    JOIN material_lots ml ON u.material_lot_id = ml.material_lot_id
    JOIN raw_materials rm ON ml.material_id = rm.material_id
    JOIN suppliers s ON ml.supplier_id = s.supplier_id
    WHERE b.batch_number = 'BATCH-25003'
)
SELECT * FROM batch_genealogy;

-- 8. Quarantine aging
SELECT
    rm.material_name,
    ml.supplier_lot_number,
    s.supplier_name,
    CURRENT_DATE - ml.received_date AS days_in_inventory
FROM material_lots ml
JOIN raw_materials rm ON ml.material_id = rm.material_id
JOIN suppliers s ON ml.supplier_id = s.supplier_id
WHERE ml.disposition_status = 'Quarantined'
ORDER BY days_in_inventory DESC;

-- 9. Month-over-month quality trend
WITH monthly_quality AS (
    SELECT
        DATE_TRUNC('month', tested_date)::DATE AS month,
        COUNT(*) AS tests_completed,
        SUM(CASE WHEN test_status = 'Fail' THEN 1 ELSE 0 END) AS failed_tests
    FROM quality_tests
    GROUP BY DATE_TRUNC('month', tested_date)::DATE
),
rates AS (
    SELECT
        month,
        tests_completed,
        failed_tests,
        ROUND(100.0 * failed_tests / NULLIF(tests_completed, 0), 2) AS failure_rate
    FROM monthly_quality
)
SELECT
    *,
    LAG(failure_rate) OVER (ORDER BY month) AS prior_month_rate,
    failure_rate - LAG(failure_rate) OVER (ORDER BY month) AS monthly_change
FROM rates;

-- 10. Material-waste outlier analysis
WITH material_waste AS (
    SELECT
        rm.material_name,
        b.batch_number,
        SUM(u.quantity_wasted) AS total_waste
    FROM batch_material_usage u
    JOIN manufacturing_batches b ON u.batch_id = b.batch_id
    JOIN material_lots ml ON u.material_lot_id = ml.material_lot_id
    JOIN raw_materials rm ON ml.material_id = rm.material_id
    GROUP BY rm.material_name, b.batch_number
),
stats AS (
    SELECT
        *,
        AVG(total_waste) OVER (PARTITION BY material_name) AS avg_waste,
        STDDEV_POP(total_waste) OVER (PARTITION BY material_name) AS stddev_waste
    FROM material_waste
)
SELECT
    material_name,
    batch_number,
    total_waste,
    ROUND((total_waste - avg_waste) / NULLIF(stddev_waste, 0), 2) AS z_score
FROM stats
ORDER BY ABS((total_waste - avg_waste) / NULLIF(stddev_waste, 0)) DESC NULLS LAST;
