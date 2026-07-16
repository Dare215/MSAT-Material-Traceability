INSERT INTO suppliers (supplier_name, country_code, approved_status, risk_tier) VALUES
('NovaChem Solutions','US','Approved','Low'),
('BioSource Materials','DE','Approved','Medium'),
('Precision Polymers','US','Conditional','High'),
('Apex Laboratory Supply','IE','Approved','Low');

INSERT INTO raw_materials
(material_code, material_name, material_category, storage_condition, critical_material) VALUES
('RM-001','Cell Culture Buffer A','Buffer','2-8C',TRUE),
('RM-002','Single-Use Polymer Film','Polymer','15-25C',TRUE),
('RM-003','Process Cleaning Agent','Cleaning','15-25C',FALSE),
('RM-004','Cryopreservation Medium','Media','-20C',TRUE);

INSERT INTO material_lots
(material_id, supplier_id, supplier_lot_number, received_date, expiration_date, quantity_received, uom, disposition_status) VALUES
(1,1,'NC-BA-1001','2025-01-05','2026-01-05',500,'L','Released'),
(1,1,'NC-BA-1002','2025-02-14','2026-02-14',450,'L','Released'),
(2,3,'PP-FILM-2201','2025-01-20','2027-01-20',1200,'EA','Released'),
(2,3,'PP-FILM-2202','2025-03-12','2027-03-12',1000,'EA','Quarantined'),
(3,4,'APX-CLN-551','2025-02-01','2026-08-01',300,'L','Released'),
(4,2,'BSM-CRYO-901','2025-01-27','2026-01-27',200,'L','Released'),
(4,2,'BSM-CRYO-902','2025-04-03','2026-04-03',220,'L','Rejected');

INSERT INTO manufacturing_batches
(batch_number, site_code, process_start_date, process_end_date, batch_status, final_yield, target_yield) VALUES
('BATCH-25001','PA-01','2025-02-01','2025-02-05','Released',93.5,95.0),
('BATCH-25002','PA-01','2025-02-18','2025-02-23','Released',96.2,95.0),
('BATCH-25003','NJ-02','2025-03-15','2025-03-20','Rejected',81.4,95.0),
('BATCH-25004','PA-01','2025-04-10','2025-04-15','Released',94.8,95.0),
('BATCH-25005','NJ-02','2025-05-03','2025-05-08','Completed',91.1,95.0);

INSERT INTO batch_material_usage
(batch_id, material_lot_id, quantity_used, quantity_wasted, usage_timestamp) VALUES
(1,1,40,2.0,'2025-02-01 09:00'),
(1,3,20,1.0,'2025-02-01 10:30'),
(1,5,5,0.5,'2025-02-02 08:15'),
(1,6,12,0.8,'2025-02-04 14:00'),
(2,2,42,1.5,'2025-02-18 09:10'),
(2,3,21,0.5,'2025-02-18 10:00'),
(3,2,39,5.5,'2025-03-15 09:00'),
(3,3,22,7.0,'2025-03-15 10:00'),
(3,6,13,2.1,'2025-03-19 12:00'),
(4,2,41,1.2,'2025-04-10 09:00'),
(5,2,40,3.2,'2025-05-03 09:00'),
(5,3,21,4.1,'2025-05-03 10:00');

INSERT INTO quality_tests
(material_lot_id, test_name, result_numeric, specification_low, specification_high, result_text, test_status, tested_date) VALUES
(1,'pH',7.20,7.00,7.40,NULL,'Pass','2025-01-07'),
(2,'pH',7.34,7.00,7.40,NULL,'Pass','2025-02-16'),
(3,'Film Integrity',NULL,NULL,NULL,'Acceptable','Pass','2025-01-23'),
(4,'Film Integrity',NULL,NULL,NULL,'Microleak Detected','Fail','2025-03-14'),
(6,'Sterility',NULL,NULL,NULL,'No Growth','Pass','2025-01-29'),
(7,'Sterility',NULL,NULL,NULL,'Growth Detected','Fail','2025-04-06');

INSERT INTO deviations
(batch_id, material_lot_id, deviation_number, opened_date, closed_date, severity, deviation_category, root_cause, status) VALUES
(3,3,'DEV-2025-001','2025-03-16','2025-04-04','Major','Material Integrity','Supplier variability','Closed'),
(3,2,'DEV-2025-002','2025-03-17','2025-04-08','Major','Excess Material Waste','Process setup error','Closed'),
(NULL,4,'DEV-2025-003','2025-03-15',NULL,'Critical','Incoming Quality Failure',NULL,'Investigation'),
(NULL,7,'DEV-2025-004','2025-04-06','2025-04-29','Critical','Sterility Failure','Supplier contamination event','Closed'),
(5,3,'DEV-2025-005','2025-05-04',NULL,'Major','Material Integrity',NULL,'Open');
