CREATE INDEX idx_material_lots_material_supplier
ON material_lots(material_id, supplier_id);

CREATE INDEX idx_quality_tests_lot_status_date
ON quality_tests(material_lot_id, test_status, tested_date);

CREATE INDEX idx_usage_batch_lot
ON batch_material_usage(batch_id, material_lot_id);

CREATE INDEX idx_deviations_category_severity
ON deviations(deviation_category, severity);

CREATE OR REPLACE VIEW vw_batch_material_traceability AS
SELECT
    b.batch_number,
    b.site_code,
    b.process_start_date,
    b.batch_status,
    rm.material_code,
    rm.material_name,
    ml.supplier_lot_number,
    s.supplier_name,
    ml.disposition_status,
    u.quantity_used,
    u.quantity_wasted,
    ROUND(100.0 * u.quantity_wasted /
          NULLIF(u.quantity_used + u.quantity_wasted, 0), 2) AS waste_percent
FROM manufacturing_batches b
JOIN batch_material_usage u ON b.batch_id = u.batch_id
JOIN material_lots ml ON u.material_lot_id = ml.material_lot_id
JOIN raw_materials rm ON ml.material_id = rm.material_id
JOIN suppliers s ON ml.supplier_id = s.supplier_id;

CREATE OR REPLACE VIEW vw_supplier_quality_scorecard AS
SELECT
    s.supplier_id,
    s.supplier_name,
    COUNT(DISTINCT ml.material_lot_id) AS total_lots,
    COUNT(DISTINCT CASE WHEN qt.test_status = 'Fail'
                   THEN ml.material_lot_id END) AS failed_lots,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN qt.test_status = 'Fail'
                               THEN ml.material_lot_id END)
        / NULLIF(COUNT(DISTINCT ml.material_lot_id), 0), 2
    ) AS lot_failure_rate_pct,
    COUNT(DISTINCT d.deviation_id) AS deviation_count
FROM suppliers s
LEFT JOIN material_lots ml ON s.supplier_id = ml.supplier_id
LEFT JOIN quality_tests qt ON ml.material_lot_id = qt.material_lot_id
LEFT JOIN deviations d ON ml.material_lot_id = d.material_lot_id
GROUP BY s.supplier_id, s.supplier_name;
