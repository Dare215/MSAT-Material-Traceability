DROP TABLE IF EXISTS deviations CASCADE;
DROP TABLE IF EXISTS quality_tests CASCADE;
DROP TABLE IF EXISTS batch_material_usage CASCADE;
DROP TABLE IF EXISTS manufacturing_batches CASCADE;
DROP TABLE IF EXISTS material_lots CASCADE;
DROP TABLE IF EXISTS raw_materials CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;

CREATE TABLE suppliers (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name VARCHAR(120) NOT NULL UNIQUE,
    country_code CHAR(2) NOT NULL,
    approved_status VARCHAR(20) NOT NULL
        CHECK (approved_status IN ('Approved','Conditional','Disqualified')),
    risk_tier VARCHAR(10) NOT NULL
        CHECK (risk_tier IN ('Low','Medium','High'))
);

CREATE TABLE raw_materials (
    material_id SERIAL PRIMARY KEY,
    material_code VARCHAR(30) NOT NULL UNIQUE,
    material_name VARCHAR(150) NOT NULL,
    material_category VARCHAR(50) NOT NULL,
    storage_condition VARCHAR(50) NOT NULL,
    critical_material BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE material_lots (
    material_lot_id SERIAL PRIMARY KEY,
    material_id INT NOT NULL REFERENCES raw_materials(material_id),
    supplier_id INT NOT NULL REFERENCES suppliers(supplier_id),
    supplier_lot_number VARCHAR(60) NOT NULL,
    received_date DATE NOT NULL,
    expiration_date DATE NOT NULL,
    quantity_received NUMERIC(12,2) NOT NULL CHECK (quantity_received > 0),
    uom VARCHAR(20) NOT NULL,
    disposition_status VARCHAR(20) NOT NULL
        CHECK (disposition_status IN ('Released','Quarantined','Rejected','Expired')),
    UNIQUE (supplier_id, supplier_lot_number)
);

CREATE TABLE manufacturing_batches (
    batch_id SERIAL PRIMARY KEY,
    batch_number VARCHAR(40) NOT NULL UNIQUE,
    site_code VARCHAR(20) NOT NULL,
    process_start_date DATE NOT NULL,
    process_end_date DATE,
    batch_status VARCHAR(20) NOT NULL
        CHECK (batch_status IN ('In Process','Completed','Rejected','Released')),
    final_yield NUMERIC(8,2),
    target_yield NUMERIC(8,2)
);

CREATE TABLE batch_material_usage (
    usage_id SERIAL PRIMARY KEY,
    batch_id INT NOT NULL REFERENCES manufacturing_batches(batch_id),
    material_lot_id INT NOT NULL REFERENCES material_lots(material_lot_id),
    quantity_used NUMERIC(12,3) NOT NULL CHECK (quantity_used > 0),
    quantity_wasted NUMERIC(12,3) NOT NULL DEFAULT 0 CHECK (quantity_wasted >= 0),
    usage_timestamp TIMESTAMP NOT NULL
);

CREATE TABLE quality_tests (
    quality_test_id SERIAL PRIMARY KEY,
    material_lot_id INT NOT NULL REFERENCES material_lots(material_lot_id),
    test_name VARCHAR(100) NOT NULL,
    result_numeric NUMERIC(14,4),
    specification_low NUMERIC(14,4),
    specification_high NUMERIC(14,4),
    result_text VARCHAR(60),
    test_status VARCHAR(20) NOT NULL CHECK (test_status IN ('Pass','Fail','Pending')),
    tested_date DATE NOT NULL
);

CREATE TABLE deviations (
    deviation_id SERIAL PRIMARY KEY,
    batch_id INT REFERENCES manufacturing_batches(batch_id),
    material_lot_id INT REFERENCES material_lots(material_lot_id),
    deviation_number VARCHAR(40) NOT NULL UNIQUE,
    opened_date DATE NOT NULL,
    closed_date DATE,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('Minor','Major','Critical')),
    deviation_category VARCHAR(80) NOT NULL,
    root_cause VARCHAR(120),
    status VARCHAR(20) NOT NULL CHECK (status IN ('Open','Investigation','Closed')),
    CHECK (batch_id IS NOT NULL OR material_lot_id IS NOT NULL)
);
