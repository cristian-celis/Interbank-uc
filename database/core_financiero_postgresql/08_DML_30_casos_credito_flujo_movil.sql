-- ============================================================================
-- bd_core_mobile - 08) 30 CASOS CREDITO EMPRESARIAL FLUJO MOVIL
-- ----------------------------------------------------------------------------
-- Carga idempotente de los 30 casos abstraidos desde:
-- docs/casos_credito_flujo_movil_abstraccion.md
--
-- Inserta/actualiza: clientes, accesos app, cartera diaria, solicitudes,
-- consultas de buro, decisiones, creditos desembolsados, cronogramas completos,
-- documentos placeholder y notificaciones.
-- ============================================================================

BEGIN;

CREATE TEMP TABLE tmp_casos_credito_fm (
    caso INTEGER PRIMARY KEY,
    dni TEXT NOT NULL,
    nombres TEXT NOT NULL,
    apellidos TEXT NOT NULL,
    telefono TEXT NOT NULL,
    tipo_negocio TEXT NOT NULL,
    nombre_negocio TEXT NOT NULL,
    distrito TEXT NOT NULL,
    antiguedad_meses INTEGER NOT NULL,
    ingresos NUMERIC(12,2) NOT NULL,
    gastos NUMERIC(12,2) NOT NULL,
    monto_solicitado NUMERIC(12,2) NOT NULL,
    plazo_meses INTEGER NOT NULL,
    tea NUMERIC(5,2) NOT NULL,
    seguro TEXT NOT NULL,
    garantia TEXT NOT NULL,
    destino TEXT NOT NULL,
    cuota_referencia NUMERIC(10,2) NOT NULL,
    prioridad TEXT NOT NULL,
    lat NUMERIC(10,7) NOT NULL,
    lng NUMERIC(10,7) NOT NULL,
    pre_evaluacion TEXT NOT NULL,
    puntaje INTEGER NOT NULL,
    buro TEXT NOT NULL,
    entidades_deuda INTEGER NOT NULL,
    deuda_total NUMERIC(12,2) NOT NULL,
    dias_mora INTEGER NOT NULL,
    lista_inhabilitados BOOLEAN NOT NULL,
    decision TEXT NOT NULL,
    monto_aprobado NUMERIC(12,2),
    condicion_adicional TEXT,
    motivo_rechazo TEXT,
    fecha_desembolso DATE,
    dia_pago INTEGER,
    cuota_mensual NUMERIC(10,2)
) ON COMMIT DROP;

INSERT INTO tmp_casos_credito_fm (
    caso, dni, nombres, apellidos, telefono, tipo_negocio, nombre_negocio,
    distrito, antiguedad_meses, ingresos, gastos, monto_solicitado,
    plazo_meses, tea, seguro, garantia, destino, cuota_referencia, prioridad,
    lat, lng, pre_evaluacion, puntaje, buro, entidades_deuda, deuda_total,
    dias_mora, lista_inhabilitados, decision, monto_aprobado,
    condicion_adicional, motivo_rechazo, fecha_desembolso, dia_pago,
    cuota_mensual
) VALUES
    (1, '40118120', 'Anaximandro', 'Quispe', '964110201', 'Bodega', 'Bodega Don Anaxi', 'El Tambo', 48, 2200.00, 900.00, 1000.00, 12, 43.92, 'sin seguro de desgravamen', 'sin garantia', 'Capital de trabajo: compra de mercaderia', 100.95, 'normal', -12.0581, -75.2027, 'APTO', 85, 'NORMAL', 1, 4500.00, 0, FALSE, 'aprobado', 1000.00, NULL, NULL, DATE '2026-02-02', 3, 100.95),
    (2, '41223341', 'Eulalia', 'Mamani', '964110202', 'Restaurante', 'Picanteria La Eulalia', 'Chilca', 36, 3000.00, 1400.00, 3000.00, 12, 40.92, 'con seguro de desgravamen', 'sin garantia', 'Compra de cocina industrial', 299.59, 'media', -12.0921, -75.2105, 'APTO', 85, 'NORMAL', 2, 12000.00, 0, FALSE, 'aprobado', 3000.00, NULL, NULL, DATE '2026-02-05', 5, 299.59),
    (3, '42330336', 'Teofilo', 'Huaman', '964110203', 'Carpinteria', 'Maderas Huaman', 'Pilcomayo', 60, 4200.00, 1800.00, 5000.00, 18, 43.92, 'sin seguro de desgravamen', 'sin garantia', 'Maquinaria: sierra y cepillo', 366.02, 'media', -12.0496, -75.2486, 'APTO', 85, 'NORMAL', 1, 6000.00, 0, FALSE, 'aprobado', 5000.00, NULL, NULL, DATE '2026-02-10', 10, 366.02),
    (4, '43440349', 'Casandra', 'Flores', '964110204', 'Abarrotes', 'Distribuidora Casandra', 'Huancayo', 84, 7000.00, 2600.00, 8000.00, 6, 43.92, 'sin seguro de desgravamen', 'sin garantia', 'Reposicion de stock por campana', 1480.73, 'alta', -12.0651, -75.2049, 'APTO', 85, 'NORMAL', 2, 14000.00, 0, FALSE, 'aprobado', 8000.00, NULL, NULL, DATE '2026-02-15', 15, 1480.73),
    (5, '40556071', 'Demostenes', 'Rojas', '964110205', 'Ferreteria', 'Ferreteria El Constructor', 'San Agustin de Cajas', 30, 5200.00, 2100.00, 10000.00, 12, 43.92, 'sin seguro de desgravamen', 'hipotecaria', 'Ampliacion de local', 1009.46, 'alta', -12.0188, -75.2271, 'APTO', 85, 'NORMAL', 2, 12000.00, 0, FALSE, 'aprobado', 10000.00, NULL, NULL, DATE '2026-03-01', 3, 1009.46),
    (6, '41669066', 'Hipatia', 'Condori', '964110206', 'Textil', 'Confecciones Hipatia', 'El Tambo', 54, 6800.00, 2900.00, 12000.00, 24, 40.92, 'con seguro de desgravamen', 'hipotecaria', 'Compra de maquinas remalladoras', 700.94, 'media', -12.0612, -75.2118, 'APTO', 85, 'NORMAL', 1, 6000.00, 0, FALSE, 'aprobado', 12000.00, NULL, NULL, DATE '2026-03-05', 5, 700.94),
    (7, '43773379', 'Anibal', 'Vargas', '964110207', 'Transporte', 'Transportes Anibal', 'Concepcion', 42, 9500.00, 4200.00, 15000.00, 18, 43.92, 'sin seguro de desgravamen', 'vehicular', 'Cuota inicial de vehiculo de carga', 1098.07, 'alta', -11.9182, -75.3142, 'APTO', 85, 'NORMAL', 2, 14000.00, 0, FALSE, 'aprobado', 15000.00, NULL, NULL, DATE '2026-03-10', 10, 1098.07),
    (8, '40886086', 'Penelope', 'Apaza', '964110208', 'Avicola', 'Granja Penelope', 'Sapallanga', 72, 8800.00, 3600.00, 18000.00, 24, 43.92, 'sin seguro de desgravamen', 'hipotecaria', 'Ampliacion de galpon', 1072.10, 'alta', -12.1581, -75.1762, 'APTO', 85, 'NORMAL', 1, 6000.00, 0, FALSE, 'aprobado', 18000.00, NULL, NULL, DATE '2026-03-15', 15, 1072.10),
    (9, '41990091', 'Heraclito', 'Ccahua', '964110209', 'Comercio', 'Importaciones Heraclito', 'Huancayo', 96, 12000.00, 5000.00, 20000.00, 36, 43.92, 'sin seguro de desgravamen', 'hipotecaria', 'Capital para nueva sucursal', 927.12, 'alta', -12.0668, -75.2103, 'APTO', 85, 'NORMAL', 2, 12000.00, 0, FALSE, 'aprobado', 20000.00, NULL, NULL, DATE '2026-04-02', 3, 927.12),
    (10, '43003039', 'Cleopatra', 'Soto', '964110210', 'Farmacia', 'Botica Cleopatra', 'Chupaca', 66, 11000.00, 4400.00, 25000.00, 24, 40.92, 'con seguro de desgravamen', 'hipotecaria', 'Equipamiento y stock farmaceutico', 1460.29, 'alta', -12.056, -75.287, 'APTO', 85, 'NORMAL', 2, 14000.00, 0, FALSE, 'aprobado', 25000.00, NULL, NULL, DATE '2026-04-05', 5, 1460.29),
    (11, '40110010', 'Esquilo', 'Ramos', '964110211', 'Bodega', 'Minimarket Esquilo', 'Huayucachi', 24, 1900.00, 800.00, 2000.00, 12, 43.92, 'sin seguro de desgravamen', 'sin garantia', 'Compra de congeladora', 201.89, 'normal', -12.1339, -75.209, 'APTO', 85, 'NORMAL', 1, 4500.00, 0, FALSE, 'aprobado', 2000.00, NULL, NULL, DATE '2026-04-10', 10, 201.89),
    (12, '41226021', 'Ariadna', 'Quispe', '964110212', 'Peluqueria', 'Estilos Ariadna', 'El Tambo', 40, 3300.00, 1300.00, 4000.00, 18, 43.92, 'sin seguro de desgravamen', 'sin garantia', 'Mobiliario y equipos de salon', 292.82, 'media', -12.0573, -75.2161, 'APTO', 85, 'NORMAL', 2, 12000.00, 0, FALSE, 'aprobado', 4000.00, NULL, NULL, DATE '2026-04-15', 15, 292.82),
    (13, '43336033', 'Sofocles', 'Huanca', '964110213', 'Panaderia', 'Panaderia Sofocles', 'Sicaya', 58, 5600.00, 2300.00, 6000.00, 12, 40.92, 'con seguro de desgravamen', 'sin garantia', 'Horno rotativo', 599.17, 'media', -12.0228, -75.3134, 'APTO', 85, 'NORMAL', 0, 0.00, 0, FALSE, 'aprobado', 6000.00, NULL, NULL, DATE '2026-05-02', 3, 599.17),
    (14, '40550055', 'Casiopea', 'Torres', '964110214', 'Mecanica', 'Taller Casiopea', 'Pilcomayo', 50, 7400.00, 3000.00, 7500.00, 6, 43.92, 'sin seguro de desgravamen', 'sin garantia', 'Herramienta neumatica', 1388.18, 'media', -12.0512, -75.2451, 'APTO', 85, 'DEFICIENTE', 2, 16000.00, 45, FALSE, 'aprobado', 7500.00, NULL, NULL, DATE '2026-05-05', 5, 1388.18),
    (15, '41669166', 'Aristofanes', 'Cruz', '964110215', 'Agropecuario', 'Insumos Aristofanes', 'Orcotuna', 78, 8200.00, 3300.00, 9000.00, 24, 43.92, 'sin seguro de desgravamen', 'hipotecaria', 'Capital para campana agricola', 536.05, 'alta', -11.976, -75.3361, 'APTO', 85, 'NORMAL', 1, 6000.00, 0, FALSE, 'aprobado', 9000.00, NULL, NULL, DATE '2026-05-10', 10, 536.05),
    (16, '43880088', 'Calipso', 'Mendoza', '964110216', 'Calzado', 'Calzados Calipso', 'Huancayo', 62, 7900.00, 3100.00, 11000.00, 18, 40.92, 'con seguro de desgravamen', 'hipotecaria', 'Compra de cuero y maquinaria', 793.03, 'media', -12.0689, -75.2055, 'APTO', 85, 'CPP', 1, 9000.00, 20, FALSE, 'aprobado', 11000.00, NULL, NULL, DATE '2026-05-15', 15, 793.03),
    (17, '40119019', 'Demetrio', 'Quispe', '964110217', 'Comercio', 'Mayorista Demetrio', 'Jauja', 90, 11500.00, 4700.00, 13500.00, 12, 43.92, 'sin seguro de desgravamen', 'hipotecaria', 'Reposicion de inventario mayorista', 1362.77, 'alta', -11.7752, -75.4995, 'APTO', 85, 'NORMAL', 2, 14000.00, 0, FALSE, 'aprobado', 13500.00, NULL, NULL, DATE '2026-06-02', 3, 1362.77),
    (18, '41226126', 'Antigona', 'Flores', '964110218', 'Restaurante', 'Recreo Antigona', 'Concepcion', 70, 9200.00, 3900.00, 16000.00, 36, 43.92, 'sin seguro de desgravamen', 'hipotecaria', 'Ampliacion y remodelacion', 741.70, 'alta', -11.9201, -75.311, 'APTO', 85, 'NORMAL', 1, 6000.00, 0, FALSE, 'aprobado', 16000.00, NULL, NULL, DATE '2026-06-05', 5, 741.70),
    (19, '43339033', 'Pitagoras', 'Rojas', '964110219', 'Ferreteria', 'Ferreteria Pitagoras', 'El Tambo', 100, 13000.00, 5200.00, 17000.00, 24, 40.92, 'con seguro de desgravamen', 'hipotecaria', 'Compra de stock estructural', 993.00, 'alta', -12.0599, -75.2143, 'APTO', 85, 'NORMAL', 0, 0.00, 0, FALSE, 'aprobado', 17000.00, NULL, NULL, DATE '2026-06-10', 10, 993.00),
    (20, '40556056', 'Berenice', 'Apaza', '964110220', 'Textil', 'Tejidos Berenice', 'San Jeronimo de Tunan', 46, 8600.00, 3500.00, 19000.00, 18, 43.92, 'sin seguro de desgravamen', 'hipotecaria', 'Maquinaria de tejido plano', 1390.89, 'alta', -11.9871, -75.2899, 'APTO', 85, 'NORMAL', 1, 6000.00, 0, FALSE, 'aprobado', 19000.00, NULL, NULL, DATE '2026-06-15', 15, 1390.89),
    (21, '43889089', 'Anaxagoras', 'Huaman', '964110221', 'Transporte', 'Carga Anaxagoras', 'Huancayo', 84, 14000.00, 5800.00, 22000.00, 36, 43.92, 'sin seguro de desgravamen', 'vehicular', 'Cuota inicial de camion', 1019.83, 'alta', -12.0644, -75.2088, 'APTO', 85, 'NORMAL', 2, 14000.00, 0, FALSE, 'aprobado', 22000.00, NULL, NULL, DATE '2026-07-02', 3, 1019.83),
    (22, '41003001', 'Climene', 'Vargas', '964110222', 'Avicola', 'Avicola Climene', 'Sapallanga', 76, 13500.00, 5500.00, 24000.00, 24, 40.92, 'con seguro de desgravamen', 'hipotecaria', 'Equipamiento de planta', 1401.88, 'alta', -12.156, -75.179, 'APTO', 85, 'NORMAL', 2, 12000.00, 0, FALSE, 'aprobado', 24000.00, NULL, NULL, DATE '2026-07-05', 5, 1401.88),
    (23, '40115011', 'Epaminondas', 'Soto', '964110223', 'Bodega', 'Bodega Epaminondas', 'Pucara', 28, 2600.00, 1000.00, 1500.00, 6, 43.92, 'sin seguro de desgravamen', 'sin garantia', 'Compra de vitrinas', 277.64, 'normal', -12.1701, -75.1611, 'APTO', 85, 'NORMAL', 2, 12000.00, 0, FALSE, 'aprobado', 1500.00, NULL, NULL, DATE '2026-07-10', 10, 277.64),
    (24, '41336036', 'Lisistrata', 'Ramos', '964110224', 'Comercio', 'Variedades Lisistrata', 'Huancayo', 52, 4100.00, 1700.00, 3500.00, 12, 43.92, 'sin seguro de desgravamen', 'sin garantia', 'Capital de trabajo', 353.31, 'media', -12.0633, -75.2071, 'APTO', 85, 'NORMAL', 1, 6000.00, 0, FALSE, 'aprobado', 3500.00, NULL, NULL, DATE '2026-07-15', 15, 353.31),
    (25, '41552052', 'Filoctetes', 'Cruz', '964110225', 'Restaurante', 'Cevicheria Filoctetes', 'Chilca', 18, 3800.00, 2200.00, 11000.00, 18, 40.92, 'con seguro de desgravamen', 'sin garantia', 'Ampliacion de local nuevo', 793.03, 'media', -12.093, -75.209, 'APTO', 85, 'CPP', 2, 18000.00, 15, FALSE, 'condicionado', 7000.00, 'Antiguedad del negocio menor a 24 meses y carga de gastos alta: el comite aprueba un monto menor.', NULL, DATE '2026-08-02', 3, 504.66),
    (26, '41888088', 'Calirroe', 'Mendoza', '964110226', 'Calzado', 'Calzados Calirroe', 'El Tambo', 34, 5000.00, 2600.00, 16000.00, 24, 43.92, 'sin seguro de desgravamen', 'hipotecaria', 'Maquinaria de mayor capacidad', 952.98, 'media', -12.0588, -75.2129, 'APTO', 85, 'CPP', 1, 9000.00, 20, FALSE, 'condicionado', 10000.00, 'Calificacion CPP con 20 dias de mora reciente: se aprueba monto reducido con seguimiento.', NULL, DATE '2026-08-05', 5, 595.61),
    (27, '42220022', 'Tucidides', 'Quispe', '964110227', 'Ferreteria', 'Ferreteria Tucidides', 'Concepcion', 40, 6200.00, 2900.00, 20000.00, 24, 40.92, 'con seguro de desgravamen', 'hipotecaria', 'Compra de stock y montacarga', 1168.23, 'alta', -11.9176, -75.3155, 'APTO', 85, 'CPP', 2, 18000.00, 15, FALSE, 'condicionado', 14000.00, 'Endeudamiento externo en 2 entidades y relacion monto/ingreso ajustada: el comite condiciona el monto.', NULL, DATE '2026-08-10', 10, 817.76),
    (28, '43337037', 'Aquiles', 'Mamani', '964110228', 'Comercio', 'Comercial Aquiles', 'Huancayo', 60, 9000.00, 3600.00, 15000.00, 24, 43.92, 'sin seguro de desgravamen', 'hipotecaria', 'Capital de trabajo', 893.42, 'alta', -12.0657, -75.2099, 'APTO', 85, 'PERDIDA', 4, 40000.00, 210, TRUE, 'rechazado', NULL, NULL, 'Registrado en lista de inhabilitados del sistema financiero; la solicitud se bloquea en la consulta de buro. No se genera cronograma. Registrar el motivo de rechazo y cerrar el expediente en estado rechazado.', NULL, NULL, NULL),
    (29, '41884084', 'Medea', 'Apaza', '964110229', 'Bodega', 'Bodega Medea', 'Pilcomayo', 22, 1800.00, 1100.00, 14000.00, 18, 43.92, 'sin seguro de desgravamen', 'sin garantia', 'Compra de camioneta para reparto', 1024.87, 'media', -12.0489, -75.247, 'REVISAR', 60, 'DUDOSO', 3, 25000.00, 95, FALSE, 'rechazado', NULL, NULL, 'El monto solicitado supera ampliamente la capacidad de pago estimada (pre-evaluacion NO_PROCEDE). No se genera cronograma. Registrar el motivo de rechazo y cerrar el expediente en estado rechazado.', NULL, NULL, NULL),
    (30, '43334034', 'Esquines', 'Rojas', '964110230', 'Transporte', 'Fletes Esquines', 'Jauja', 30, 7000.00, 3200.00, 30000.00, 24, 43.92, 'sin seguro de desgravamen', 'vehicular', 'Compra de unidad de transporte', 1786.83, 'alta', -11.774, -75.501, 'APTO', 85, 'DUDOSO', 3, 25000.00, 95, FALSE, 'rechazado', NULL, NULL, 'Calificacion SBS DUDOSO con 95 dias de mora vigente en 3 entidades: no procede el otorgamiento. No se genera cronograma. Registrar el motivo de rechazo y cerrar el expediente en estado rechazado.', NULL, NULL, NULL);

-- Limpiar la carga anterior de estos casos sin tocar la data demo base.
DELETE FROM notificaciones
WHERE data_json ->> 'origen' = '30_casos_credito_flujo_movil';

DELETE FROM cr_creditos
WHERE cod_cuenta_credito LIKE 'CRED-FM-%';

DELETE FROM consultas_buro
WHERE solicitud_id IN (
    SELECT id FROM solicitudes_credito WHERE numero_expediente LIKE 'FM-%'
);

DELETE FROM solicitudes_credito
WHERE numero_expediente LIKE 'FM-%';

DELETE FROM cartera_diaria cd
USING clientes c, tmp_casos_credito_fm t
WHERE cd.cliente_id = c.id
  AND c.numero_documento = t.dni
  AND cd.tipo_gestion = 'NUEVA_SOLICITUD'
  AND cd.fecha_asignacion BETWEEN DATE '2026-01-01' AND DATE '2026-12-31';

-- Clientes y acceso a App Clientes.
INSERT INTO clientes (
    cod_cliente, numero_documento, tipo_documento, nombres, apellidos,
    telefono, email, direccion, tipo_negocio, nombre_negocio,
    antiguedad_negocio_meses, ingresos_estimados, lat, lng,
    calificacion_sbs, es_prospecto, updated_at
)
SELECT
    'FM-C' || lpad(caso::TEXT, 3, '0'),
    dni,
    'DNI',
    nombres,
    apellidos,
    telefono,
    lower(replace(nombres || '.' || apellidos || '@demo.local', ' ', '.')),
    distrito,
    tipo_negocio,
    nombre_negocio,
    antiguedad_meses,
    ingresos,
    lat,
    lng,
    CASE buro
        WHEN 'NORMAL' THEN 'Normal'
        WHEN 'CPP' THEN 'CPP'
        WHEN 'DEFICIENTE' THEN 'Deficiente'
        WHEN 'DUDOSO' THEN 'Dudoso'
        WHEN 'PERDIDA' THEN 'Perdida'
        ELSE buro
    END,
    TRUE,
    now()
FROM tmp_casos_credito_fm
ON CONFLICT (numero_documento) DO UPDATE SET
    cod_cliente = COALESCE(clientes.cod_cliente, EXCLUDED.cod_cliente),
    nombres = EXCLUDED.nombres,
    apellidos = EXCLUDED.apellidos,
    telefono = EXCLUDED.telefono,
    email = EXCLUDED.email,
    direccion = EXCLUDED.direccion,
    tipo_negocio = EXCLUDED.tipo_negocio,
    nombre_negocio = EXCLUDED.nombre_negocio,
    antiguedad_negocio_meses = EXCLUDED.antiguedad_negocio_meses,
    ingresos_estimados = EXCLUDED.ingresos_estimados,
    lat = EXCLUDED.lat,
    lng = EXCLUDED.lng,
    calificacion_sbs = EXCLUDED.calificacion_sbs,
    es_prospecto = TRUE,
    updated_at = now();

INSERT INTO usuarios_cliente (cliente_id, username, password_hash, activo, bloqueado, intentos_fallidos)
SELECT c.id, t.dni,
       '$2b$12$D.eZtoXYYW79A0.tN9XwgOz4.t2fIqnGbiNoEY.n4Bvq6u/prRrTe',
       TRUE, FALSE, 0
FROM tmp_casos_credito_fm t
JOIN clientes c ON c.numero_documento = t.dni
ON CONFLICT (username) DO UPDATE SET
    cliente_id = EXCLUDED.cliente_id,
    password_hash = EXCLUDED.password_hash,
    activo = TRUE,
    bloqueado = FALSE,
    intentos_fallidos = 0;

DO $$
DECLARE
    r tmp_casos_credito_fm%ROWTYPE;
    v_cliente_id UUID;
    v_asesor_id UUID;
    v_agencia_id UUID;
    v_decisor_id UUID;
    v_solicitud_id UUID;
    v_fecha_asignacion DATE;
    v_cod_credito TEXT;
    v_tem NUMERIC;
    v_saldo NUMERIC(12,2);
    v_interes NUMERIC(10,2);
    v_capital NUMERIC(10,2);
    v_fecha_cuota DATE;
    v_doc TEXT;
    i INTEGER;
BEGIN
    SELECT id, agencia_id INTO v_asesor_id, v_agencia_id
    FROM asesores
    WHERE cod_asesor = 'A002'
    LIMIT 1;

    IF v_asesor_id IS NULL THEN
        SELECT id, agencia_id INTO v_asesor_id, v_agencia_id
        FROM asesores
        ORDER BY codigo_empleado
        LIMIT 1;
    END IF;

    SELECT id INTO v_decisor_id
    FROM asesores
    WHERE cod_asesor = 'A001'
    LIMIT 1;

    IF v_decisor_id IS NULL THEN
        v_decisor_id := v_asesor_id;
    END IF;

    IF v_asesor_id IS NULL THEN
        RAISE EXCEPTION 'No existen asesores. Ejecute 02_DML_catalogos_core_mobile.sql antes del script 08.';
    END IF;

    FOR r IN SELECT * FROM tmp_casos_credito_fm ORDER BY caso LOOP
        SELECT id INTO v_cliente_id
        FROM clientes
        WHERE numero_documento = r.dni;

        v_fecha_asignacion := COALESCE(
            r.fecha_desembolso - INTERVAL '3 days',
            DATE '2026-08-01' + (r.caso - 28)
        )::DATE;

        INSERT INTO cartera_diaria (
            asesor_id, cliente_id, agencia_id, fecha_asignacion, tipo_gestion,
            prioridad, score_prioridad, monto_credito, estado_visita,
            resultado_visita, observacion_visita, timestamp_visita,
            lat_visita, lng_visita, orden_manual
        ) VALUES (
            v_asesor_id, v_cliente_id, v_agencia_id, v_fecha_asignacion,
            'NUEVA_SOLICITUD', r.prioridad, r.puntaje, r.monto_solicitado,
            'visitado', 'visitado',
            'Visita registrada para caso FM-' || lpad(r.caso::TEXT, 3, '0') ||
            '. Resultado esperado: ' || r.pre_evaluacion || '. Buro: ' || r.buro || '.',
            v_fecha_asignacion + TIME '10:00', r.lat, r.lng, r.caso
        )
        ON CONFLICT (asesor_id, cliente_id, fecha_asignacion) DO UPDATE SET
            agencia_id = EXCLUDED.agencia_id,
            tipo_gestion = EXCLUDED.tipo_gestion,
            prioridad = EXCLUDED.prioridad,
            score_prioridad = EXCLUDED.score_prioridad,
            monto_credito = EXCLUDED.monto_credito,
            estado_visita = EXCLUDED.estado_visita,
            resultado_visita = EXCLUDED.resultado_visita,
            observacion_visita = EXCLUDED.observacion_visita,
            timestamp_visita = EXCLUDED.timestamp_visita,
            lat_visita = EXCLUDED.lat_visita,
            lng_visita = EXCLUDED.lng_visita,
            orden_manual = EXCLUDED.orden_manual;

        INSERT INTO solicitudes_credito (
            numero_expediente, cod_solicitud_core, asesor_id, cliente_id,
            agencia_id, canal, tipo_negocio, nombre_negocio,
            antiguedad_negocio_meses, ingresos_estimados, gastos_mensuales,
            monto_solicitado, plazo_meses, moneda, tipo_cuota, garantia,
            destino_credito, cuota_estimada, tea_referencial, estado,
            monto_aprobado, motivo_rechazo, condicion_adicional,
            analista_asignado, firma_cliente_base64, lat_captura, lng_captura,
            pendiente_sync, created_at, updated_at
        ) VALUES (
            'FM-' || lpad(r.caso::TEXT, 3, '0'),
            'SOL-FM-' || lpad(r.caso::TEXT, 3, '0'),
            v_asesor_id, v_cliente_id, v_agencia_id, 'cliente',
            r.tipo_negocio, r.nombre_negocio, r.antiguedad_meses,
            r.ingresos, r.gastos, r.monto_solicitado, r.plazo_meses,
            'PEN', 'mensual', r.garantia, r.destino,
            COALESCE(r.cuota_mensual, r.cuota_referencia), r.tea,
            CASE WHEN r.decision = 'rechazado' THEN 'rechazado' ELSE 'desembolsado' END,
            r.monto_aprobado, r.motivo_rechazo, r.condicion_adicional,
            'Comite demo FM',
            'firma-demo-fm-' || lpad(r.caso::TEXT, 3, '0'),
            r.lat, r.lng, FALSE,
            v_fecha_asignacion + TIME '09:00',
            COALESCE(r.fecha_desembolso, v_fecha_asignacion) + TIME '12:00'
        )
        RETURNING id INTO v_solicitud_id;

        INSERT INTO consultas_buro (
            asesor_id, cliente_id, solicitud_id, dni_consultado,
            calificacion_sbs, entidades_con_deuda, deuda_total_pen,
            mayor_deuda, dias_mayor_mora, en_lista_negra, motivo_bloqueo,
            resultado_json, firma_consentimiento_base64, created_at
        ) VALUES (
            v_asesor_id, v_cliente_id, v_solicitud_id, r.dni,
            r.buro, r.entidades_deuda, r.deuda_total,
            CASE WHEN r.entidades_deuda = 0 THEN 0 ELSE round(r.deuda_total / r.entidades_deuda, 2) END,
            r.dias_mora, r.lista_inhabilitados,
            CASE WHEN r.lista_inhabilitados THEN 'Cliente en lista de inhabilitados' ELSE NULL END,
            jsonb_build_object(
                'origen', '30_casos_credito_flujo_movil',
                'caso', r.caso,
                'pre_evaluacion', r.pre_evaluacion,
                'puntaje', r.puntaje,
                'seguro', r.seguro
            ),
            'consentimiento-demo-fm-' || lpad(r.caso::TEXT, 3, '0'),
            v_fecha_asignacion + TIME '10:30'
        );

        INSERT INTO solicitudes_decisiones (
            solicitud_id, asesor_decisor_id, decision, monto_aprobado,
            motivo, created_at
        ) VALUES (
            v_solicitud_id, v_decisor_id, r.decision, r.monto_aprobado,
            COALESCE(r.motivo_rechazo, r.condicion_adicional, 'Aprobado segun comite.'),
            COALESCE(r.fecha_desembolso, v_fecha_asignacion) + TIME '11:00'
        );

        FOREACH v_doc IN ARRAY ARRAY[
            'dni_anverso', 'dni_reverso', 'sustento_negocio',
            'foto_negocio', 'foto_visita'
        ] LOOP
            INSERT INTO solicitudes_documentos (
                solicitud_id, tipo_documento, storage_url, tamanio_kb,
                nitidez_score, created_at
            ) VALUES (
                v_solicitud_id, v_doc,
                '/demo/fm_' || lpad(r.caso::TEXT, 3, '0') || '/' || v_doc || '.jpg',
                512 + r.caso,
                92.50,
                v_fecha_asignacion + TIME '10:45'
            );
        END LOOP;

        IF r.decision <> 'rechazado' THEN
            v_cod_credito := 'CRED-FM-' || lpad(r.caso::TEXT, 3, '0');

            INSERT INTO cr_creditos (
                cod_cuenta_credito, cliente_id, producto, monto_desembolsado,
                saldo_capital, saldo_total, dias_mora, calificacion_interna,
                estado, fecha_desembolso, tea, cuotas_total, cuotas_pagadas
            ) VALUES (
                v_cod_credito, v_cliente_id, 'Credito Empresarial - Microempresa',
                r.monto_aprobado, r.monto_aprobado, r.monto_aprobado,
                0, lower(r.buro), 'vigente', r.fecha_desembolso,
                r.tea, r.plazo_meses, 0
            );

            v_tem := power(1 + (r.tea / 100.0), 1.0 / 12.0) - 1;
            v_saldo := r.monto_aprobado;

            FOR i IN 1..r.plazo_meses LOOP
                v_fecha_cuota := (
                    make_date(
                        EXTRACT(YEAR FROM r.fecha_desembolso + INTERVAL '1 month')::INT,
                        EXTRACT(MONTH FROM r.fecha_desembolso + INTERVAL '1 month')::INT,
                        r.dia_pago
                    ) + ((i - 1) || ' months')::INTERVAL
                )::DATE;

                v_interes := round(v_saldo * v_tem, 2);
                IF i = r.plazo_meses THEN
                    v_capital := v_saldo;
                    v_saldo := 0;
                ELSE
                    v_capital := round(r.cuota_mensual - v_interes, 2);
                    v_saldo := round(v_saldo - v_capital, 2);
                END IF;

                INSERT INTO cr_cronograma_pagos (
                    cod_cuenta_credito, nro_cuota, fecha_vencimiento,
                    monto_cuota, monto_capital, monto_interes, saldo,
                    estado_cuota
                ) VALUES (
                    v_cod_credito, i, v_fecha_cuota,
                    r.cuota_mensual, v_capital, v_interes,
                    GREATEST(v_saldo, 0), 'pendiente'
                );
            END LOOP;
        END IF;

        INSERT INTO notificaciones (
            destinatario_tipo, cliente_id, titulo, cuerpo, tipo, data_json,
            leida, created_at
        ) VALUES (
            'cliente', v_cliente_id,
            CASE
                WHEN r.decision = 'rechazado' THEN 'Solicitud rechazada'
                WHEN r.decision = 'condicionado' THEN 'Solicitud aprobada con condicion'
                ELSE 'Credito desembolsado'
            END,
            CASE
                WHEN r.decision = 'rechazado' THEN r.motivo_rechazo
                WHEN r.decision = 'condicionado' THEN 'Monto aprobado: S/ ' || r.monto_aprobado::TEXT || '. ' || COALESCE(r.condicion_adicional, '')
                ELSE 'Tu credito empresarial fue desembolsado por S/ ' || r.monto_aprobado::TEXT || '.'
            END,
            CASE WHEN r.decision = 'rechazado' THEN 'rechazado' ELSE 'desembolsado' END,
            jsonb_build_object(
                'origen', '30_casos_credito_flujo_movil',
                'caso', r.caso,
                'numero_expediente', 'FM-' || lpad(r.caso::TEXT, 3, '0')
            ),
            FALSE,
            COALESCE(r.fecha_desembolso, v_fecha_asignacion) + TIME '12:30'
        );
    END LOOP;
END $$;

-- Controles esperados:
--   solicitudes FM-*     = 30
--   decisiones FM-*      = 30
--   consultas buro FM-*  = 30
--   creditos CRED-FM-*   = 27
--   cronograma CRED-FM-* = 510
--   documentos FM-*      = 150
DO $$
DECLARE
    v_solicitudes INTEGER;
    v_decisiones INTEGER;
    v_buro INTEGER;
    v_creditos INTEGER;
    v_cuotas INTEGER;
    v_documentos INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_solicitudes
    FROM solicitudes_credito
    WHERE numero_expediente LIKE 'FM-%';

    SELECT COUNT(*) INTO v_decisiones
    FROM solicitudes_decisiones sd
    JOIN solicitudes_credito sc ON sc.id = sd.solicitud_id
    WHERE sc.numero_expediente LIKE 'FM-%';

    SELECT COUNT(*) INTO v_buro
    FROM consultas_buro cb
    JOIN solicitudes_credito sc ON sc.id = cb.solicitud_id
    WHERE sc.numero_expediente LIKE 'FM-%';

    SELECT COUNT(*) INTO v_creditos
    FROM cr_creditos
    WHERE cod_cuenta_credito LIKE 'CRED-FM-%';

    SELECT COUNT(*) INTO v_cuotas
    FROM cr_cronograma_pagos
    WHERE cod_cuenta_credito LIKE 'CRED-FM-%';

    SELECT COUNT(*) INTO v_documentos
    FROM solicitudes_documentos sd
    JOIN solicitudes_credito sc ON sc.id = sd.solicitud_id
    WHERE sc.numero_expediente LIKE 'FM-%';

    IF v_solicitudes <> 30 OR v_decisiones <> 30 OR v_buro <> 30 OR
       v_creditos <> 27 OR v_cuotas <> 510 OR v_documentos <> 150 THEN
        RAISE EXCEPTION
            'Carga FM inconsistente: solicitudes %, decisiones %, buro %, creditos %, cuotas %, documentos %',
            v_solicitudes, v_decisiones, v_buro, v_creditos, v_cuotas, v_documentos;
    END IF;

    RAISE NOTICE
        'Carga 30 casos FM OK: solicitudes %, decisiones %, buro %, creditos %, cuotas %, documentos %',
        v_solicitudes, v_decisiones, v_buro, v_creditos, v_cuotas, v_documentos;
END $$;

COMMIT;

-- ============================================================================
-- FIN 08
-- ============================================================================
