-- ============================================================================
-- NEON BOOTSTRAP bd_core_mobile
-- Pegar este archivo completo en Neon SQL Editor y ejecutar.
-- No incluye 99_run_all.sql porque ese archivo usa comandos psql (\i, \echo).
-- ============================================================================


-- ============================================================================
-- BEGIN FILE: database/core_financiero_postgresql/01_DDL_create_tables_core_mobile.sql
-- ============================================================================

-- ============================================================================
-- bd_core_mobile — Capa operacional de canales moviles (Banco Andino)
-- ----------------------------------------------------------------------------
-- Base PostgreSQL servida por un backend FastAPI "mobile" (puerto sugerido 8003).
-- La consumen DOS apps moviles:
--   - App Fuerza de Ventas (Flutter)   -> originacion en campo (escritura)
--   - App Clientes appbanco_s8 (Kotlin) -> autoservicio (consulta + solicitudes)
--
-- Relacion con el nucleo bd_core_financiero (core 8001 + homebanking 8002):
--   - mobile -> core : solicitudes capturadas se PROMUEVEN al core via servicio
--                      (cola sync_outbox -> dsolicitud / dcliente del core).
--   - core -> mobile : estados, saldos, cronograma y movimientos se REPLICAN a
--                      las tablas espejo (prefijo cr_) para consulta offline.
--
-- Convencion de nombres: snake_case OLTP, PK UUID, FKs con sufijo _id.
-- Puente al core: columnas cod_* que mapean a los cod* del core
-- (codcliente, codsolicitud, codcuentacredito...). NO se comparten PKs.
-- ============================================================================

-- Requiere PostgreSQL 13+ (gen_random_uuid en pgcrypto / nativo en PG18).
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================================
-- GRUPO 1 — IDENTIDAD / CATALOGOS  (referencia, algunos espejo del core)
-- ============================================================================

CREATE TABLE agencias (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cod_agencia     VARCHAR(20) UNIQUE NOT NULL,   -- = dagencia.codagencia (core)
    nombre          VARCHAR(100) NOT NULL,
    region          VARCHAR(50),
    lat             DECIMAL(10,7),
    lng             DECIMAL(10,7),
    activa          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Asesores de negocio (usuarios de la app de fuerza de ventas).
CREATE TABLE asesores (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cod_asesor        VARCHAR(20) UNIQUE,           -- = dasesor.codasesor (core)
    codigo_empleado   VARCHAR(10) UNIQUE NOT NULL,  -- login (RF-01)
    nombres           VARCHAR(100) NOT NULL,
    apellidos         VARCHAR(100) NOT NULL,
    agencia_id        UUID REFERENCES agencias(id),
    perfil            VARCHAR(20) NOT NULL DEFAULT 'operador'
                      CHECK (perfil IN ('operador','super_operador','supervisor','administrador')),
    password_hash     TEXT NOT NULL,
    token_fcm         TEXT,                          -- notificaciones push (RF-73)
    intentos_fallidos INTEGER NOT NULL DEFAULT 0,    -- bloqueo (RF-04)
    bloqueado_hasta   TIMESTAMPTZ,
    activo            BOOLEAN NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Clientes. Espejo del core (dcliente) + datos capturados en campo.
CREATE TABLE clientes (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cod_cliente              VARCHAR(20) UNIQUE,      -- = dcliente.codcliente (core); NULL si es prospecto nuevo
    numero_documento         VARCHAR(15) UNIQUE NOT NULL,
    tipo_documento           VARCHAR(5) NOT NULL DEFAULT 'DNI' CHECK (tipo_documento IN ('DNI','RUC','CE')),
    nombres                  VARCHAR(100) NOT NULL,
    apellidos                VARCHAR(100) NOT NULL,
    fecha_nacimiento         DATE,
    estado_civil             VARCHAR(15),
    telefono                 VARCHAR(15),
    email                    VARCHAR(100),
    direccion                TEXT,
    tipo_negocio             VARCHAR(30),
    nombre_negocio           VARCHAR(100),
    antiguedad_negocio_meses INTEGER,
    ingresos_estimados       DECIMAL(12,2),
    lat                      DECIMAL(10,7),
    lng                      DECIMAL(10,7),
    calificacion_sbs         VARCHAR(15),             -- Normal/CPP/Deficiente/Dudoso/Perdida
    es_prospecto             BOOLEAN NOT NULL DEFAULT FALSE, -- aun no existe en el core
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- GRUPO 2 — ESPEJO DEL CORE (read-only en mobile; sync core -> mobile)
--   Prefijo cr_ (core-replica). Se actualizan por el servicio de sync.
-- ============================================================================

-- Espejo de dcuentacredito + fagcuentacredito (posicion del credito).
CREATE TABLE cr_creditos (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cod_cuenta_credito   VARCHAR(30) UNIQUE NOT NULL,  -- = dcuentacredito.codcuentacredito
    cliente_id           UUID NOT NULL REFERENCES clientes(id),
    producto             VARCHAR(40),
    monto_desembolsado   DECIMAL(12,2),
    saldo_capital        DECIMAL(12,2),
    saldo_total          DECIMAL(12,2),
    dias_mora            INTEGER NOT NULL DEFAULT 0,
    calificacion_interna VARCHAR(20),
    estado               VARCHAR(20),                 -- vigente/pagado/vencido/castigado
    fecha_desembolso     DATE,
    tea                  DECIMAL(5,2),
    cuotas_total         INTEGER,
    cuotas_pagadas       INTEGER,
    sync_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Espejo de fplanpagomes (cronograma de cuotas).
CREATE TABLE cr_cronograma_pagos (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cod_cuenta_credito  VARCHAR(30) NOT NULL REFERENCES cr_creditos(cod_cuenta_credito) ON DELETE CASCADE,
    nro_cuota           INTEGER NOT NULL,
    fecha_vencimiento   DATE NOT NULL,
    monto_cuota         DECIMAL(10,2),
    monto_capital       DECIMAL(10,2),
    monto_interes       DECIMAL(10,2),
    saldo               DECIMAL(12,2),
    estado_cuota        VARCHAR(20),                 -- pendiente/pagada/vencida
    fecha_pago          DATE,
    sync_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (cod_cuenta_credito, nro_cuota)
);

-- Espejo de dcuentaahorro + fcuentaahorro (para app de clientes).
CREATE TABLE cr_cuentas_ahorro (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cod_cuenta_ahorro   VARCHAR(30) UNIQUE NOT NULL,  -- = dcuentaahorro.codcuentaahorro
    cliente_id          UUID NOT NULL REFERENCES clientes(id),
    tipo_cuenta         VARCHAR(40),
    moneda              VARCHAR(3) DEFAULT 'PEN',
    saldo_capital       DECIMAL(12,2),
    saldo_interes       DECIMAL(12,2),
    tea                 DECIMAL(5,2),
    estado              VARCHAR(20),
    sync_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Espejo de foperaciones (movimientos: pagos, transferencias) para app clientes.
CREATE TABLE cr_movimientos (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cod_operacion       VARCHAR(40) UNIQUE NOT NULL,  -- = foperaciones.codkardex
    cliente_id          UUID NOT NULL REFERENCES clientes(id),
    cod_cuenta          VARCHAR(30),                  -- credito o ahorro
    tipo                VARCHAR(10),                  -- DEB/CRE/TRF
    concepto            VARCHAR(60),
    canal               VARCHAR(20),                  -- APP/WEB/VENTANILLA
    monto               DECIMAL(12,2) NOT NULL,
    moneda              VARCHAR(3) DEFAULT 'PEN',
    fecha_operacion     TIMESTAMPTZ NOT NULL,
    sync_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- GRUPO 3 — OPERACION FUERZA DE VENTAS (origen; escribe la app Flutter)
-- ============================================================================

CREATE TABLE creditos_preaprobados (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cliente_id           UUID NOT NULL REFERENCES clientes(id),
    asesor_id            UUID REFERENCES asesores(id),
    monto_maximo         DECIMAL(12,2) NOT NULL,
    plazo_sugerido_meses INTEGER,
    tea_referencial      DECIMAL(5,2),
    score_confianza      INTEGER CHECK (score_confianza BETWEEN 0 AND 100),
    vigente              BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_calculo        DATE,
    fecha_vencimiento    DATE,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Cartera asignada del dia (RF-09). UNIQUE evita duplicar cliente por dia.
CREATE TABLE cartera_diaria (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asesor_id          UUID NOT NULL REFERENCES asesores(id),
    cliente_id         UUID NOT NULL REFERENCES clientes(id),
    agencia_id         UUID REFERENCES agencias(id),
    fecha_asignacion   DATE NOT NULL,
    tipo_gestion       VARCHAR(30) NOT NULL
                       CHECK (tipo_gestion IN ('RENOVACION','AMPLIACION','NUEVA_SOLICITUD',
                                               'SEGUIMIENTO','RECUPERACION_MORA','DESERTOR')),
    prioridad          VARCHAR(10) DEFAULT 'normal' CHECK (prioridad IN ('alta','media','normal')),
    score_prioridad    INTEGER DEFAULT 0,
    monto_credito      DECIMAL(12,2),
    estado_visita      VARCHAR(20) DEFAULT 'pendiente'
                       CHECK (estado_visita IN ('pendiente','visitado','no_encontrado','reagendado','negocio_cerrado')),
    resultado_visita   VARCHAR(30),
    observacion_visita TEXT,
    timestamp_visita   TIMESTAMPTZ,
    lat_visita         DECIMAL(10,7),
    lng_visita         DECIMAL(10,7),
    orden_manual       INTEGER,
    UNIQUE (asesor_id, cliente_id, fecha_asignacion)
);

CREATE TABLE campanas_activas (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asesor_id         UUID NOT NULL REFERENCES asesores(id),
    cliente_id        UUID NOT NULL REFERENCES clientes(id),
    tipo              VARCHAR(30),                 -- renovacion/ampliacion/producto_paralelo
    monto_ofertado    DECIMAL(12,2),
    fecha_vencimiento DATE,
    activa            BOOLEAN NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Solicitud de credito capturada en campo (M5). Se promueve al core (dsolicitud).
CREATE TABLE solicitudes_credito (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_expediente        VARCHAR(20) UNIQUE,        -- asignado por el core al promover
    cod_solicitud_core       VARCHAR(20),               -- = dsolicitud.codsolicitud tras promocion
    asesor_id                UUID NOT NULL REFERENCES asesores(id),
    cliente_id               UUID NOT NULL REFERENCES clientes(id),
    agencia_id               UUID REFERENCES agencias(id),
    canal                    VARCHAR(15) NOT NULL DEFAULT 'asesor'  -- asesor | cliente (appbanco)
                             CHECK (canal IN ('asesor','cliente')),
    -- negocio
    tipo_negocio             VARCHAR(30),
    nombre_negocio           VARCHAR(100),
    actividad_economica      VARCHAR(10),               -- CIIU
    antiguedad_negocio_meses INTEGER,
    ingresos_estimados       DECIMAL(12,2),
    gastos_mensuales         DECIMAL(12,2),
    patrimonio_estimado      DECIMAL(12,2),
    -- co-deudores
    tiene_conyuge            BOOLEAN DEFAULT FALSE,
    conyuge_json             JSONB,
    tiene_garante            BOOLEAN DEFAULT FALSE,
    garante_json             JSONB,
    -- condiciones
    monto_solicitado         DECIMAL(12,2) NOT NULL,
    plazo_meses              INTEGER,
    moneda                   VARCHAR(3) DEFAULT 'PEN',
    tipo_cuota               VARCHAR(10) DEFAULT 'mensual',
    garantia                 VARCHAR(20),
    destino_credito          TEXT,
    cuota_estimada           DECIMAL(10,2),
    tea_referencial          DECIMAL(5,2),
    -- ciclo de estado (mobile + reflejo del core)
    estado                   VARCHAR(30) NOT NULL DEFAULT 'borrador'
                             CHECK (estado IN ('borrador','enviado','recibido_comite','en_evaluacion',
                                               'aprobado','condicionado','rechazado','desembolsado')),
    monto_aprobado           DECIMAL(12,2),
    motivo_rechazo           TEXT,
    condicion_adicional      TEXT,
    analista_asignado        VARCHAR(100),
    firma_cliente_base64     TEXT,
    lat_captura              DECIMAL(10,7),
    lng_captura              DECIMAL(10,7),
    pendiente_sync           BOOLEAN NOT NULL DEFAULT FALSE,  -- offline-first (RF-17)
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE solicitudes_documentos (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    solicitud_id    UUID NOT NULL REFERENCES solicitudes_credito(id) ON DELETE CASCADE,
    tipo_documento  VARCHAR(40) NOT NULL,    -- dni_anverso/dni_reverso/ruc/recibo_servicios/foto_negocio/foto_visita/contrato_arrendamiento
    storage_url     TEXT,                    -- ruta en almacenamiento de archivos
    tamanio_kb      INTEGER,
    nitidez_score   DECIMAL(5,2),            -- varianza de Laplaciano (RF-54)
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE consultas_buro (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asesor_id                   UUID NOT NULL REFERENCES asesores(id),
    cliente_id                  UUID NOT NULL REFERENCES clientes(id),
    solicitud_id                UUID REFERENCES solicitudes_credito(id),
    dni_consultado              VARCHAR(15) NOT NULL,
    calificacion_sbs            VARCHAR(20),
    entidades_con_deuda         INTEGER,
    deuda_total_pen             DECIMAL(12,2),
    mayor_deuda                 DECIMAL(12,2),
    dias_mayor_mora             INTEGER,
    en_lista_negra              BOOLEAN NOT NULL DEFAULT FALSE,
    motivo_bloqueo              TEXT,
    resultado_json             JSONB,
    firma_consentimiento_base64 TEXT,        -- Ley 29733 (RF-57)
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE acciones_cobranza (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asesor_id         UUID NOT NULL REFERENCES asesores(id),
    cliente_id        UUID NOT NULL REFERENCES clientes(id),
    cod_cuenta_credito VARCHAR(30) REFERENCES cr_creditos(cod_cuenta_credito),
    tipo_gestion      VARCHAR(20) CHECK (tipo_gestion IN ('visita','llamada','mensaje')),
    resultado         VARCHAR(30) CHECK (resultado IN ('compromiso_pago','pago_parcial','sin_contacto','se_niega')),
    monto_pagado      DECIMAL(12,2),
    fecha_compromiso  DATE,
    monto_compromiso  DECIMAL(12,2),
    observaciones     TEXT,
    lat               DECIMAL(10,7),
    lng               DECIMAL(10,7),
    timestamp_gestion TIMESTAMPTZ NOT NULL DEFAULT now(),
    pendiente_sync    BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE alertas_cartera (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asesor_id   UUID NOT NULL REFERENCES asesores(id),
    cliente_id  UUID NOT NULL REFERENCES clientes(id),
    tipo_alerta VARCHAR(30) CHECK (tipo_alerta IN ('primer_dia_mora','mora_30d','mora_60d','pago_parcial','pago_total')),
    mensaje     TEXT,
    leida       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE solicitudes_notas_internas (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    solicitud_id UUID NOT NULL REFERENCES solicitudes_credito(id) ON DELETE CASCADE,
    asesor_id    UUID NOT NULL REFERENCES asesores(id),
    contenido    TEXT NOT NULL CHECK (char_length(contenido) <= 500),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- GRUPO 4 — APP DE CLIENTES (autoservicio appbanco_s8)
-- ============================================================================

-- Credenciales del cliente (equivalente a usuarios_homebanking del core).
CREATE TABLE usuarios_cliente (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cliente_id        UUID NOT NULL UNIQUE REFERENCES clientes(id),
    username          VARCHAR(50) UNIQUE NOT NULL,   -- normalmente el numero_documento
    password_hash     TEXT NOT NULL,
    token_fcm         TEXT,
    activo            BOOLEAN NOT NULL DEFAULT TRUE,
    bloqueado         BOOLEAN NOT NULL DEFAULT FALSE,
    intentos_fallidos INTEGER NOT NULL DEFAULT 0,
    ultimo_acceso     TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Tarjetas de credito (la app appbanco_s8 las muestra; el core no las modela aun).
CREATE TABLE tarjetas (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cliente_id          UUID NOT NULL REFERENCES clientes(id),
    numero_enmascarado  VARCHAR(25) NOT NULL,         -- **** **** **** 1234
    marca               VARCHAR(20),                  -- visa/mastercard
    linea_credito       DECIMAL(12,2),
    saldo_utilizado     DECIMAL(12,2),
    fecha_corte         DATE,
    fecha_pago          DATE,
    estado              VARCHAR(20) DEFAULT 'activa',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Operaciones iniciadas por el cliente (pago de cuota, transferencia).
-- Se PROMUEVEN al core (foperaciones) via sync_outbox.
CREATE TABLE operaciones_cliente (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cliente_id         UUID NOT NULL REFERENCES clientes(id),
    cod_cuenta_origen  VARCHAR(30),
    cod_cuenta_destino VARCHAR(30),
    tipo               VARCHAR(20) CHECK (tipo IN ('pago_cuota','transferencia','recarga')),
    monto              DECIMAL(12,2) NOT NULL,
    moneda             VARCHAR(3) DEFAULT 'PEN',
    estado             VARCHAR(20) NOT NULL DEFAULT 'pendiente'
                       CHECK (estado IN ('pendiente','enviada','confirmada','rechazada')),
    cod_operacion_core VARCHAR(40),                   -- = foperaciones.codkardex tras promocion
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Notificaciones para ambas apps (push / centro de notificaciones).
CREATE TABLE notificaciones (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    destinatario_tipo VARCHAR(10) NOT NULL CHECK (destinatario_tipo IN ('asesor','cliente')),
    asesor_id    UUID REFERENCES asesores(id),
    cliente_id   UUID REFERENCES clientes(id),
    titulo       VARCHAR(120) NOT NULL,
    cuerpo       TEXT,
    tipo         VARCHAR(40),    -- recibido_comite/aprobado/rechazado/desembolsado/mora/...
    data_json    JSONB,
    leida        BOOLEAN NOT NULL DEFAULT FALSE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- GRUPO 5 — PUENTE DE SINCRONIZACION mobile <-> core
-- ============================================================================

-- Cola de salida: entidades de mobile que deben promoverse/aplicarse al core.
-- El servicio de promocion (FastAPI/worker) la lee, escribe en bd_core_financiero
-- y marca el resultado.
CREATE TABLE sync_outbox (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entidad         VARCHAR(40) NOT NULL,   -- solicitudes_credito / clientes / operaciones_cliente / acciones_cobranza
    entidad_id      UUID NOT NULL,          -- id local de la fila
    operacion       VARCHAR(10) NOT NULL CHECK (operacion IN ('create','update','delete')),
    payload         JSONB NOT NULL,         -- snapshot a enviar al core
    estado          VARCHAR(15) NOT NULL DEFAULT 'pendiente'
                    CHECK (estado IN ('pendiente','procesando','aplicado','error')),
    intentos        INTEGER NOT NULL DEFAULT 0,
    core_ref        VARCHAR(40),            -- cod* devuelto por el core (codsolicitud, codkardex...)
    ultimo_error    TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    procesado_at    TIMESTAMPTZ
);

-- Bitacora de sincronizacion (auditoria de ambas direcciones).
CREATE TABLE sync_log (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    direccion    VARCHAR(15) NOT NULL CHECK (direccion IN ('mobile_a_core','core_a_mobile')),
    entidad      VARCHAR(40) NOT NULL,
    referencia   VARCHAR(60),
    resultado    VARCHAR(15) NOT NULL CHECK (resultado IN ('ok','error')),
    detalle      TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- INDICES recomendados
-- ============================================================================
CREATE INDEX idx_cartera_asesor_fecha   ON cartera_diaria (asesor_id, fecha_asignacion);
CREATE INDEX idx_cartera_score          ON cartera_diaria (score_prioridad DESC);
CREATE INDEX idx_solicitudes_asesor     ON solicitudes_credito (asesor_id, created_at DESC);
CREATE INDEX idx_solicitudes_estado     ON solicitudes_credito (estado);
CREATE INDEX idx_solicitudes_pendsync   ON solicitudes_credito (pendiente_sync) WHERE pendiente_sync = TRUE;
CREATE INDEX idx_cronograma_credito     ON cr_cronograma_pagos (cod_cuenta_credito);
CREATE INDEX idx_movimientos_cliente    ON cr_movimientos (cliente_id, fecha_operacion DESC);
CREATE INDEX idx_alertas_asesor_noleida ON alertas_cartera (asesor_id) WHERE leida = FALSE;
CREATE INDEX idx_outbox_pendiente       ON sync_outbox (estado) WHERE estado = 'pendiente';

-- ============================================================================
-- FIN bd_core_mobile
-- ============================================================================

-- ============================================================================
-- END FILE: database/core_financiero_postgresql/01_DDL_create_tables_core_mobile.sql
-- ============================================================================

-- ============================================================================
-- BEGIN FILE: database/core_financiero_postgresql/02_DML_catalogos_core_mobile.sql
-- ============================================================================

-- ============================================================================
-- bd_core_mobile — 02) CATALOGOS  (datos genericos: agencias + asesores)
-- ----------------------------------------------------------------------------
-- 3 agencias ficticias y 30 asesores (10 por agencia). Datos de demostracion.
-- Login de la app Fuerza de Ventas:  codigo_empleado = 0001..0030
-- Contrasena para TODOS los asesores:  1234
--   (hash bcrypt valido, verificado contra passlib/CryptContext del backend)
-- ============================================================================

-- ── Agencias (nombres genericos, sin geolocalizacion real) ───────────────────
INSERT INTO agencias (cod_agencia, nombre, region, lat, lng, activa) VALUES
    ('AG-01', 'Agencia Norte',  NULL, NULL, NULL, TRUE),
    ('AG-02', 'Agencia Centro', NULL, NULL, NULL, TRUE),
    ('AG-03', 'Agencia Sur',    NULL, NULL, NULL, TRUE);

-- ── Asesores (cod_agencia se resuelve por JOIN; hash bcrypt unico de '1234') ──
INSERT INTO asesores (cod_asesor, codigo_empleado, nombres, apellidos, agencia_id, perfil, password_hash)
SELECT v.cod_asesor, v.codigo_empleado, v.nombres, v.apellidos, a.id, v.perfil,
       '$2b$12$D.eZtoXYYW79A0.tN9XwgOz4.t2fIqnGbiNoEY.n4Bvq6u/prRrTe'
FROM (VALUES
    -- AGENCIA NORTE (0001-0010)
    ('A001','0001','Carlos','Ramirez Quispe',  'AG-01','supervisor'),
    ('A002','0002','Lucia','Flores Mamani',     'AG-01','operador'),
    ('A003','0003','Jorge','Huaman Condori',    'AG-01','operador'),
    ('A004','0004','Rosa','Apaza Vargas',       'AG-01','operador'),
    ('A005','0005','Miguel','Ccahua Soto',      'AG-01','operador'),
    ('A006','0006','Elena','Quispe Ramos',      'AG-01','operador'),
    ('A007','0007','Victor','Mamani Huanca',    'AG-01','operador'),
    ('A008','0008','Sofia','Condori Lazo',      'AG-01','operador'),
    ('A009','0009','Raul','Vargas Inga',        'AG-01','operador'),
    ('A010','0010','Carmen','Soto Ñahui',       'AG-01','operador'),
    -- AGENCIA CENTRO (0011-0020)
    ('A011','0011','Pedro','Gutierrez Rojas',   'AG-02','supervisor'),
    ('A012','0012','Ana','Castro Paredes',      'AG-02','operador'),
    ('A013','0013','Luis','Meza Quinto',        'AG-02','operador'),
    ('A014','0014','Diana','Aliaga Camargo',    'AG-02','operador'),
    ('A015','0015','Oscar','Baldeon Sinche',    'AG-02','operador'),
    ('A016','0016','Patricia','Riveros Yupanqui','AG-02','operador'),
    ('A017','0017','Hector','Caceres Bullon',   'AG-02','operador'),
    ('A018','0018','Gloria','Espinoza Matos',   'AG-02','operador'),
    ('A019','0019','Javier','Pariona Taipe',    'AG-02','operador'),
    ('A020','0020','Nadia','Lopez Curo',        'AG-02','operador'),
    -- AGENCIA SUR (0021-0030)
    ('A021','0021','Fernando','Salazar Beraun', 'AG-03','supervisor'),
    ('A022','0022','Monica','Orihuela Cardenas','AG-03','operador'),
    ('A023','0023','Cesar','Bravo Galarza',     'AG-03','operador'),
    ('A024','0024','Veronica','Hinostroza Lozano','AG-03','operador'),
    ('A025','0025','Daniel','Maravi Surichaqui', 'AG-03','operador'),
    ('A026','0026','Karina','Poma Astuhuaman',  'AG-03','operador'),
    ('A027','0027','Renato','Chuquillanqui Veliz','AG-03','operador'),
    ('A028','0028','Ingrid','Ramos Palomino',   'AG-03','operador'),
    ('A029','0029','Alex','Quispe Bendezu',     'AG-03','operador'),
    ('A030','0030','Yesenia','Huaroc Pacheco',  'AG-03','operador')
) AS v(cod_asesor, codigo_empleado, nombres, apellidos, cod_agencia, perfil)
JOIN agencias a ON a.cod_agencia = v.cod_agencia;

-- ── Verificacion rapida ──────────────────────────────────────────────────────
-- SELECT ag.nombre, COUNT(*) FROM asesores a JOIN agencias ag ON ag.id=a.agencia_id GROUP BY ag.nombre;
--   Agencia Norte  -> 10
--   Agencia Centro -> 10
--   Agencia Sur    -> 10

-- ============================================================================
-- FIN catalogos
-- ============================================================================

-- ============================================================================
-- END FILE: database/core_financiero_postgresql/02_DML_catalogos_core_mobile.sql
-- ============================================================================

-- ============================================================================
-- BEGIN FILE: database/core_financiero_postgresql/03_DML_clientes_core_mobile.sql
-- ============================================================================

-- ============================================================================
-- bd_core_mobile — 03) CLIENTES  (600 clientes + acceso a la app de clientes)
-- ----------------------------------------------------------------------------
-- 30 asesores x 20 clientes = 600 clientes.
--   cod_cliente : C0001 .. C0600   (numero correlativo = clave de mapeo)
--   numero_documento (DNI) : 40000001 .. 40000600
--   Reparto por asesor: clientes C(20k+1 .. 20k+20) -> asesor k+1 (script 04).
-- Cada cliente tiene acceso a la app:  username = DNI   ·   password = 1234
-- Generacion DETERMINISTA (sin random) -> re-ejecutar produce los mismos datos.
-- ============================================================================

DO $$
DECLARE
    v_nombres   TEXT[] := ARRAY[
        'Maria','Jose','Rosa','Pedro','Lucia','Juan','Carmen','Luis','Ana','Cesar',
        'Sonia','Walter','Yolanda','Marco','Elena','Raul','Gladys','Hugo','Nilda','Edwin'];
    v_apellidos TEXT[] := ARRAY[
        'Quispe','Mamani','Condori','Apaza','Huaman','Vargas','Flores','Ccahua','Soto','Ramos',
        'Inga','Ñahui','Lazo','Huanca','Taipe','Pariona','Aliaga','Meza','Poma','Maravi',
        'Orihuela','Bravo','Salazar','Beraun','Surichaqui'];
    v_negocios  TEXT[] := ARRAY[
        'bodega','restaurante','ferreteria','farmacia','peluqueria',
        'taller mecanico','sastreria','libreria','carpinteria','polleria'];
    n        INT;
    v_dni    TEXT;
    v_nom    TEXT;
    v_ape    TEXT;
    v_neg    TEXT;
    v_hash   TEXT := '$2b$12$D.eZtoXYYW79A0.tN9XwgOz4.t2fIqnGbiNoEY.n4Bvq6u/prRrTe';
    v_cli_id UUID;
BEGIN
    FOR n IN 1..600 LOOP
        v_dni := lpad((40000000 + n)::text, 8, '0');
        v_nom := v_nombres[((n - 1) % array_length(v_nombres, 1)) + 1];
        v_ape := v_apellidos[((n * 7  - 1) % array_length(v_apellidos, 1)) + 1] || ' ' ||
                 v_apellidos[((n * 13 - 1) % array_length(v_apellidos, 1)) + 1];
        v_neg := v_negocios[((n - 1) % array_length(v_negocios, 1)) + 1];

        INSERT INTO clientes (
            cod_cliente, numero_documento, tipo_documento, nombres, apellidos,
            fecha_nacimiento, estado_civil, telefono, email, direccion,
            tipo_negocio, nombre_negocio, antiguedad_negocio_meses, ingresos_estimados,
            lat, lng, calificacion_sbs, es_prospecto
        ) VALUES (
            'C' || lpad(n::text, 4, '0'),
            v_dni, 'DNI', v_nom, v_ape,
            DATE '1972-01-01' + ((n * 97) % 9000),
            (ARRAY['soltero','casado','conviviente','viudo'])[((n - 1) % 4) + 1],
            '9' || lpad(((n * 811) % 100000000)::text, 8, '0'),
            lower(v_nom) || '.' || lower(split_part(v_ape, ' ', 1)) || n || '@correo.com',
            'Av. Principal ' || (100 + (n % 900)) || ' - ' ||
                (ARRAY['Agencia Norte','Agencia Centro','Agencia Sur'])[((n - 1) / 200) + 1],
            v_neg, initcap(v_neg) || ' ' || v_nom,
            6 + (n % 90),
            800 + (n % 40) * 150,
            NULL, NULL,
            (ARRAY['Normal','Normal','Normal','CPP','Deficiente'])[((n - 1) % 5) + 1],
            FALSE
        )
        RETURNING id INTO v_cli_id;

        -- Acceso a la app de clientes (appbanco_s8)
        INSERT INTO usuarios_cliente (cliente_id, username, password_hash, activo)
        VALUES (v_cli_id, v_dni, v_hash, TRUE);
    END LOOP;

    RAISE NOTICE 'Clientes insertados: %  | Accesos app: %',
        (SELECT COUNT(*) FROM clientes),
        (SELECT COUNT(*) FROM usuarios_cliente);
END $$;

-- ============================================================================
-- FIN clientes
-- ============================================================================

-- ============================================================================
-- END FILE: database/core_financiero_postgresql/03_DML_clientes_core_mobile.sql
-- ============================================================================

-- ============================================================================
-- BEGIN FILE: database/core_financiero_postgresql/04_DML_cartera_core_mobile.sql
-- ============================================================================

-- ============================================================================
-- bd_core_mobile — 04) CARTERA  (creditos + cronograma + cartera del dia +
--                                alertas + acciones de cobranza)
-- ----------------------------------------------------------------------------
-- Para cada uno de los 600 clientes (C0001..C0600) se genera 1 credito.
-- Reparto por asesor (20 clientes c/u) y por estado de cartera:
--     posicion  1..12  ->  VIGENTE  (al dia, dias_mora = 0)
--     posicion 13..17  ->  VENCIDA  (atraso 5..29 dias)
--     posicion 18..20  ->  MORA     (atraso 60..90 dias)
--   => por asesor: 12 vigente / 5 vencida / 3 mora
--   => total: 360 vigente / 150 vencida / 90 mora
-- Mapeo: cliente C(n) -> asesor codigo_empleado = lpad( ((n-1) DIV 20)+1 , 4).
-- Fechas relativas a CURRENT_DATE (la data se mantiene "fresca").
-- ============================================================================

DO $$
DECLARE
    n            INT;
    v_pos        INT;      -- 1..20 posicion del cliente dentro del asesor
    v_aseidx     INT;      -- 1..30 numero de asesor
    v_bucket     TEXT;     -- vigente | vencida | mora
    v_cli_id     UUID;
    v_ase_id     UUID;
    v_age_id     UUID;
    v_codcred    TEXT;
    -- financieros
    v_monto      NUMERIC;
    v_tea        NUMERIC;
    v_cuotas     INT;
    v_elapsed    INT;
    v_pagadas    INT;
    v_total      NUMERIC;
    v_cuota      NUMERIC;
    v_cap        NUMERIC;
    v_int        NUMERIC;
    v_desemb     DATE;
    v_diasmora   INT;
    v_estado     TEXT;
    v_calif      TEXT;
    v_saldocap   NUMERIC;
    v_saldotot   NUMERIC;
    -- cronograma
    k            INT;
    v_fven       DATE;
    v_estcuota   TEXT;
    v_fpago      DATE;
    v_saldo      NUMERIC;
    -- cartera diaria
    v_tipogest   TEXT;
    v_prioridad  TEXT;
    v_score      INT;
BEGIN
    FOR n IN 1..600 LOOP
        v_aseidx := ((n - 1) / 20) + 1;          -- 1..30
        v_pos    := ((n - 1) % 20) + 1;          -- 1..20

        IF    v_pos <= 12 THEN v_bucket := 'vigente';
        ELSIF v_pos <= 17 THEN v_bucket := 'vencida';
        ELSE                   v_bucket := 'mora';
        END IF;

        SELECT id INTO v_cli_id FROM clientes  WHERE cod_cliente = 'C' || lpad(n::text, 4, '0');
        SELECT a.id, a.agencia_id INTO v_ase_id, v_age_id
            FROM asesores a WHERE a.codigo_empleado = lpad(v_aseidx::text, 4, '0');

        v_codcred := 'CRED-' || lpad(n::text, 5, '0');

        -- ── Parametros del credito ───────────────────────────────────────────
        v_monto  := 5000 + ((n * 317) % 251) * 100;                 -- 5 000 .. 30 100
        v_tea    := 28 + (n % 20);                                  -- 28 .. 47 %
        v_cuotas := (ARRAY[12, 18, 24, 36])[((n - 1) % 4) + 1];
        v_elapsed := GREATEST(3, v_cuotas / 3);                     -- meses transcurridos

        v_total := round(v_monto + v_monto * (v_tea / 100.0) * (v_cuotas / 12.0), 2);
        v_cuota := round(v_total / v_cuotas, 2);
        v_cap   := round(v_monto / v_cuotas, 2);
        v_int   := round(v_cuota - v_cap, 2);

        -- Desembolso: hace v_elapsed meses + un desfase de 5..29 dias.
        v_desemb := (CURRENT_DATE
                     - (v_elapsed || ' months')::interval
                     - ((5 + (n % 25)) || ' days')::interval)::date;

        IF v_bucket = 'vigente' THEN
            v_pagadas  := v_elapsed;          -- al dia
            v_estado   := 'vigente';
            v_calif    := 'normal';
        ELSIF v_bucket = 'vencida' THEN
            v_pagadas  := v_elapsed - 1;      -- debe la ultima cuota vencida
            v_estado   := 'vencido';
            v_calif    := 'cpp';
        ELSE  -- mora
            v_pagadas  := GREATEST(v_elapsed - 3, 1);  -- 3 cuotas vencidas
            v_estado   := 'vencido';
            v_calif    := CASE WHEN (n % 2) = 0 THEN 'deficiente' ELSE 'dudoso' END;
        END IF;

        -- dias de mora reales = dias desde el vencimiento de la 1ra cuota impaga
        IF v_bucket = 'vigente' THEN
            v_diasmora := 0;
        ELSE
            v_diasmora := CURRENT_DATE
                        - (v_desemb + ((v_pagadas + 1) || ' months')::interval)::date;
            IF v_diasmora < 0 THEN v_diasmora := 0; END IF;
        END IF;

        v_saldocap := round(GREATEST(v_monto - v_cap * v_pagadas, 0), 2);
        v_saldotot := round(v_cuota * (v_cuotas - v_pagadas), 2);

        -- ── cr_creditos ──────────────────────────────────────────────────────
        INSERT INTO cr_creditos (
            cod_cuenta_credito, cliente_id, producto, monto_desembolsado,
            saldo_capital, saldo_total, dias_mora, calificacion_interna, estado,
            fecha_desembolso, tea, cuotas_total, cuotas_pagadas
        ) VALUES (
            v_codcred, v_cli_id,
            (ARRAY['Capital de Trabajo','Credito Negocio','Microcredito','Credito Pyme'])[((n - 1) % 4) + 1],
            v_monto, v_saldocap, v_saldotot, v_diasmora, v_calif, v_estado,
            v_desemb, v_tea, v_cuotas, v_pagadas
        );

        -- ── cr_cronograma_pagos ──────────────────────────────────────────────
        FOR k IN 1..v_cuotas LOOP
            v_fven  := (v_desemb + (k || ' months')::interval)::date;
            v_saldo := round(GREATEST(v_monto - v_cap * k, 0), 2);

            IF k <= v_pagadas THEN
                v_estcuota := 'pagada';
                v_fpago    := v_fven - ((1 + (n % 5)) || ' days')::interval;
            ELSIF v_fven < CURRENT_DATE THEN
                v_estcuota := 'vencida';
                v_fpago    := NULL;
            ELSE
                v_estcuota := 'pendiente';
                v_fpago    := NULL;
            END IF;

            INSERT INTO cr_cronograma_pagos (
                cod_cuenta_credito, nro_cuota, fecha_vencimiento, monto_cuota,
                monto_capital, monto_interes, saldo, estado_cuota, fecha_pago
            ) VALUES (
                v_codcred, k, v_fven, v_cuota, v_cap, v_int, v_saldo, v_estcuota, v_fpago
            );
        END LOOP;

        -- ── cartera_diaria (gestion del dia) ─────────────────────────────────
        IF v_bucket = 'vigente' THEN
            v_tipogest  := (ARRAY['RENOVACION','AMPLIACION','NUEVA_SOLICITUD','SEGUIMIENTO'])[((n - 1) % 4) + 1];
            v_prioridad := (ARRAY['normal','media'])[((n - 1) % 2) + 1];
            v_score     := 10 + (n % 40);
        ELSIF v_bucket = 'vencida' THEN
            v_tipogest  := 'RECUPERACION_MORA';
            v_prioridad := 'media';
            v_score     := 50 + (n % 30);
        ELSE
            v_tipogest  := 'RECUPERACION_MORA';
            v_prioridad := 'alta';
            v_score     := 80 + (n % 20);
        END IF;

        INSERT INTO cartera_diaria (
            asesor_id, cliente_id, agencia_id, fecha_asignacion, tipo_gestion,
            prioridad, score_prioridad, monto_credito, estado_visita, orden_manual
        ) VALUES (
            v_ase_id, v_cli_id, v_age_id, CURRENT_DATE, v_tipogest,
            v_prioridad, v_score, v_monto, 'pendiente', v_pos
        );

        -- ── Alertas + acciones de cobranza (solo vencida / mora) ─────────────
        IF v_bucket <> 'vigente' THEN
            INSERT INTO alertas_cartera (asesor_id, cliente_id, tipo_alerta, mensaje, leida)
            VALUES (
                v_ase_id, v_cli_id,
                CASE
                    WHEN v_diasmora <= 3  THEN 'primer_dia_mora'
                    WHEN v_diasmora <= 60 THEN 'mora_30d'
                    ELSE 'mora_60d'
                END,
                'Credito ' || v_codcred || ' con ' || v_diasmora || ' dias de atraso. Saldo S/ ' || v_saldotot,
                FALSE
            );

            INSERT INTO acciones_cobranza (
                asesor_id, cliente_id, cod_cuenta_credito, tipo_gestion, resultado,
                monto_pagado, fecha_compromiso, monto_compromiso, observaciones
            ) VALUES (
                v_ase_id, v_cli_id, v_codcred,
                (ARRAY['visita','llamada','mensaje'])[((n - 1) % 3) + 1],
                (ARRAY['compromiso_pago','pago_parcial','sin_contacto','se_niega'])[((n - 1) % 4) + 1],
                CASE WHEN (n % 4) = 1 THEN round(v_cuota / 2, 2) ELSE NULL END,
                CASE WHEN (n % 4) = 0 THEN CURRENT_DATE + ((3 + (n % 7)) || ' days')::interval ELSE NULL END,
                CASE WHEN (n % 4) = 0 THEN v_cuota ELSE NULL END,
                'Gestion de recuperacion generada por simulacion.'
            );
        END IF;
    END LOOP;

    RAISE NOTICE 'Creditos: %  | Cuotas: %  | Cartera dia: %  | Alertas: %  | Cobranzas: %',
        (SELECT COUNT(*) FROM cr_creditos),
        (SELECT COUNT(*) FROM cr_cronograma_pagos),
        (SELECT COUNT(*) FROM cartera_diaria),
        (SELECT COUNT(*) FROM alertas_cartera),
        (SELECT COUNT(*) FROM acciones_cobranza);
END $$;

-- ============================================================================
-- VERIFICACION: distribucion de cartera por agencia y estado
-- ----------------------------------------------------------------------------
-- SELECT ag.nombre AS agencia,
--        SUM((c.estado='vigente')::int)                          AS vigentes,
--        SUM((c.estado='vencido' AND c.dias_mora<=30)::int)      AS vencidos,
--        SUM((c.estado='vencido' AND c.dias_mora>30)::int)       AS en_mora,
--        COUNT(*)                                                AS total
-- FROM cr_creditos c
-- JOIN clientes      cl ON cl.id = c.cliente_id
-- JOIN cartera_diaria cd ON cd.cliente_id = cl.id
-- JOIN agencias      ag ON ag.id = cd.agencia_id
-- GROUP BY ag.nombre ORDER BY ag.nombre;
--   Cada agencia -> 120 vigentes / 50 vencidos / 30 en_mora / 200 total
-- ============================================================================
-- FIN cartera
-- ============================================================================

-- ============================================================================
-- END FILE: database/core_financiero_postgresql/04_DML_cartera_core_mobile.sql
-- ============================================================================

-- ============================================================================
-- BEGIN FILE: database/core_financiero_postgresql/05_DML_app_cliente_extras_core_mobile.sql
-- ============================================================================

-- bd_core_mobile — 05) Extras App Clientes
-- Tarjetas y notificaciones demo para validar autoservicio movil.

INSERT INTO tarjetas (
    cliente_id, numero_enmascarado, marca, linea_credito, saldo_utilizado,
    fecha_corte, fecha_pago, estado
)
SELECT
    c.id,
    '**** **** **** ' || lpad((1000 + row_number() OVER (ORDER BY c.cod_cliente))::text, 4, '0'),
    CASE WHEN row_number() OVER (ORDER BY c.cod_cliente) % 2 = 0 THEN 'Mastercard' ELSE 'Visa' END,
    8000 + (row_number() OVER (ORDER BY c.cod_cliente) * 250),
    900 + (row_number() OVER (ORDER BY c.cod_cliente) * 37),
    current_date + 10,
    current_date + 25,
    'activa'
FROM clientes c
WHERE c.cod_cliente BETWEEN 'C0001' AND 'C0020'
ON CONFLICT DO NOTHING;

INSERT INTO notificaciones (
    destinatario_tipo, cliente_id, titulo, cuerpo, tipo, leida
)
SELECT
    'cliente',
    c.id,
    'Cronograma actualizado',
    'Tu proxima cuota ya esta disponible en la app.',
    'credito',
    FALSE
FROM clientes c
WHERE c.cod_cliente BETWEEN 'C0001' AND 'C0010'
ON CONFLICT DO NOTHING;

INSERT INTO notificaciones (
    destinatario_tipo, cliente_id, titulo, cuerpo, tipo, leida
)
SELECT
    'cliente',
    c.id,
    'Oferta preaprobada vigente',
    'Tienes una oferta de capital de trabajo disponible.',
    'oferta',
    FALSE
FROM clientes c
WHERE c.cod_cliente BETWEEN 'C0011' AND 'C0020'
ON CONFLICT DO NOTHING;

-- ============================================================================
-- END FILE: database/core_financiero_postgresql/05_DML_app_cliente_extras_core_mobile.sql
-- ============================================================================

-- ============================================================================
-- BEGIN FILE: database/core_financiero_postgresql/06_DDL_workflow_creditos.sql
-- ============================================================================

-- Flujo cliente -> vendedor -> comite web -> desembolso.

CREATE TABLE IF NOT EXISTS solicitudes_decisiones (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    solicitud_id    UUID NOT NULL REFERENCES solicitudes_credito(id) ON DELETE CASCADE,
    asesor_decisor_id UUID NOT NULL REFERENCES asesores(id),
    decision        VARCHAR(20) NOT NULL CHECK (decision IN ('aprobado','rechazado','condicionado')),
    monto_aprobado  DECIMAL(12,2),
    motivo          TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_decisiones_solicitud
    ON solicitudes_decisiones (solicitud_id, created_at DESC);

-- ============================================================================
-- END FILE: database/core_financiero_postgresql/06_DDL_workflow_creditos.sql
-- ============================================================================

-- ============================================================================
-- BEGIN FILE: database/core_financiero_postgresql/07_DML_cuentas_movimientos_demo.sql
-- ============================================================================

-- Cuentas y movimientos iniciales para autoservicio del cliente.

INSERT INTO cr_cuentas_ahorro (
    cod_cuenta_ahorro, cliente_id, tipo_cuenta, moneda, saldo_capital,
    saldo_interes, tea, estado
)
SELECT
    'AHO-' || substring(c.cod_cliente from 2),
    c.id,
    'Ahorro soles',
    'PEN',
    1500 + (substring(c.cod_cliente from 2)::integer * 7 % 8500),
    0,
    0.50,
    'activa'
FROM clientes c
WHERE c.cod_cliente IS NOT NULL
ON CONFLICT (cod_cuenta_ahorro) DO NOTHING;

INSERT INTO cr_movimientos (
    cod_operacion, cliente_id, cod_cuenta, tipo, concepto, canal,
    monto, moneda, fecha_operacion
)
SELECT
    'MOV-INI-' || substring(c.cod_cliente from 2),
    c.id,
    'AHO-' || substring(c.cod_cliente from 2),
    'CRE',
    'Saldo inicial',
    'CORE',
    1500 + (substring(c.cod_cliente from 2)::integer * 7 % 8500),
    'PEN',
    now() - interval '2 days'
FROM clientes c
WHERE c.cod_cliente IS NOT NULL
ON CONFLICT (cod_operacion) DO NOTHING;

-- ============================================================================
-- END FILE: database/core_financiero_postgresql/07_DML_cuentas_movimientos_demo.sql
-- ============================================================================

-- ============================================================================
-- BEGIN FILE: database/core_financiero_postgresql/08_DML_30_casos_credito_flujo_movil.sql
-- ============================================================================

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

-- ============================================================================
-- END FILE: database/core_financiero_postgresql/08_DML_30_casos_credito_flujo_movil.sql
-- ============================================================================

-- ============================================================================
-- VERIFICACION FINAL NEON
-- ============================================================================
SELECT 'clientes' AS item, COUNT(*) AS total FROM clientes
UNION ALL SELECT 'asesores', COUNT(*) FROM asesores
UNION ALL SELECT 'solicitudes_fm', COUNT(*) FROM solicitudes_credito WHERE numero_expediente LIKE 'FM-%'
UNION ALL SELECT 'creditos_fm', COUNT(*) FROM cr_creditos WHERE cod_cuenta_credito LIKE 'CRED-FM-%'
UNION ALL SELECT 'cuotas_fm', COUNT(*) FROM cr_cronograma_pagos WHERE cod_cuenta_credito LIKE 'CRED-FM-%'
UNION ALL SELECT 'documentos_fm', COUNT(*) FROM solicitudes_documentos sd JOIN solicitudes_credito sc ON sc.id = sd.solicitud_id WHERE sc.numero_expediente LIKE 'FM-%'
ORDER BY item;
