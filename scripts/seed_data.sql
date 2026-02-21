-- =============================================================================
-- SEED DATA - Datos ficticios para exploración (Onboarding)
-- =============================================================================
-- Ejecutar después de terraform apply. Reemplaza <AMBIENTE> por DEV, UAT o PROD.
-- Desde Snowsight: pegar y ejecutar por bloques, o usar: snowsql -f seed_data.sql
-- (ajustando los prefijos de base de datos según el ambiente).
-- =============================================================================

-- Uso: Sustituir ERP_<AMBIENTE>, CRM_<AMBIENTE>, SCM_<AMBIENTE> por tu ambiente (ej. ERP_DEV).

-- -----------------------------------------------------------------------------
-- ERP - FINANCE.INVOICES (mínimo 5 filas)
-- -----------------------------------------------------------------------------
INSERT INTO ERP_DEV.FINANCE.INVOICES (ID, INVOICE_NUMBER, AMOUNT, CURRENCY, STATUS, CREATED_AT) VALUES
(1, 'INV-2024-001', 1500.00, 'USD', 'PAID', '2024-01-15 10:00:00'),
(2, 'INV-2024-002', 2300.50, 'EUR', 'PENDING', '2024-01-16 11:30:00'),
(3, 'INV-2024-003', 890.25, 'USD', 'PAID', '2024-01-17 09:15:00'),
(4, 'INV-2024-004', 4500.00, 'GBP', 'CANCELLED', '2024-01-18 14:00:00'),
(5, 'INV-2024-005', 1200.00, 'USD', 'PAID', '2024-01-19 16:45:00');

-- -----------------------------------------------------------------------------
-- ERP - FINANCE.COST_CENTERS (mínimo 5 filas)
-- -----------------------------------------------------------------------------
INSERT INTO ERP_DEV.FINANCE.COST_CENTERS (ID, CODE, NAME, DEPARTMENT, BUDGET, ACTIVE) VALUES
(1, 'CC-IT', 'Tecnología', 'IT', 500000.00, TRUE),
(2, 'CC-HR', 'Recursos Humanos', 'HR', 200000.00, TRUE),
(3, 'CC-MKT', 'Marketing', 'Marketing', 350000.00, TRUE),
(4, 'CC-OPS', 'Operaciones', 'Operations', 800000.00, TRUE),
(5, 'CC-LEGACY', 'Legacy', 'Other', 50000.00, FALSE);

-- -----------------------------------------------------------------------------
-- CRM - CUSTOMERS.CONTACTS (mínimo 5 filas)
-- -----------------------------------------------------------------------------
INSERT INTO CRM_DEV.CUSTOMERS.CONTACTS (ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE, COUNTRY, CREATED_AT) VALUES
(1, 'Ana', 'García', 'ana.garcia@example.com', '+34 600 111 222', 'España', '2024-01-10 08:00:00'),
(2, 'Carlos', 'López', 'carlos.lopez@example.com', '+52 55 1234 5678', 'México', '2024-01-11 09:30:00'),
(3, 'María', 'Torres', 'maria.torres@example.com', '+57 1 234 5678', 'Colombia', '2024-01-12 10:15:00'),
(4, 'Pedro', 'Ramírez', 'pedro.ramirez@example.com', '+54 11 8765 4321', 'Argentina', '2024-01-13 11:00:00'),
(5, 'Laura', 'Martín', 'laura.martin@example.com', '+34 912 345 678', 'España', '2024-01-14 14:20:00');

-- -----------------------------------------------------------------------------
-- CRM - CUSTOMERS.OPPORTUNITIES (mínimo 5 filas)
-- -----------------------------------------------------------------------------
INSERT INTO CRM_DEV.CUSTOMERS.OPPORTUNITIES (ID, NAME, AMOUNT, STAGE, CLOSE_DATE, CONTACT_ID) VALUES
(1, 'Proyecto Alpha', 25000.00, 'Proposal', '2024-03-01', 1),
(2, 'Contrato Beta', 50000.00, 'Negotiation', '2024-03-15', 2),
(3, 'Renovación Gamma', 12000.00, 'Closed Won', '2024-02-01', 3),
(4, 'Nuevo servicio Delta', 8000.00, 'Qualification', '2024-04-01', 4),
(5, 'Soporte Epsilon', 15000.00, 'Closed Lost', '2024-01-20', 5);

-- -----------------------------------------------------------------------------
-- SCM - LOGISTICS.SHIPMENTS (mínimo 5 filas)
-- -----------------------------------------------------------------------------
INSERT INTO SCM_DEV.LOGISTICS.SHIPMENTS (ID, TRACKING_NUMBER, ORIGIN, DESTINATION, STATUS, SHIPPED_AT) VALUES
(1, 'TRK-001', 'Madrid', 'Barcelona', 'DELIVERED', '2024-01-05 08:00:00'),
(2, 'TRK-002', 'Ciudad de México', 'Guadalajara', 'IN_TRANSIT', '2024-01-08 10:00:00'),
(3, 'TRK-003', 'Bogotá', 'Medellín', 'PENDING', '2024-01-10 12:00:00'),
(4, 'TRK-004', 'Buenos Aires', 'Córdoba', 'DELIVERED', '2024-01-03 09:30:00'),
(5, 'TRK-005', 'Valencia', 'Sevilla', 'IN_TRANSIT', '2024-01-12 07:00:00');

-- -----------------------------------------------------------------------------
-- SCM - LOGISTICS.SUPPLIERS (mínimo 5 filas)
-- -----------------------------------------------------------------------------
INSERT INTO SCM_DEV.LOGISTICS.SUPPLIERS (ID, NAME, COUNTRY, CONTACT_EMAIL, RATING, ACTIVE) VALUES
(1, 'Suministros Globales SA', 'España', 'contacto@suministros-globales.com', 4.5, TRUE),
(2, 'TechParts MX', 'México', 'ventas@techparts.mx', 4.2, TRUE),
(3, 'Andean Logistics', 'Colombia', 'info@andeanlog.com', 4.8, TRUE),
(4, 'Sur Materials', 'Argentina', 'compras@surmaterials.com', 3.9, TRUE),
(5, 'Euro Supply Co', 'Alemania', 'hello@eurosupply.de', 4.0, FALSE);

-- Para UAT reemplaza _DEV por _UAT; para PROD por _PROD.
