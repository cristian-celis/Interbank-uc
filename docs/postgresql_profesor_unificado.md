# PostgreSQL local - Scripts del profesor y conexion Flutter

Este documento unifica los cinco scripts SQL entregados por el profesor y deja el paso a paso para instalar PostgreSQL en macOS, cargar la base local y correr la app Flutter conectada a esa base.

## Resumen rapido

- Motor requerido: PostgreSQL local.
- Base de datos: `bd_appmovil_fventas`.
- Usuario recomendado para demo: `postgres`.
- Puerto local por defecto: `5432`.
- App Flutter: por defecto corre con mocks; para usar PostgreSQL hay que pasar `--dart-define=DATA_SOURCE=postgres`.

## 1. Descargar e instalar PostgreSQL en Mac

Opcion recomendada para esta entrega: instalador oficial de PostgreSQL para macOS, porque instala el servidor y normalmente ofrece pgAdmin 4.

1. Entra a https://www.postgresql.org/download/macosx/.
2. Descarga el instalador para macOS.
3. Ejecuta el instalador.
4. Cuando pida password para el usuario administrador `postgres`, pon una password y anotala. En los ejemplos uso `postgres`; si eliges otra, reemplazala en los comandos.
5. Instala pgAdmin 4 si el instalador lo ofrece. Si no aparece, descargalo desde https://www.pgadmin.org/download/.

Alternativa valida: Postgres.app desde https://postgres.app/. Es mas simple para Mac, pero para una entrega universitaria con pgAdmin suele ser mas directo usar el instalador oficial.

## 2. Crear la base en pgAdmin

1. Abre `pgAdmin 4`.
2. En `Servers`, conectate al servidor PostgreSQL local con la password que creaste para `postgres`.
3. Clic derecho en `Databases` -> `Create` -> `Database...`.
4. En `Database`, escribe exactamente:

```text
bd_appmovil_fventas
```

5. En `Owner`, deja `postgres`.
6. Guarda.

## 3. Ejecutar los scripts del profesor en pgAdmin

Ejecutalos en este orden, siempre conectada la ventana `Query Tool` a la base `bd_appmovil_fventas`:

1. `00_setup_base_local.sql`
2. `01_scoring_tablas_funciones_local.sql`
3. `02_agencias_asesores_local.sql`
4. `03_seed_demo_local.sql`
5. `04_test_scoring_local.sql`

Forma de hacerlo:

1. Selecciona la base `bd_appmovil_fventas`.
2. Abre `Query Tool`.
3. Abre el archivo SQL correspondiente o pega su contenido.
4. Presiona ejecutar.
5. Espera a que termine sin errores.
6. Repite con el siguiente archivo.

El script `04_test_scoring_local.sql` es de validacion: si devuelve tablas/resultados, la BD quedo lista.

## 4. Ejecutar los scripts por terminal

Si despues de instalar PostgreSQL tienes `psql` disponible, puedes usar:

```bash
createdb -U postgres bd_appmovil_fventas
psql -U postgres -d bd_appmovil_fventas -f /Users/cc/Downloads/00_setup_base_local.sql
psql -U postgres -d bd_appmovil_fventas -f /Users/cc/Downloads/01_scoring_tablas_funciones_local.sql
psql -U postgres -d bd_appmovil_fventas -f /Users/cc/Downloads/02_agencias_asesores_local.sql
psql -U postgres -d bd_appmovil_fventas -f /Users/cc/Downloads/03_seed_demo_local.sql
psql -U postgres -d bd_appmovil_fventas -f /Users/cc/Downloads/04_test_scoring_local.sql
```

Si `psql` dice `command not found`, usa pgAdmin o agrega PostgreSQL al PATH. En instalaciones oficiales suele estar en una ruta similar a:

```bash
/Library/PostgreSQL/17/bin
```

La version puede cambiar segun lo que instales.

## 5. Conectar la app Flutter a PostgreSQL

La app ya tiene integrado el paquete Dart `postgres` y el origen de datos `LocalPostgresBankDataSource`. Por defecto corre con datos mock. Para conectar a PostgreSQL local usa `DATA_SOURCE=postgres`.

### Correr en Chrome o macOS local

```bash
flutter run -d chrome \
  --dart-define=DATA_SOURCE=postgres \
  --dart-define=PG_HOST=localhost \
  --dart-define=PG_PORT=5432 \
  --dart-define=PG_DATABASE=bd_appmovil_fventas \
  --dart-define=PG_USER=postgres \
  --dart-define=PG_PASSWORD=postgres
```

Cambia `PG_PASSWORD=postgres` por la password real que pusiste al instalar PostgreSQL.

### Correr en Android emulator

En Android emulator, `localhost` apunta al emulador, no a tu Mac. Por eso se usa `10.0.2.2`:

```bash
flutter run \
  --dart-define=DATA_SOURCE=postgres \
  --dart-define=PG_HOST=10.0.2.2 \
  --dart-define=PG_PORT=5432 \
  --dart-define=PG_DATABASE=bd_appmovil_fventas \
  --dart-define=PG_USER=postgres \
  --dart-define=PG_PASSWORD=postgres
```

### Correr en celular fisico

1. Conecta tu Mac y tu celular a la misma red Wi-Fi.
2. Busca la IP local de tu Mac:

```bash
ipconfig getifaddr en0
```

3. Usa esa IP como `PG_HOST`:

```bash
flutter run \
  --dart-define=DATA_SOURCE=postgres \
  --dart-define=PG_HOST=192.168.1.50 \
  --dart-define=PG_PORT=5432 \
  --dart-define=PG_DATABASE=bd_appmovil_fventas \
  --dart-define=PG_USER=postgres \
  --dart-define=PG_PASSWORD=postgres
```

Reemplaza `192.168.1.50` por la IP real de tu Mac. Para celular fisico puede hacer falta permitir conexiones entrantes a PostgreSQL en macOS y configurar PostgreSQL para escuchar conexiones de red.

## 6. Usuario demo para probar

El seed del profesor crea asesores. Para probar fuerza de ventas usa este correo en login:

```text
jessica.quispe@fieldiq.pe
```

La password no se valida criptograficamente en esta demo local; el login busca el correo en `usuarios_mock`. Puedes escribir `123456`.

## 7. Como saber que funciono

En la app deberias ver datos reales provenientes de PostgreSQL:

- Cartera diaria de Jessica.
- Rutas planificadas del dia.
- Scores y segmentos.
- Fichas de campo.
- Solicitudes nuevas insertadas en `fichas_campo`.

Si corres sin `DATA_SOURCE=postgres`, la app usa mocks y no toca la base de datos.

## 8. Nota importante

Esta conexion directa Flutter -> PostgreSQL sirve para demo local y requisito academico. En produccion lo correcto seria:

```text
App Flutter -> API backend -> PostgreSQL
```

Conectar una app movil directo a PostgreSQL expone credenciales y solo conviene en entorno local/controlado.

# Scripts SQL unificados

Los scripts siguientes estan pegados en el mismo orden recomendado. Si copias SQL manualmente desde este documento, ejecuta cada bloque por separado y respeta el orden.

## 00 - Setup base local

Origen: `/Users/cc/Downloads/00_setup_base_local.sql`

```sql
-- ============================================================
-- SCRIPT 00 — Setup Base LOCAL (pgAdmin / PostgreSQL)
-- App Móvil Fuerza de Ventas · v1.0
-- ============================================================
-- EJECUTAR: 1ro de 5
-- TIEMPO ESTIMADO: < 3 segundos
-- DONDE: pgAdmin 4 → Query Tool sobre DB: bd_appmovil_fventas
-- ============================================================
-- DIFERENCIA vs Supabase:
--   • NO usa auth.users → usa tabla propia: usuarios_mock
--   • NO tiene RLS → control de acceso en la app
--   • Ideal para pruebas locales y demos sin internet
-- ============================================================
-- QUÉ CREA:
--   usuarios_mock        → reemplaza auth.users de Supabase
--   cuentas              → M2 Cuentas
--   transacciones        → M3 Transacciones
--   pagos                → M4 Pagos
--   solicitudes_prestamo → M5 Préstamos
--   cuentas_ahorro       → M6 Ahorro
-- ============================================================

-- ── 0. Limpieza segura (orden inverso a FK) ───────────────
DROP TABLE IF EXISTS public.solicitudes_prestamo CASCADE;
DROP TABLE IF EXISTS public.cuentas_ahorro        CASCADE;
DROP TABLE IF EXISTS public.pagos                 CASCADE;
DROP TABLE IF EXISTS public.transacciones         CASCADE;
DROP TABLE IF EXISTS public.cuentas               CASCADE;
DROP TABLE IF EXISTS public.usuarios_mock         CASCADE;

-- ── 1. usuarios_mock (reemplaza auth.users) ───────────────
-- En Supabase la autenticación la maneja Supabase Auth.
-- En local, esta tabla simula los usuarios registrados.
CREATE TABLE public.usuarios_mock (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  email          TEXT        NOT NULL UNIQUE,
  nombre         TEXT        NOT NULL,
  apellido       TEXT        NOT NULL,
  password_hash  TEXT        NOT NULL DEFAULT 'demo_hash',
  rol            TEXT        NOT NULL DEFAULT 'cliente'
                             CHECK (rol IN ('cliente','asesor','admin')),
  activo         BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.usuarios_mock IS
  'Reemplaza auth.users de Supabase para entorno local/pgAdmin.
   Roles: cliente (portal), asesor (app móvil FV), admin (backoffice).';

-- ── 2. cuentas ────────────────────────────────────────────
CREATE TABLE public.cuentas (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID        NOT NULL REFERENCES public.usuarios_mock(id) ON DELETE CASCADE,
  tipo           TEXT        NOT NULL CHECK (tipo IN ('corriente','ahorro')),
  numero_cuenta  TEXT        NOT NULL UNIQUE,
  saldo          NUMERIC(12,2) NOT NULL DEFAULT 0,
  moneda         TEXT        NOT NULL DEFAULT 'PEN',
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ── 3. transacciones ──────────────────────────────────────
CREATE TABLE public.transacciones (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID        NOT NULL REFERENCES public.usuarios_mock(id) ON DELETE CASCADE,
  cuenta_id      UUID        REFERENCES public.cuentas(id) ON DELETE SET NULL,
  tipo           TEXT        NOT NULL CHECK (tipo IN ('debito','credito')),
  descripcion    TEXT        NOT NULL,
  monto          NUMERIC(12,2) NOT NULL,
  fecha          TIMESTAMPTZ DEFAULT NOW()
);

-- ── 4. pagos ──────────────────────────────────────────────
CREATE TABLE public.pagos (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID        NOT NULL REFERENCES public.usuarios_mock(id) ON DELETE CASCADE,
  servicio         TEXT        NOT NULL CHECK (servicio IN ('agua','luz','cable','telefono','gas')),
  numero_contrato  TEXT        NOT NULL,
  monto            NUMERIC(10,2) NOT NULL,
  estado           TEXT        NOT NULL DEFAULT 'completado',
  fecha            TIMESTAMPTZ DEFAULT NOW()
);

-- ── 5. solicitudes_prestamo ───────────────────────────────
CREATE TABLE public.solicitudes_prestamo (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID        NOT NULL REFERENCES public.usuarios_mock(id) ON DELETE CASCADE,
  monto          NUMERIC(12,2) NOT NULL,
  plazo_meses    INTEGER     NOT NULL,
  tasa_anual     NUMERIC(5,2) NOT NULL,
  cuota_mensual  NUMERIC(10,2) NOT NULL,
  proposito      TEXT,
  estado         TEXT        NOT NULL DEFAULT 'pendiente'
                             CHECK (estado IN ('pendiente','aprobado','rechazado','desembolsado')),
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ── 6. cuentas_ahorro ─────────────────────────────────────
CREATE TABLE public.cuentas_ahorro (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID        NOT NULL REFERENCES public.usuarios_mock(id) ON DELETE CASCADE,
  saldo           NUMERIC(12,2) NOT NULL DEFAULT 0,
  meta_ahorro     NUMERIC(12,2) NOT NULL DEFAULT 10000,
  tasa_interes    NUMERIC(5,2) NOT NULL DEFAULT 3.5,
  fecha_apertura  DATE        DEFAULT CURRENT_DATE
);

-- ── Índices de rendimiento ────────────────────────────────
CREATE INDEX idx_cuentas_user        ON public.cuentas(user_id);
CREATE INDEX idx_transacciones_user  ON public.transacciones(user_id);
CREATE INDEX idx_transacciones_fecha ON public.transacciones(fecha);
CREATE INDEX idx_pagos_user          ON public.pagos(user_id);
CREATE INDEX idx_solicitudes_user    ON public.solicitudes_prestamo(user_id);
CREATE INDEX idx_solicitudes_estado  ON public.solicitudes_prestamo(estado);

-- ── Verificación ──────────────────────────────────────────
SELECT
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns c
   WHERE c.table_name = t.table_name AND c.table_schema = 'public') AS columnas
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN (
    'usuarios_mock','cuentas','transacciones',
    'pagos','solicitudes_prestamo','cuentas_ahorro'
  )
ORDER BY table_name;

-- ============================================================
-- FIN — 00_setup_base_local.sql · v1.0
-- BD: bd_appmovil_fventas
-- Siguiente: ejecutar 01_scoring_tablas_funciones_local.sql
-- ============================================================
```

## 01 - Scoring: tablas, vistas y funciones

Origen: `/Users/cc/Downloads/01_scoring_tablas_funciones_local.sql`

```sql
-- ============================================================
-- SCRIPT 01 — Scoring: Tablas, Vistas y Funciones (LOCAL)
-- App Móvil Fuerza de Ventas · v1.0
-- ============================================================
-- EJECUTAR: 2do de 5  (después de 00_setup_base_local.sql)
-- TIEMPO ESTIMADO: < 5 segundos
-- DONDE: pgAdmin 4 → Query Tool sobre DB: bd_appmovil_fventas
-- ============================================================
-- QUÉ CREA:
--   perfiles_clientes     → datos socioeconómicos del cliente
--   movimientos_mensuales → historial financiero para scoring
--   features_scoring      → variables calculadas del modelo
--   scores_transaccionales→ resultado final del scoring
--   fichas_campo          → registro de visita del asesor en campo
--   creditos_preaprobados → resultado de la pre-aprobación
--
-- FUNCIONES:
--   calcular_features_scoring(uuid)
--   calcular_score_transaccional(uuid)
--   evaluar_credito_campo(uuid, numeric, int)
-- ============================================================

-- ── Limpieza segura ───────────────────────────────────────
DROP TABLE IF EXISTS public.creditos_preaprobados  CASCADE;
DROP TABLE IF EXISTS public.fichas_campo           CASCADE;
DROP TABLE IF EXISTS public.scores_transaccionales CASCADE;
DROP TABLE IF EXISTS public.features_scoring       CASCADE;
DROP TABLE IF EXISTS public.movimientos_mensuales  CASCADE;
DROP TABLE IF EXISTS public.perfiles_clientes      CASCADE;

DROP FUNCTION IF EXISTS public.evaluar_credito_campo(UUID, NUMERIC, INT);
DROP FUNCTION IF EXISTS public.calcular_score_transaccional(UUID);
DROP FUNCTION IF EXISTS public.calcular_features_scoring(UUID);

-- ════════════════════════════════════════════════════════════
-- TABLAS DE SCORING
-- ════════════════════════════════════════════════════════════

-- ── 1. perfiles_clientes ──────────────────────────────────
-- Datos socioeconómicos capturados por el asesor en campo
-- o pre-cargados desde el core bancario.
CREATE TABLE public.perfiles_clientes (
  id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID        NOT NULL REFERENCES public.usuarios_mock(id) ON DELETE CASCADE,

  -- Datos personales
  nombres               TEXT        NOT NULL DEFAULT '',
  apellidos             TEXT        NOT NULL DEFAULT '',
  dni                   TEXT        UNIQUE,
  fecha_nacimiento      DATE,
  genero                TEXT        CHECK (genero IN ('M','F','otro')),

  -- Datos de negocio (campo)
  tipo_negocio          TEXT,        -- 'bodega','ferreteria','transporte','agro', etc.
  antiguedad_negocio    INTEGER      DEFAULT 0,   -- meses
  local_propio          BOOLEAN      DEFAULT FALSE,
  zona_negocio          TEXT         CHECK (zona_negocio IN ('urbano','periurbano','rural')),

  -- Datos financieros capturados en campo
  ingreso_mensual_est   NUMERIC(10,2) DEFAULT 0,  -- estimado por asesor
  gasto_mensual_est     NUMERIC(10,2) DEFAULT 0,
  deuda_actual          NUMERIC(12,2) DEFAULT 0,
  entidades_deuda       INTEGER       DEFAULT 0,  -- cuántas entidades le deben

  -- Estado en el sistema
  estado_cliente        TEXT        NOT NULL DEFAULT 'prospecto'
                                    CHECK (estado_cliente IN (
                                      'prospecto','activo','moroso','castigado','retirado'
                                    )),
  puntaje_crediticio    NUMERIC(5,2) DEFAULT 0,   -- resultado del scoring

  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT uq_perfiles_user UNIQUE (user_id)
);

COMMENT ON TABLE public.perfiles_clientes IS
  'Perfil socioeconómico del cliente. Capturado en campo por el asesor
   usando la app móvil .NET MAUI / Flutter. Alimenta el motor de scoring.';

-- ── 2. movimientos_mensuales ──────────────────────────────
-- Resumen mensual calculado desde transacciones.
-- Insumo principal del motor de scoring.
CREATE TABLE public.movimientos_mensuales (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID        NOT NULL REFERENCES public.usuarios_mock(id) ON DELETE CASCADE,

  periodo           TEXT        NOT NULL,  -- 'YYYY-MM'  ej: '2025-03'
  total_creditos    NUMERIC(12,2) DEFAULT 0,
  total_debitos     NUMERIC(12,2) DEFAULT 0,
  saldo_promedio    NUMERIC(12,2) DEFAULT 0,
  num_transacciones INTEGER       DEFAULT 0,
  num_pagos_puntual INTEGER       DEFAULT 0,   -- pagos antes de vencimiento
  num_pagos_tardio  INTEGER       DEFAULT 0,

  created_at        TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT uq_mov_user_periodo UNIQUE (user_id, periodo)
);

-- ── 3. features_scoring ──────────────────────────────────
-- Variables del modelo ML calculadas a partir de
-- movimientos_mensuales + perfiles_clientes.
CREATE TABLE public.features_scoring (
  id                        UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                   UUID        NOT NULL REFERENCES public.usuarios_mock(id) ON DELETE CASCADE,

  -- Variables de comportamiento transaccional
  promedio_saldo_3m         NUMERIC(12,2) DEFAULT 0,  -- saldo promedio 3 meses
  variabilidad_saldo        NUMERIC(8,4)  DEFAULT 0,  -- coeficiente de variación
  ratio_credito_debito      NUMERIC(8,4)  DEFAULT 0,  -- créditos/débitos
  frecuencia_transacciones  NUMERIC(6,2)  DEFAULT 0,  -- txns/mes promedio
  porcentaje_pagos_puntual  NUMERIC(5,2)  DEFAULT 0,  -- % pagos a tiempo

  -- Variables del perfil de campo
  ratio_deuda_ingreso       NUMERIC(8,4)  DEFAULT 0,  -- deuda/ingreso mensual
  capacidad_pago            NUMERIC(10,2) DEFAULT 0,  -- ingreso - gastos - cuotas
  antiguedad_meses          INTEGER       DEFAULT 0,

  -- Fecha de cálculo
  calculado_at              TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT uq_features_user UNIQUE (user_id)
);

-- ── 4. scores_transaccionales ────────────────────────────
-- Resultado final del scoring con segmentación.
CREATE TABLE public.scores_transaccionales (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID        NOT NULL REFERENCES public.usuarios_mock(id) ON DELETE CASCADE,

  score             NUMERIC(5,2) NOT NULL DEFAULT 0, -- 0 a 100
  segmento          TEXT         NOT NULL DEFAULT 'C'
                                 CHECK (segmento IN ('A','B','C','D','E')),
  recomendacion     TEXT         NOT NULL DEFAULT 'evaluar_presencial',
  monto_max_sugerido NUMERIC(12,2) DEFAULT 0,

  -- Trazabilidad
  modelo_version    TEXT         DEFAULT 'v1.0_reglas',
  calculado_at      TIMESTAMPTZ  DEFAULT NOW(),

  CONSTRAINT uq_score_user UNIQUE (user_id)
);

COMMENT ON COLUMN public.scores_transaccionales.segmento IS
  'A: Excelente (85-100) → pre-aprobado inmediato
   B: Bueno    (70-84)  → aprobación rápida
   C: Regular  (50-69)  → evaluar con garantías
   D: Riesgoso (30-49)  → requiere comité
   E: Alto riesgo (<30) → rechazar';

-- ── 5. fichas_campo ──────────────────────────────────────
-- Registro de cada visita del asesor al cliente en campo.
-- Esta es la tabla CENTRAL de la app móvil fuerza de ventas.
CREATE TABLE public.fichas_campo (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  asesor_id           UUID        NOT NULL REFERENCES public.usuarios_mock(id),
  cliente_user_id     UUID        REFERENCES public.usuarios_mock(id),

  -- Si el cliente no está registrado aún (prospecto nuevo)
  prospecto_nombre    TEXT,
  prospecto_dni       TEXT,
  prospecto_telefono  TEXT,

  -- Geolocalización de la visita
  latitud             NUMERIC(10,7),
  longitud            NUMERIC(10,7),
  distrito            TEXT,
  provincia           TEXT        DEFAULT 'Huancayo',
  departamento        TEXT        DEFAULT 'Junín',

  -- Datos capturados en campo
  tipo_visita         TEXT        NOT NULL DEFAULT 'prospeccion'
                                  CHECK (tipo_visita IN (
                                    'prospeccion','renovacion',
                                    'seguimiento','cobranza'
                                  )),
  negocio_nombre      TEXT,
  negocio_rubro       TEXT,
  ingreso_declarado   NUMERIC(10,2) DEFAULT 0,
  gasto_declarado     NUMERIC(10,2) DEFAULT 0,

  -- Documentos (rutas locales o URLs en producción)
  foto_dni_path       TEXT,
  foto_negocio_path   TEXT,

  -- Estado del proceso
  estado_ficha        TEXT        NOT NULL DEFAULT 'borrador'
                                  CHECK (estado_ficha IN (
                                    'borrador','completada',
                                    'sincronizada','rechazada'
                                  )),
  score_obtenido      NUMERIC(5,2) DEFAULT 0,
  monto_solicitado    NUMERIC(12,2) DEFAULT 0,
  observaciones       TEXT,

  -- Sincronización offline-first
  creada_offline      BOOLEAN     DEFAULT FALSE,
  sincronizada_at     TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.fichas_campo IS
  'Registro de visita del asesor en campo.
   Soporta modo offline: creada_offline=TRUE cuando no hay internet.
   La app sincroniza al recuperar señal (sincronizada_at).
   Equivale al "expediente físico" digitalizado del video de referencia.';

-- ── 6. creditos_preaprobados ──────────────────────────────
-- Resultado final: crédito pre-aprobado para renovación
-- o nuevo cliente calificado.
CREATE TABLE public.creditos_preaprobados (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  ficha_id          UUID        NOT NULL REFERENCES public.fichas_campo(id),
  cliente_user_id   UUID        REFERENCES public.usuarios_mock(id),
  asesor_id         UUID        NOT NULL REFERENCES public.usuarios_mock(id),

  monto_preaprobado NUMERIC(12,2) NOT NULL,
  plazo_meses       INTEGER      NOT NULL DEFAULT 12,
  tasa_mensual      NUMERIC(6,4) NOT NULL DEFAULT 1.8,  -- TEM
  cuota_estimada    NUMERIC(10,2) GENERATED ALWAYS AS (
    ROUND(
      monto_preaprobado
      * (tasa_mensual/100 * POWER(1 + tasa_mensual/100, plazo_meses))
      / (POWER(1 + tasa_mensual/100, plazo_meses) - 1)
    , 2)
  ) STORED,

  score_aprobacion  NUMERIC(5,2) DEFAULT 0,
  estado            TEXT        NOT NULL DEFAULT 'pre-aprobado'
                                CHECK (estado IN (
                                  'pre-aprobado','en_comite',
                                  'aprobado','desembolsado','rechazado'
                                )),
  vigente_hasta     DATE        DEFAULT (CURRENT_DATE + INTERVAL '30 days'),
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.creditos_preaprobados IS
  'Pre-aprobación generada en campo por la app móvil.
   cuota_estimada se calcula automáticamente con la fórmula
   de cuota francesa (sistema francés): C = M * [i*(1+i)^n / ((1+i)^n - 1)]
   donde i = TEM/100 y n = plazo_meses.';

-- ════════════════════════════════════════════════════════════
-- ÍNDICES
-- ════════════════════════════════════════════════════════════
CREATE INDEX idx_perfiles_user          ON public.perfiles_clientes(user_id);
CREATE INDEX idx_perfiles_estado        ON public.perfiles_clientes(estado_cliente);
CREATE INDEX idx_mov_user_periodo       ON public.movimientos_mensuales(user_id, periodo);
CREATE INDEX idx_fichas_asesor          ON public.fichas_campo(asesor_id);
CREATE INDEX idx_fichas_estado          ON public.fichas_campo(estado_ficha);
CREATE INDEX idx_fichas_offline         ON public.fichas_campo(creada_offline) WHERE creada_offline = TRUE;
CREATE INDEX idx_creditos_estado        ON public.creditos_preaprobados(estado);
CREATE INDEX idx_creditos_vigencia      ON public.creditos_preaprobados(vigente_hasta);

-- ════════════════════════════════════════════════════════════
-- FUNCIÓN 1: calcular_features_scoring(user_id)
-- Calcula las variables del modelo desde movimientos y perfil
-- ════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.calcular_features_scoring(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  v_prom_saldo          NUMERIC(12,2);
  v_variabilidad        NUMERIC(8,4);
  v_ratio_cd            NUMERIC(8,4);
  v_freq_txn            NUMERIC(6,2);
  v_pct_puntual         NUMERIC(5,2);
  v_ratio_di            NUMERIC(8,4);
  v_cap_pago            NUMERIC(10,2);
  v_antiguedad          INTEGER;
  v_ingreso             NUMERIC(10,2);
  v_gasto               NUMERIC(10,2);
  v_deuda               NUMERIC(12,2);
BEGIN
  -- Promedio de saldo últimos 3 meses
  SELECT COALESCE(AVG(saldo_promedio), 0)
    INTO v_prom_saldo
    FROM public.movimientos_mensuales
   WHERE user_id = p_user_id
     AND periodo >= TO_CHAR(NOW() - INTERVAL '3 months', 'YYYY-MM');

  -- Variabilidad del saldo (coeficiente de variación)
  SELECT COALESCE(
    CASE WHEN AVG(saldo_promedio) = 0 THEN 0
         ELSE STDDEV(saldo_promedio) / AVG(saldo_promedio)
    END, 0)
    INTO v_variabilidad
    FROM public.movimientos_mensuales
   WHERE user_id = p_user_id
     AND periodo >= TO_CHAR(NOW() - INTERVAL '6 months', 'YYYY-MM');

  -- Ratio créditos/débitos
  SELECT COALESCE(
    CASE WHEN SUM(total_debitos) = 0 THEN 1
         ELSE SUM(total_creditos) / NULLIF(SUM(total_debitos), 0)
    END, 1)
    INTO v_ratio_cd
    FROM public.movimientos_mensuales
   WHERE user_id = p_user_id;

  -- Frecuencia de transacciones promedio mensual
  SELECT COALESCE(AVG(num_transacciones), 0)
    INTO v_freq_txn
    FROM public.movimientos_mensuales
   WHERE user_id = p_user_id;

  -- % pagos puntuales
  SELECT COALESCE(
    CASE WHEN (SUM(num_pagos_puntual) + SUM(num_pagos_tardio)) = 0 THEN 0
         ELSE SUM(num_pagos_puntual) * 100.0
              / (SUM(num_pagos_puntual) + SUM(num_pagos_tardio))
    END, 0)
    INTO v_pct_puntual
    FROM public.movimientos_mensuales
   WHERE user_id = p_user_id;

  -- Datos del perfil de campo
  SELECT
    COALESCE(ingreso_mensual_est, 0),
    COALESCE(gasto_mensual_est, 0),
    COALESCE(deuda_actual, 0),
    COALESCE(antiguedad_negocio, 0)
    INTO v_ingreso, v_gasto, v_deuda, v_antiguedad
    FROM public.perfiles_clientes
   WHERE user_id = p_user_id;

  -- Ratio deuda/ingreso
  v_ratio_di := CASE WHEN v_ingreso = 0 THEN 999
                     ELSE v_deuda / v_ingreso
                END;

  -- Capacidad de pago
  v_cap_pago := v_ingreso - v_gasto;

  -- INSERT o UPDATE en features_scoring
  INSERT INTO public.features_scoring (
    user_id,
    promedio_saldo_3m,
    variabilidad_saldo,
    ratio_credito_debito,
    frecuencia_transacciones,
    porcentaje_pagos_puntual,
    ratio_deuda_ingreso,
    capacidad_pago,
    antiguedad_meses,
    calculado_at
  )
  VALUES (
    p_user_id,
    v_prom_saldo,
    v_variabilidad,
    v_ratio_cd,
    v_freq_txn,
    v_pct_puntual,
    v_ratio_di,
    v_cap_pago,
    v_antiguedad,
    NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    promedio_saldo_3m        = EXCLUDED.promedio_saldo_3m,
    variabilidad_saldo       = EXCLUDED.variabilidad_saldo,
    ratio_credito_debito     = EXCLUDED.ratio_credito_debito,
    frecuencia_transacciones = EXCLUDED.frecuencia_transacciones,
    porcentaje_pagos_puntual = EXCLUDED.porcentaje_pagos_puntual,
    ratio_deuda_ingreso      = EXCLUDED.ratio_deuda_ingreso,
    capacidad_pago           = EXCLUDED.capacidad_pago,
    antiguedad_meses         = EXCLUDED.antiguedad_meses,
    calculado_at             = NOW();

  RAISE NOTICE 'Features calculadas para user_id: %', p_user_id;
END;
$$;

-- ════════════════════════════════════════════════════════════
-- FUNCIÓN 2: calcular_score_transaccional(user_id)
-- Motor de scoring por reglas v1.0
-- Basado en modelo de CAJA HUANCAYO (tesis Guillermo Peña)
-- Precisión validada: ~90% en datos históricos 2015-2020
-- ════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.calcular_score_transaccional(p_user_id UUID)
RETURNS NUMERIC(5,2)
LANGUAGE plpgsql
AS $$
DECLARE
  v_score           NUMERIC(5,2) := 0;
  v_segmento        TEXT;
  v_recomendacion   TEXT;
  v_monto_max       NUMERIC(12,2);
  f                 public.features_scoring%ROWTYPE;
BEGIN
  -- 1. Calcular features primero
  PERFORM public.calcular_features_scoring(p_user_id);

  -- 2. Leer features calculadas
  SELECT * INTO f
    FROM public.features_scoring
   WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No se encontraron features para user_id: %', p_user_id;
  END IF;

  -- ══════════════════════════════════════════════════
  -- MOTOR DE SCORING POR REGLAS (40 puntos posibles)
  -- Adaptado del modelo de Caja Huancayo
  -- ══════════════════════════════════════════════════

  -- BLOQUE A: Saldo promedio (máx 15 pts)
  --   Evalúa liquidez y capacidad transaccional
  v_score := v_score + CASE
    WHEN f.promedio_saldo_3m >= 5000  THEN 15   -- Alto saldo
    WHEN f.promedio_saldo_3m >= 2000  THEN 12   -- Saldo medio-alto
    WHEN f.promedio_saldo_3m >= 1000  THEN 9    -- Saldo medio
    WHEN f.promedio_saldo_3m >= 500   THEN 6    -- Saldo bajo
    WHEN f.promedio_saldo_3m >= 200   THEN 3    -- Saldo muy bajo
    ELSE 0
  END;

  -- BLOQUE B: Comportamiento de pagos (máx 20 pts)
  --   Variable más predictiva del modelo
  v_score := v_score + CASE
    WHEN f.porcentaje_pagos_puntual >= 95 THEN 20  -- Nunca se atrasa
    WHEN f.porcentaje_pagos_puntual >= 85 THEN 16  -- Casi siempre puntual
    WHEN f.porcentaje_pagos_puntual >= 70 THEN 12  -- Puntual frecuente
    WHEN f.porcentaje_pagos_puntual >= 50 THEN 7   -- A veces se atrasa
    WHEN f.porcentaje_pagos_puntual >= 30 THEN 3   -- Se atrasa seguido
    ELSE 0
  END;

  -- BLOQUE C: Capacidad de pago del negocio (máx 25 pts)
  --   Ingreso - Gasto. Clave para microempresas rurales
  v_score := v_score + CASE
    WHEN f.capacidad_pago >= 3000 THEN 25   -- Alta capacidad
    WHEN f.capacidad_pago >= 1500 THEN 20   -- Buena capacidad
    WHEN f.capacidad_pago >= 800  THEN 15   -- Capacidad media
    WHEN f.capacidad_pago >= 400  THEN 9    -- Capacidad baja
    WHEN f.capacidad_pago >= 100  THEN 4    -- Capacidad mínima
    ELSE 0
  END;

  -- BLOQUE D: Ratio deuda/ingreso (máx 15 pts)
  --   Penaliza sobre-endeudamiento
  v_score := v_score + CASE
    WHEN f.ratio_deuda_ingreso <= 0.3  THEN 15  -- Deuda baja
    WHEN f.ratio_deuda_ingreso <= 0.5  THEN 12  -- Deuda moderada
    WHEN f.ratio_deuda_ingreso <= 0.7  THEN 8   -- Deuda media
    WHEN f.ratio_deuda_ingreso <= 1.0  THEN 4   -- Deuda alta
    WHEN f.ratio_deuda_ingreso <= 1.5  THEN 2   -- Deuda muy alta
    ELSE 0
  END;

  -- BLOQUE E: Antigüedad del negocio (máx 10 pts)
  --   Meses de operación = estabilidad
  v_score := v_score + CASE
    WHEN f.antiguedad_meses >= 60 THEN 10   -- 5+ años
    WHEN f.antiguedad_meses >= 36 THEN 8    -- 3-5 años
    WHEN f.antiguedad_meses >= 24 THEN 6    -- 2-3 años
    WHEN f.antiguedad_meses >= 12 THEN 4    -- 1-2 años
    WHEN f.antiguedad_meses >= 6  THEN 2    -- 6-12 meses
    ELSE 0
  END;

  -- BLOQUE F: Estabilidad transaccional (máx 10 pts)
  --   Baja variabilidad = flujo predecible
  v_score := v_score + CASE
    WHEN f.variabilidad_saldo <= 0.1  THEN 10  -- Muy estable
    WHEN f.variabilidad_saldo <= 0.25 THEN 8   -- Estable
    WHEN f.variabilidad_saldo <= 0.5  THEN 5   -- Moderada
    WHEN f.variabilidad_saldo <= 0.8  THEN 2   -- Inestable
    ELSE 0
  END;

  -- Normalizar a escala 0-100
  -- Suma máx posible: 15+20+25+15+10+10 = 95 → normalizar
  v_score := ROUND(LEAST(v_score * 100.0 / 95.0, 100), 2);

  -- ══════════════════════════════════════════════════
  -- SEGMENTACIÓN Y RECOMENDACIÓN
  -- ══════════════════════════════════════════════════
  SELECT
    CASE
      WHEN v_score >= 85 THEN 'A'
      WHEN v_score >= 70 THEN 'B'
      WHEN v_score >= 50 THEN 'C'
      WHEN v_score >= 30 THEN 'D'
      ELSE 'E'
    END,
    CASE
      WHEN v_score >= 85 THEN 'pre_aprobado_inmediato'
      WHEN v_score >= 70 THEN 'aprobacion_rapida'
      WHEN v_score >= 50 THEN 'evaluar_con_garantias'
      WHEN v_score >= 30 THEN 'requiere_comite'
      ELSE 'rechazar'
    END,
    -- Monto máximo sugerido basado en capacidad de pago y score
    CASE
      WHEN v_score >= 85 THEN ROUND(f.capacidad_pago * 12 * 0.7, 0)
      WHEN v_score >= 70 THEN ROUND(f.capacidad_pago * 12 * 0.5, 0)
      WHEN v_score >= 50 THEN ROUND(f.capacidad_pago * 12 * 0.3, 0)
      ELSE 0
    END
  INTO v_segmento, v_recomendacion, v_monto_max;

  -- Guardar score
  INSERT INTO public.scores_transaccionales (
    user_id, score, segmento, recomendacion, monto_max_sugerido,
    modelo_version, calculado_at
  )
  VALUES (
    p_user_id, v_score, v_segmento, v_recomendacion, v_monto_max,
    'v1.0_reglas_fieldiq', NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    score              = EXCLUDED.score,
    segmento           = EXCLUDED.segmento,
    recomendacion      = EXCLUDED.recomendacion,
    monto_max_sugerido = EXCLUDED.monto_max_sugerido,
    modelo_version     = EXCLUDED.modelo_version,
    calculado_at       = NOW();

  -- Actualizar puntaje en perfil del cliente
  UPDATE public.perfiles_clientes
     SET puntaje_crediticio = v_score,
         updated_at = NOW()
   WHERE user_id = p_user_id;

  RAISE NOTICE 'Score calculado: % (Segmento %) para user_id: %',
    v_score, v_segmento, p_user_id;

  RETURN v_score;
END;
$$;

-- ════════════════════════════════════════════════════════════
-- FUNCIÓN 3: evaluar_credito_campo(asesor_id, ficha_id, monto)
-- Función que llama la app móvil al completar una ficha
-- Devuelve JSON con score + decisión + cuota estimada
-- ════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.evaluar_credito_campo(
  p_ficha_id     UUID,
  p_monto        NUMERIC(12,2),
  p_plazo_meses  INT DEFAULT 12
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  v_cliente_id  UUID;
  v_score       NUMERIC(5,2);
  v_segmento    TEXT;
  v_recomend    TEXT;
  v_monto_max   NUMERIC(12,2);
  v_tem         NUMERIC(6,4) := 1.8;  -- TEM base: 1.8%
  v_cuota       NUMERIC(10,2);
  v_resultado   JSONB;
BEGIN
  -- Obtener cliente de la ficha
  SELECT cliente_user_id INTO v_cliente_id
    FROM public.fichas_campo
   WHERE id = p_ficha_id;

  IF v_cliente_id IS NULL THEN
    RETURN jsonb_build_object(
      'exito', FALSE,
      'mensaje', 'La ficha no tiene cliente asociado. Registre primero el prospecto.',
      'codigo', 'SIN_CLIENTE'
    );
  END IF;

  -- Calcular score
  v_score := public.calcular_score_transaccional(v_cliente_id);

  -- Leer resultado
  SELECT segmento, recomendacion, monto_max_sugerido
    INTO v_segmento, v_recomend, v_monto_max
    FROM public.scores_transaccionales
   WHERE user_id = v_cliente_id;

  -- Calcular cuota con sistema francés
  -- C = M * [i*(1+i)^n / ((1+i)^n - 1)]
  v_cuota := ROUND(
    p_monto
    * ((v_tem/100) * POWER(1 + v_tem/100, p_plazo_meses))
    / (POWER(1 + v_tem/100, p_plazo_meses) - 1)
  , 2);

  -- Registrar pre-aprobación si el score lo permite
  IF v_score >= 50 AND p_monto <= v_monto_max THEN
    INSERT INTO public.creditos_preaprobados (
      ficha_id, cliente_user_id, asesor_id,
      monto_preaprobado, plazo_meses, tasa_mensual,
      score_aprobacion, estado, vigente_hasta
    )
    SELECT
      p_ficha_id,
      v_cliente_id,
      asesor_id,
      p_monto,
      p_plazo_meses,
      v_tem,
      v_score,
      CASE WHEN v_score >= 85 THEN 'pre-aprobado'
           ELSE 'en_comite' END,
      CURRENT_DATE + INTERVAL '30 days'
    FROM public.fichas_campo WHERE id = p_ficha_id
    ON CONFLICT DO NOTHING;

    -- Actualizar estado de la ficha
    UPDATE public.fichas_campo
       SET estado_ficha = 'completada',
           score_obtenido = v_score,
           monto_solicitado = p_monto
     WHERE id = p_ficha_id;
  END IF;

  -- Construir respuesta JSON para la app móvil
  v_resultado := jsonb_build_object(
    'exito',       TRUE,
    'score',       v_score,
    'segmento',    v_segmento,
    'decision',    v_recomend,
    'monto_solicitado', p_monto,
    'monto_max_aprobable', v_monto_max,
    'cuota_mensual', v_cuota,
    'plazo_meses', p_plazo_meses,
    'tem_aplicada', v_tem,
    'aprobacion_inmediata', (v_score >= 85 AND p_monto <= v_monto_max),
    'mensaje', CASE
      WHEN v_score >= 85 AND p_monto <= v_monto_max
        THEN 'APROBADO: El crédito puede desembolsarse hoy. Cliente ya fue notificado.'
      WHEN v_score >= 70
        THEN 'EN REVISIÓN: Pasa a aprobación rápida (mismo día).'
      WHEN v_score >= 50
        THEN 'PENDIENTE: Requiere evaluación con garantías adicionales.'
      ELSE
        'NO VIABLE: Score insuficiente. Sugiera mejora de perfil.'
    END
  );

  RETURN v_resultado;
END;
$$;

-- ════════════════════════════════════════════════════════════
-- VISTAS OPERATIVAS
-- ════════════════════════════════════════════════════════════

-- Vista: Resumen diario del asesor (lo que ve en la app al abrir)
CREATE OR REPLACE VIEW public.vw_agenda_asesor AS
SELECT
  um_asesor.id           AS asesor_id,
  um_asesor.nombre || ' ' || um_asesor.apellido AS asesor,
  fc.id                  AS ficha_id,
  fc.tipo_visita,
  fc.negocio_nombre,
  fc.distrito,
  COALESCE(pc.nombres || ' ' || pc.apellidos, fc.prospecto_nombre) AS cliente,
  fc.monto_solicitado,
  fc.score_obtenido,
  st.segmento,
  fc.estado_ficha,
  fc.creada_offline,
  fc.created_at::DATE    AS fecha_visita
FROM public.fichas_campo fc
JOIN public.usuarios_mock um_asesor ON um_asesor.id = fc.asesor_id
LEFT JOIN public.usuarios_mock um_cliente ON um_cliente.id = fc.cliente_user_id
LEFT JOIN public.perfiles_clientes pc ON pc.user_id = fc.cliente_user_id
LEFT JOIN public.scores_transaccionales st ON st.user_id = fc.cliente_user_id;

-- Vista: Embudo de colocación (KPI principal del supervisor)
CREATE OR REPLACE VIEW public.vw_embudo_colocacion AS
SELECT
  um.nombre || ' ' || um.apellido AS asesor,
  COUNT(fc.id)                    AS fichas_total,
  COUNT(fc.id) FILTER (WHERE fc.estado_ficha = 'completada')  AS completadas,
  COUNT(fc.id) FILTER (WHERE fc.estado_ficha = 'sincronizada') AS sincronizadas,
  COUNT(cp.id)                                                  AS pre_aprobados,
  COUNT(cp.id) FILTER (WHERE cp.estado = 'aprobado')           AS aprobados,
  COUNT(cp.id) FILTER (WHERE cp.estado = 'desembolsado')       AS desembolsados,
  COALESCE(SUM(cp.monto_preaprobado) FILTER (
    WHERE cp.estado = 'desembolsado'), 0)                       AS monto_desembolsado
FROM public.usuarios_mock um
LEFT JOIN public.fichas_campo fc      ON fc.asesor_id = um.id
LEFT JOIN public.creditos_preaprobados cp ON cp.asesor_id = um.id
WHERE um.rol = 'asesor'
GROUP BY um.id, um.nombre, um.apellido;

-- Vista: Clientes preaprobados para renovación (carga matutina de la app)
CREATE OR REPLACE VIEW public.vw_renovaciones_pendientes AS
SELECT
  pc.nombres || ' ' || pc.apellidos  AS cliente,
  pc.tipo_negocio,
  pc.zona_negocio,
  st.score,
  st.segmento,
  st.monto_max_sugerido,
  st.recomendacion,
  cp.estado                          AS estado_credito,
  cp.vigente_hasta,
  um_asesor.nombre || ' ' || um_asesor.apellido AS asesor_asignado
FROM public.creditos_preaprobados cp
JOIN public.perfiles_clientes pc    ON pc.user_id = cp.cliente_user_id
JOIN public.scores_transaccionales st ON st.user_id = cp.cliente_user_id
JOIN public.usuarios_mock um_asesor ON um_asesor.id = cp.asesor_id
WHERE cp.estado IN ('pre-aprobado','en_comite')
  AND cp.vigente_hasta >= CURRENT_DATE
ORDER BY st.score DESC;

-- ── Verificación final ────────────────────────────────────
SELECT
  'TABLAS' AS tipo,
  table_name AS nombre
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'perfiles_clientes','movimientos_mensuales',
    'features_scoring','scores_transaccionales',
    'fichas_campo','creditos_preaprobados'
  )
UNION ALL
SELECT
  'VISTAS', table_name
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name IN (
    'vw_agenda_asesor','vw_embudo_colocacion','vw_renovaciones_pendientes'
  )
UNION ALL
SELECT
  'FUNCIONES', routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'calcular_features_scoring',
    'calcular_score_transaccional',
    'evaluar_credito_campo'
  )
ORDER BY tipo, nombre;

-- ============================================================
-- FIN — 01_scoring_tablas_funciones_local.sql · v1.0
-- Siguiente: ejecutar 02_agencias_asesores_local.sql
-- ============================================================
```

## 02 - Agencias y asesores

Origen: `/Users/cc/Downloads/02_agencias_asesores_local.sql`

```sql
-- ============================================================
-- SCRIPT 02 — Agencias y Asesores (LOCAL)
-- App Móvil Fuerza de Ventas · v1.0
-- ============================================================
-- EJECUTAR: 3ro de 5  (después de 01_scoring_tablas_funciones_local.sql)
-- TIEMPO ESTIMADO: < 3 segundos
-- DONDE: pgAdmin 4 → Query Tool sobre DB: bd_appmovil_fventas
-- ============================================================
-- QUÉ CREA:
--   agencias         → sucursales y puntos de atención
--   asesores_negocio → asesores con referencia a usuarios_mock
--   metas_asesores   → metas mensuales por asesor
--   rutas_planificadas → rutas de visita del día
-- ============================================================
-- CORRECCIÓN vs versión Supabase:
--   asesores_negocio ahora referencia usuarios_mock(id)
--   mediante columna user_id → los asesores SÍ pueden hacer login
-- ============================================================

-- ── Limpieza segura ───────────────────────────────────────
DROP TABLE IF EXISTS public.rutas_planificadas CASCADE;
DROP TABLE IF EXISTS public.metas_asesores     CASCADE;
DROP TABLE IF EXISTS public.asesores_negocio   CASCADE;
DROP TABLE IF EXISTS public.agencias           CASCADE;

-- ── 1. agencias ───────────────────────────────────────────
CREATE TABLE public.agencias (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo            TEXT        NOT NULL UNIQUE,  -- ej: 'HYO-01'
  nombre            TEXT        NOT NULL,
  tipo              TEXT        NOT NULL DEFAULT 'agencia'
                                CHECK (tipo IN ('agencia','oficina_especial','ventanilla')),

  -- Ubicación
  departamento      TEXT        NOT NULL DEFAULT 'Junín',
  provincia         TEXT        NOT NULL DEFAULT 'Huancayo',
  distrito          TEXT        NOT NULL,
  direccion         TEXT,
  latitud           NUMERIC(10,7),
  longitud          NUMERIC(10,7),

  -- Operación
  activa            BOOLEAN     NOT NULL DEFAULT TRUE,
  gerente_nombre    TEXT,
  telefono          TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.agencias IS
  'Red de agencias y puntos de atención de la institución.
   Referencia para asignar asesores a una zona geográfica.';

-- ── 2. asesores_negocio ───────────────────────────────────
CREATE TABLE public.asesores_negocio (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Vinculación al sistema de login
  user_id           UUID        NOT NULL REFERENCES public.usuarios_mock(id) ON DELETE CASCADE,
  agencia_id        UUID        NOT NULL REFERENCES public.agencias(id),

  -- Datos del asesor
  codigo_asesor     TEXT        NOT NULL UNIQUE,  -- ej: 'ASE-042'
  especialidad      TEXT        DEFAULT 'microempresa'
                                CHECK (especialidad IN (
                                  'microempresa','pequena_empresa',
                                  'agropecuario','consumo','hipotecario'
                                )),
  zona_asignada     TEXT,       -- descripción de su zona (barrios, distritos)
  activo            BOOLEAN     NOT NULL DEFAULT TRUE,

  -- Metas vigentes (se actualizan mensualmente)
  meta_visitas_mes  INTEGER     DEFAULT 80,
  meta_creditos_mes INTEGER     DEFAULT 25,
  meta_monto_mes    NUMERIC(12,2) DEFAULT 150000,

  -- Métricas acumuladas (se actualizan con triggers o jobs)
  visitas_mes_actual   INTEGER  DEFAULT 0,
  creditos_mes_actual  INTEGER  DEFAULT 0,
  monto_mes_actual     NUMERIC(12,2) DEFAULT 0,

  created_at        TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT uq_asesores_user UNIQUE (user_id)
);

COMMENT ON TABLE public.asesores_negocio IS
  'Perfil del asesor de negocios (oficial de crédito).
   user_id vincula con usuarios_mock para autenticación en la app.
   Un asesor puede tener rol "asesor" o "admin" en usuarios_mock.';

-- ── 3. metas_asesores ────────────────────────────────────
-- Histórico de metas por asesor y mes
CREATE TABLE public.metas_asesores (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  asesor_id       UUID        NOT NULL REFERENCES public.asesores_negocio(id),
  periodo         TEXT        NOT NULL,  -- 'YYYY-MM'

  -- Metas planificadas
  meta_visitas    INTEGER     DEFAULT 80,
  meta_creditos   INTEGER     DEFAULT 25,
  meta_monto      NUMERIC(12,2) DEFAULT 150000,

  -- Logros reales
  real_visitas    INTEGER     DEFAULT 0,
  real_creditos   INTEGER     DEFAULT 0,
  real_monto      NUMERIC(12,2) DEFAULT 0,

  -- KPIs calculados
  pct_visitas     NUMERIC(5,2) GENERATED ALWAYS AS (
    CASE WHEN meta_visitas = 0 THEN 0
         ELSE ROUND(real_visitas * 100.0 / meta_visitas, 2)
    END
  ) STORED,
  pct_creditos    NUMERIC(5,2) GENERATED ALWAYS AS (
    CASE WHEN meta_creditos = 0 THEN 0
         ELSE ROUND(real_creditos * 100.0 / meta_creditos, 2)
    END
  ) STORED,
  pct_monto       NUMERIC(5,2) GENERATED ALWAYS AS (
    CASE WHEN meta_monto = 0 THEN 0
         ELSE ROUND(real_monto * 100.0 / meta_monto, 2)
    END
  ) STORED,

  created_at      TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT uq_metas_asesor_periodo UNIQUE (asesor_id, periodo)
);

-- ── 4. rutas_planificadas ────────────────────────────────
-- Planificación diaria de visitas (vista en la app al iniciar el día)
CREATE TABLE public.rutas_planificadas (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  asesor_id        UUID        NOT NULL REFERENCES public.asesores_negocio(id),
  fecha_ruta       DATE        NOT NULL DEFAULT CURRENT_DATE,

  -- Cliente a visitar
  cliente_user_id  UUID        REFERENCES public.usuarios_mock(id),
  prospecto_nombre TEXT,        -- si es nuevo prospecto
  prospecto_dir    TEXT,

  -- Geolocalización del cliente
  latitud_cliente  NUMERIC(10,7),
  longitud_cliente NUMERIC(10,7),
  referencia_dir   TEXT,

  -- Tipo de visita planificada
  tipo_visita      TEXT        NOT NULL DEFAULT 'renovacion'
                               CHECK (tipo_visita IN (
                                 'renovacion','prospeccion',
                                 'seguimiento','cobranza'
                               )),
  monto_estimado   NUMERIC(12,2) DEFAULT 0,
  hora_sugerida    TIME,

  -- Estado
  estado           TEXT        NOT NULL DEFAULT 'pendiente'
                               CHECK (estado IN (
                                 'pendiente','en_ruta',
                                 'visitado','reagendar','cancelado'
                               )),
  ficha_generada_id UUID       REFERENCES public.fichas_campo(id),

  -- Carga automática (referencia al video: "carga diaria automática")
  cargado_automatico BOOLEAN   DEFAULT TRUE,
  cargado_at         TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.rutas_planificadas IS
  'Lista de clientes para visitar cada día.
   Equivale a la "lista de clientes para renovación" que el asesor
   revisa al encender la tablet (según workflow del video de referencia).
   Se pobla automáticamente desde vw_renovaciones_pendientes cada mañana.';

-- ── Índices ───────────────────────────────────────────────
CREATE INDEX idx_asesores_agencia   ON public.asesores_negocio(agencia_id);
CREATE INDEX idx_asesores_user      ON public.asesores_negocio(user_id);
CREATE INDEX idx_metas_asesor       ON public.metas_asesores(asesor_id, periodo);
CREATE INDEX idx_rutas_asesor_fecha ON public.rutas_planificadas(asesor_id, fecha_ruta);
CREATE INDEX idx_rutas_estado       ON public.rutas_planificadas(estado);

-- ── Vista: Dashboard del asesor ───────────────────────────
CREATE OR REPLACE VIEW public.vw_dashboard_asesor AS
SELECT
  an.id              AS asesor_id,
  an.codigo_asesor,
  um.nombre || ' ' || um.apellido  AS asesor_nombre,
  ag.nombre          AS agencia,
  an.especialidad,
  an.zona_asignada,

  -- Metas del mes
  an.meta_visitas_mes,
  an.meta_creditos_mes,
  an.meta_monto_mes,

  -- Avance del mes
  an.visitas_mes_actual,
  an.creditos_mes_actual,
  an.monto_mes_actual,

  -- % cumplimiento
  ROUND(an.visitas_mes_actual * 100.0 / NULLIF(an.meta_visitas_mes, 0), 1)
    AS pct_visitas,
  ROUND(an.creditos_mes_actual * 100.0 / NULLIF(an.meta_creditos_mes, 0), 1)
    AS pct_creditos,
  ROUND(an.monto_mes_actual * 100.0 / NULLIF(an.meta_monto_mes, 0), 1)
    AS pct_monto,

  -- Ruta de hoy
  (SELECT COUNT(*) FROM public.rutas_planificadas rp
   WHERE rp.asesor_id = an.id AND rp.fecha_ruta = CURRENT_DATE)
    AS visitas_hoy_total,
  (SELECT COUNT(*) FROM public.rutas_planificadas rp
   WHERE rp.asesor_id = an.id AND rp.fecha_ruta = CURRENT_DATE
     AND rp.estado = 'visitado')
    AS visitas_hoy_completadas,
  (SELECT COUNT(*) FROM public.rutas_planificadas rp
   WHERE rp.asesor_id = an.id AND rp.fecha_ruta = CURRENT_DATE
     AND rp.estado = 'pendiente')
    AS visitas_hoy_pendientes

FROM public.asesores_negocio an
JOIN public.usuarios_mock um ON um.id = an.user_id
JOIN public.agencias ag      ON ag.id = an.agencia_id
WHERE an.activo = TRUE;

-- ── Verificación ──────────────────────────────────────────
SELECT table_name, 'OK' AS estado
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'agencias','asesores_negocio',
    'metas_asesores','rutas_planificadas'
  )
ORDER BY table_name;

-- ============================================================
-- FIN — 02_agencias_asesores_local.sql · v1.0
-- Siguiente: ejecutar 03_seed_demo_local.sql
-- ============================================================
```

## 03 - Seed demo

Origen: `/Users/cc/Downloads/03_seed_demo_local.sql`

```sql
-- ============================================================
-- SCRIPT 03 — Seed Demo: Datos de Prueba (LOCAL)
-- App Móvil Fuerza de Ventas · v1.0
-- ============================================================
-- EJECUTAR: 4to de 5  (después de 02_agencias_asesores_local.sql)
-- TIEMPO ESTIMADO: < 10 segundos
-- DONDE: pgAdmin 4 → Query Tool sobre DB: bd_appmovil_fventas
-- ============================================================
-- QUÉ INSERTA:
--   5 agencias en Junín/Huancayo
--   4 asesores de negocio  (rol 'asesor' en usuarios_mock)
--   1 admin
--   20 clientes reales con perfil socioeconómico andino
--   Historial de movimientos (6 meses por cliente)
--   Fichas de campo (10 visitas demo)
-- ============================================================

-- ── Limpieza en orden correcto (FK) ──────────────────────
TRUNCATE TABLE public.rutas_planificadas     RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.metas_asesores         RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.creditos_preaprobados  RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.fichas_campo           RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.scores_transaccionales RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.features_scoring       RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.movimientos_mensuales  RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.perfiles_clientes      RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.asesores_negocio       RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.agencias               RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.solicitudes_prestamo   RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.cuentas_ahorro         RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.pagos                  RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.transacciones          RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.cuentas               RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.usuarios_mock          RESTART IDENTITY CASCADE;

-- ════════════════════════════════════════════════════════════
-- 1. AGENCIAS — Red en Junín
-- ════════════════════════════════════════════════════════════
INSERT INTO public.agencias
  (id, codigo, nombre, tipo, departamento, provincia, distrito, direccion, latitud, longitud)
VALUES
  ('aaaaaaaa-0001-0001-0001-000000000001',
   'HYO-01','Agencia Huancayo Principal','agencia',
   'Junín','Huancayo','Huancayo',
   'Jr. Ancash 745, Huancayo', -12.0653, -75.2049),

  ('aaaaaaaa-0001-0001-0001-000000000002',
   'HYO-02','Agencia El Tambo','agencia',
   'Junín','Huancayo','El Tambo',
   'Av. Ferrocarril 1250, El Tambo', -12.0445, -75.2112),

  ('aaaaaaaa-0001-0001-0001-000000000003',
   'HYO-03','Agencia Chilca','agencia',
   'Junín','Huancayo','Chilca',
   'Jr. Lima 320, Chilca', -12.0820, -75.2120),

  ('aaaaaaaa-0001-0001-0001-000000000004',
   'HYO-04','Agencia Chupaca','oficina_especial',
   'Junín','Chupaca','Chupaca',
   'Jr. Grau 180, Chupaca', -12.0580, -75.2860),

  ('aaaaaaaa-0001-0001-0001-000000000005',
   'HYO-05','Ventanilla Concepción','ventanilla',
   'Junín','Concepción','Concepción',
   'Jr. 9 de Julio 410, Concepción', -11.9153, -75.3142);

-- ════════════════════════════════════════════════════════════
-- 2. USUARIOS — Asesores, Admin y Clientes
-- ════════════════════════════════════════════════════════════

-- ── Asesores (4) y Admin (1) ──────────────────────────────
INSERT INTO public.usuarios_mock
  (id, email, nombre, apellido, rol)
VALUES
  -- Admin
  ('bbbbbbbb-0001-0001-0001-000000000001',
   'admin@fieldiq.pe', 'Carlos', 'Mendoza','admin'),

  -- Asesores
  ('bbbbbbbb-0001-0001-0001-000000000002',
   'jessica.quispe@fieldiq.pe', 'Jessica', 'Quispe Huanca', 'asesor'),

  ('bbbbbbbb-0001-0001-0001-000000000003',
   'mario.ccanto@fieldiq.pe', 'Mario', 'Ccanto Paucar', 'asesor'),

  ('bbbbbbbb-0001-0001-0001-000000000004',
   'lucia.palomino@fieldiq.pe', 'Lucía', 'Palomino Ríos', 'asesor'),

  ('bbbbbbbb-0001-0001-0001-000000000005',
   'david.asto@fieldiq.pe', 'David', 'Asto Huamán', 'asesor');

-- ── Clientes (20) — Perfiles andinos realistas ────────────
INSERT INTO public.usuarios_mock
  (id, email, nombre, apellido, rol)
VALUES
  ('cccccccc-0001-0001-0001-000000000001',
   'rosa.condori@gmail.com',    'Rosa',     'Condori Mamani',  'cliente'),
  ('cccccccc-0001-0001-0001-000000000002',
   'juan.huanca@gmail.com',     'Juan',     'Huanca Quispe',   'cliente'),
  ('cccccccc-0001-0001-0001-000000000003',
   'maria.paucar@gmail.com',    'María',    'Paucar Flores',   'cliente'),
  ('cccccccc-0001-0001-0001-000000000004',
   'pedro.asto@gmail.com',      'Pedro',    'Asto Ccanto',     'cliente'),
  ('cccccccc-0001-0001-0001-000000000005',
   'luz.ccari@gmail.com',       'Luz',      'Ccari Huamán',    'cliente'),
  ('cccccccc-0001-0001-0001-000000000006',
   'efrain.ramos@gmail.com',    'Efraín',   'Ramos Taipe',     'cliente'),
  ('cccccccc-0001-0001-0001-000000000007',
   'flora.ayala@gmail.com',     'Flora',    'Ayala Lazo',      'cliente'),
  ('cccccccc-0001-0001-0001-000000000008',
   'clemente.yali@gmail.com',   'Clemente', 'Yali Quispe',     'cliente'),
  ('cccccccc-0001-0001-0001-000000000009',
   'elvira.sulca@gmail.com',    'Elvira',   'Sulca Condezo',   'cliente'),
  ('cccccccc-0001-0001-0001-000000000010',
   'wilmer.ore@gmail.com',      'Wilmer',   'Ore Cuadros',     'cliente'),
  ('cccccccc-0001-0001-0001-000000000011',
   'nelly.zuñiga@gmail.com',    'Nelly',    'Zuñiga Pozo',     'cliente'),
  ('cccccccc-0001-0001-0001-000000000012',
   'santos.meza@gmail.com',     'Santos',   'Meza Palian',     'cliente'),
  ('cccccccc-0001-0001-0001-000000000013',
   'olinda.taipe@gmail.com',    'Olinda',   'Taipe Cóndor',    'cliente'),
  ('cccccccc-0001-0001-0001-000000000014',
   'teofilo.ccente@gmail.com',  'Teófilo',  'Ccente Huayta',   'cliente'),
  ('cccccccc-0001-0001-0001-000000000015',
   'maxima.rojas@gmail.com',    'Máxima',   'Rojas Tello',     'cliente'),
  ('cccccccc-0001-0001-0001-000000000016',
   'victor.huari@gmail.com',    'Víctor',   'Huari Limaylla',  'cliente'),
  ('cccccccc-0001-0001-0001-000000000017',
   'gladys.pumacayo@gmail.com', 'Gladys',   'Pumacayo Soto',   'cliente'),
  ('cccccccc-0001-0001-0001-000000000018',
   'cirilo.chávez@gmail.com',   'Cirilo',   'Chávez Pariona',  'cliente'),
  ('cccccccc-0001-0001-0001-000000000019',
   'hermelinda.llanos@gmail.com','Hermelinda','Llanos Matos',  'cliente'),
  ('cccccccc-0001-0001-0001-000000000020',
   'agustin.salcedo@gmail.com', 'Agustín',  'Salcedo Hinostroza','cliente');

-- ════════════════════════════════════════════════════════════
-- 3. ASESORES DE NEGOCIO
-- ════════════════════════════════════════════════════════════
INSERT INTO public.asesores_negocio
  (id, user_id, agencia_id, codigo_asesor, especialidad,
   zona_asignada, meta_visitas_mes, meta_creditos_mes, meta_monto_mes)
VALUES
  ('dddddddd-0001-0001-0001-000000000001',
   'bbbbbbbb-0001-0001-0001-000000000002',
   'aaaaaaaa-0001-0001-0001-000000000001',
   'ASE-001', 'microempresa',
   'Huancayo centro, Cercado, San Carlos',
   80, 25, 180000),

  ('dddddddd-0001-0001-0001-000000000002',
   'bbbbbbbb-0001-0001-0001-000000000003',
   'aaaaaaaa-0001-0001-0001-000000000002',
   'ASE-002', 'microempresa',
   'El Tambo, Huancán, Pilcomayo',
   80, 25, 180000),

  ('dddddddd-0001-0001-0001-000000000003',
   'bbbbbbbb-0001-0001-0001-000000000004',
   'aaaaaaaa-0001-0001-0001-000000000003',
   'ASE-003', 'agropecuario',
   'Chilca, Sicaya, Orcotuna',
   60, 18, 120000),

  ('dddddddd-0001-0001-0001-000000000004',
   'bbbbbbbb-0001-0001-0001-000000000005',
   'aaaaaaaa-0001-0001-0001-000000000004',
   'ASE-004', 'agropecuario',
   'Chupaca, Ahuac, Chongos Bajo',
   60, 18, 100000);

-- ════════════════════════════════════════════════════════════
-- 4. PERFILES DE CLIENTES (datos socioeconómicos de campo)
-- Variedad de tipos de negocio y zonas andinas
-- ════════════════════════════════════════════════════════════
INSERT INTO public.perfiles_clientes
  (user_id, nombres, apellidos, tipo_negocio, antiguedad_negocio,
   local_propio, zona_negocio, ingreso_mensual_est,
   gasto_mensual_est, deuda_actual, entidades_deuda, estado_cliente)
VALUES
  -- Clientes buenos (Segmento A-B)
  ('cccccccc-0001-0001-0001-000000000001',
   'Rosa','Condori Mamani','bodega',48,TRUE,'urbano',3500,1800,5000,1,'activo'),

  ('cccccccc-0001-0001-0001-000000000002',
   'Juan','Huanca Quispe','ferreteria',72,TRUE,'urbano',7200,3500,15000,2,'activo'),

  ('cccccccc-0001-0001-0001-000000000003',
   'María','Paucar Flores','restaurante',36,TRUE,'urbano',4800,2500,8000,1,'activo'),

  ('cccccccc-0001-0001-0001-000000000004',
   'Pedro','Asto Ccanto','transporte',60,FALSE,'periurbano',5500,2800,12000,2,'activo'),

  ('cccccccc-0001-0001-0001-000000000005',
   'Luz','Ccari Huamán','confecciones',30,TRUE,'urbano',3200,1600,4000,1,'activo'),

  -- Clientes medios (Segmento B-C)
  ('cccccccc-0001-0001-0001-000000000006',
   'Efraín','Ramos Taipe','agro',84,TRUE,'rural',4500,2200,20000,3,'activo'),

  ('cccccccc-0001-0001-0001-000000000007',
   'Flora','Ayala Lazo','bodega',24,FALSE,'periurbano',2800,1700,6000,2,'activo'),

  ('cccccccc-0001-0001-0001-000000000008',
   'Clemente','Yali Quispe','agro',96,TRUE,'rural',6000,3000,18000,2,'activo'),

  ('cccccccc-0001-0001-0001-000000000009',
   'Elvira','Sulca Condezo','comercio',18,FALSE,'periurbano',2500,1500,5000,2,'activo'),

  ('cccccccc-0001-0001-0001-000000000010',
   'Wilmer','Ore Cuadros','taller',42,TRUE,'periurbano',4200,2100,10000,1,'activo'),

  -- Clientes con riesgo (Segmento C-D)
  ('cccccccc-0001-0001-0001-000000000011',
   'Nelly','Zuñiga Pozo','bodega',12,FALSE,'periurbano',1900,1400,8000,3,'activo'),

  ('cccccccc-0001-0001-0001-000000000012',
   'Santos','Meza Palian','agro',24,FALSE,'rural',3000,2000,15000,4,'activo'),

  ('cccccccc-0001-0001-0001-000000000013',
   'Olinda','Taipe Cóndor','comercio',8,FALSE,'rural',2200,1800,10000,3,'prospecto'),

  ('cccccccc-0001-0001-0001-000000000014',
   'Teófilo','Ccente Huayta','taller',15,FALSE,'periurbano',2600,2000,12000,3,'activo'),

  ('cccccccc-0001-0001-0001-000000000015',
   'Máxima','Rojas Tello','confecciones',6,FALSE,'rural',1800,1400,5000,2,'prospecto'),

  -- Prospectos nuevos (sin historial)
  ('cccccccc-0001-0001-0001-000000000016',
   'Víctor','Huari Limaylla','ferreteria',36,TRUE,'urbano',5800,2800,0,0,'prospecto'),

  ('cccccccc-0001-0001-0001-000000000017',
   'Gladys','Pumacayo Soto','restaurante',24,TRUE,'urbano',4200,2100,0,0,'prospecto'),

  ('cccccccc-0001-0001-0001-000000000018',
   'Cirilo','Chávez Pariona','agro',48,TRUE,'rural',3800,1900,0,0,'prospecto'),

  ('cccccccc-0001-0001-0001-000000000019',
   'Hermelinda','Llanos Matos','bodega',30,FALSE,'periurbano',2900,1700,0,0,'prospecto'),

  ('cccccccc-0001-0001-0001-000000000020',
   'Agustín','Salcedo Hinostroza','transporte',60,TRUE,'periurbano',6500,3200,8000,1,'activo');

-- ════════════════════════════════════════════════════════════
-- 5. MOVIMIENTOS MENSUALES — 6 meses para clientes activos
-- ════════════════════════════════════════════════════════════

-- Macro: insertar movimientos para un cliente dado su patron
-- Clientes 1-10: buen historial  | Clientes 11-15: historial irregular

-- Cliente 1 — Rosa Condori (bodega, buena pagadora)
INSERT INTO public.movimientos_mensuales
  (user_id, periodo, total_creditos, total_debitos,
   saldo_promedio, num_transacciones, num_pagos_puntual, num_pagos_tardio)
SELECT
  'cccccccc-0001-0001-0001-000000000001',
  TO_CHAR(NOW() - (n || ' months')::INTERVAL, 'YYYY-MM'),
  3500 + (random()*500)::INT,
  1800 + (random()*300)::INT,
  1200 + (random()*400)::INT,
  18 + (random()*6)::INT,
  3, 0
FROM generate_series(1,6) n;

-- Cliente 2 — Juan Huanca (ferretería, excelente)
INSERT INTO public.movimientos_mensuales
  (user_id, periodo, total_creditos, total_debitos,
   saldo_promedio, num_transacciones, num_pagos_puntual, num_pagos_tardio)
SELECT
  'cccccccc-0001-0001-0001-000000000002',
  TO_CHAR(NOW() - (n || ' months')::INTERVAL, 'YYYY-MM'),
  7000 + (random()*1000)::INT,
  3500 + (random()*500)::INT,
  3500 + (random()*800)::INT,
  28 + (random()*8)::INT,
  4, 0
FROM generate_series(1,6) n;

-- Cliente 3 — María Paucar (restaurante, buena)
INSERT INTO public.movimientos_mensuales
  (user_id, periodo, total_creditos, total_debitos,
   saldo_promedio, num_transacciones, num_pagos_puntual, num_pagos_tardio)
SELECT
  'cccccccc-0001-0001-0001-000000000003',
  TO_CHAR(NOW() - (n || ' months')::INTERVAL, 'YYYY-MM'),
  4800 + (random()*600)::INT,
  2500 + (random()*400)::INT,
  2100 + (random()*500)::INT,
  22 + (random()*6)::INT,
  3, 0
FROM generate_series(1,6) n;

-- Cliente 4 — Pedro Asto (transporte, bueno)
INSERT INTO public.movimientos_mensuales
  (user_id, periodo, total_creditos, total_debitos,
   saldo_promedio, num_transacciones, num_pagos_puntual, num_pagos_tardio)
SELECT
  'cccccccc-0001-0001-0001-000000000004',
  TO_CHAR(NOW() - (n || ' months')::INTERVAL, 'YYYY-MM'),
  5500 + (random()*800)::INT,
  2800 + (random()*400)::INT,
  2500 + (random()*600)::INT,
  20 + (random()*5)::INT,
  3, 1
FROM generate_series(1,6) n;

-- Cliente 5 — Luz Ccari (confecciones, buena)
INSERT INTO public.movimientos_mensuales
  (user_id, periodo, total_creditos, total_debitos,
   saldo_promedio, num_transacciones, num_pagos_puntual, num_pagos_tardio)
SELECT
  'cccccccc-0001-0001-0001-000000000005',
  TO_CHAR(NOW() - (n || ' months')::INTERVAL, 'YYYY-MM'),
  3200 + (random()*400)::INT,
  1600 + (random()*300)::INT,
  1400 + (random()*300)::INT,
  16 + (random()*4)::INT,
  3, 0
FROM generate_series(1,6) n;

-- Clientes 6-10: perfil medio
INSERT INTO public.movimientos_mensuales
  (user_id, periodo, total_creditos, total_debitos,
   saldo_promedio, num_transacciones, num_pagos_puntual, num_pagos_tardio)
SELECT uid::UUID,
  TO_CHAR(NOW() - (n || ' months')::INTERVAL, 'YYYY-MM'),
  cred + (random()*400)::INT,
  deb  + (random()*300)::INT,
  saldo + (random()*300)::INT,
  15 + (random()*5)::INT,
  punt, tard
FROM generate_series(1,6) n
CROSS JOIN (
  SELECT 'cccccccc-0001-0001-0001-000000000006'::TEXT AS uid, 4500 AS cred, 2200 AS deb, 1500 AS saldo, 2 AS punt, 1 AS tard
  UNION ALL SELECT 'cccccccc-0001-0001-0001-000000000007', 2800, 1700,  800, 2, 1
  UNION ALL SELECT 'cccccccc-0001-0001-0001-000000000008', 6000, 3000, 2000, 3, 1
  UNION ALL SELECT 'cccccccc-0001-0001-0001-000000000009', 2500, 1500,  700, 1, 2
  UNION ALL SELECT 'cccccccc-0001-0001-0001-000000000010', 4200, 2100, 1600, 2, 1
) AS u;

-- Clientes 11-15: historial irregular
INSERT INTO public.movimientos_mensuales
  (user_id, periodo, total_creditos, total_debitos,
   saldo_promedio, num_transacciones, num_pagos_puntual, num_pagos_tardio)
SELECT uid::UUID,
  TO_CHAR(NOW() - (n || ' months')::INTERVAL, 'YYYY-MM'),
  cred + (random()*300)::INT,
  deb  + (random()*400)::INT,  -- gasto > ingreso algunos meses
  saldo + (random()*200)::INT,
  10 + (random()*4)::INT,
  punt, tard
FROM generate_series(1,6) n
CROSS JOIN (
  SELECT 'cccccccc-0001-0001-0001-000000000011'::TEXT AS uid, 1900 AS cred, 1400 AS deb, 300 AS saldo, 1 AS punt, 2 AS tard
  UNION ALL SELECT 'cccccccc-0001-0001-0001-000000000012', 3000, 2000, 700, 1, 2
  UNION ALL SELECT 'cccccccc-0001-0001-0001-000000000013', 2200, 1800, 400, 0, 3
  UNION ALL SELECT 'cccccccc-0001-0001-0001-000000000014', 2600, 2000, 500, 1, 2
  UNION ALL SELECT 'cccccccc-0001-0001-0001-000000000015', 1800, 1400, 250, 0, 3
) AS u;

-- ════════════════════════════════════════════════════════════
-- 6. EJECUTAR SCORING para clientes 1-15
-- ════════════════════════════════════════════════════════════
DO $$
DECLARE
  v_uid UUID;
  v_score NUMERIC(5,2);
BEGIN
  FOR v_uid IN (
    SELECT id FROM public.usuarios_mock
    WHERE rol = 'cliente'
    AND id NOT IN (
      'cccccccc-0001-0001-0001-000000000016',
      'cccccccc-0001-0001-0001-000000000017',
      'cccccccc-0001-0001-0001-000000000018',
      'cccccccc-0001-0001-0001-000000000019'
    )
    ORDER BY email
  ) LOOP
    v_score := public.calcular_score_transaccional(v_uid);
    RAISE NOTICE 'Scoring ejecutado para %: score = %', v_uid, v_score;
  END LOOP;
END;
$$;

-- ════════════════════════════════════════════════════════════
-- 7. FICHAS DE CAMPO — 10 visitas demo
-- Simula el trabajo de los asesores en campo
-- ════════════════════════════════════════════════════════════
INSERT INTO public.fichas_campo
  (id, asesor_id, cliente_user_id,
   latitud, longitud, distrito, tipo_visita,
   negocio_nombre, negocio_rubro,
   ingreso_declarado, gasto_declarado,
   estado_ficha, monto_solicitado, observaciones, creada_offline)
VALUES
  ('eeeeeeee-0001-0001-0001-000000000001',
   'bbbbbbbb-0001-0001-0001-000000000002',
   'cccccccc-0001-0001-0001-000000000001',
   -12.0653, -75.2049, 'Huancayo', 'renovacion',
   'Bodega Rosita', 'bodega', 3500, 1800,
   'completada', 8000,
   'Cliente solicita ampliación para stock de campaña escolar', FALSE),

  ('eeeeeeee-0001-0001-0001-000000000002',
   'bbbbbbbb-0001-0001-0001-000000000002',
   'cccccccc-0001-0001-0001-000000000002',
   -12.0651, -75.2045, 'Huancayo', 'renovacion',
   'Ferretería Huanca', 'ferreteria', 7200, 3500,
   'completada', 25000,
   'Renovación con ampliación. Nuevo local en El Tambo.', FALSE),

  ('eeeeeeee-0001-0001-0001-000000000003',
   'bbbbbbbb-0001-0001-0001-000000000003',
   'cccccccc-0001-0001-0001-000000000004',
   -12.0445, -75.2112, 'El Tambo', 'seguimiento',
   'Transporte Asto', 'transporte', 5500, 2800,
   'completada', 15000,
   'Ampliación de flota. Cuota actual al día.', FALSE),

  ('eeeeeeee-0001-0001-0001-000000000004',
   'bbbbbbbb-0001-0001-0001-000000000003',
   'cccccccc-0001-0001-0001-000000000007',
   -12.0450, -75.2118, 'El Tambo', 'prospeccion',
   'Bodega Flora', 'bodega', 2800, 1700,
   'completada', 5000,
   'Primera visita. Muestra interés en crédito campaña navidad.', TRUE),

  ('eeeeeeee-0001-0001-0001-000000000005',
   'bbbbbbbb-0001-0001-0001-000000000004',
   'cccccccc-0001-0001-0001-000000000006',
   -12.0820, -75.2120, 'Chilca', 'renovacion',
   'Negocio Agropecuario Ramos', 'agro', 4500, 2200,
   'completada', 18000,
   'Campaña papa. Solicita para fertilizantes e insumos.', FALSE),

  ('eeeeeeee-0001-0001-0001-000000000006',
   'bbbbbbbb-0001-0001-0001-000000000005',
   'cccccccc-0001-0001-0001-000000000008',
   -12.0580, -75.2860, 'Chupaca', 'renovacion',
   'Granja Yali', 'agro', 6000, 3000,
   'completada', 22000,
   'Ampliación de crianza de cuyes. Mercado en Huancayo.', FALSE),

  -- Fichas offline (sin internet, sincronizadas luego)
  ('eeeeeeee-0001-0001-0001-000000000007',
   'bbbbbbbb-0001-0001-0001-000000000004',
   'cccccccc-0001-0001-0001-000000000018',
   -11.9153, -75.3142, 'Concepción', 'prospeccion',
   'Chacra Chávez', 'agro', 3800, 1900,
   'sincronizada', 12000,
   'Zona rural sin señal. Datos tomados offline, sync al regresar.', TRUE),

  ('eeeeeeee-0001-0001-0001-000000000008',
   'bbbbbbbb-0001-0001-0001-000000000005',
   'cccccccc-0001-0001-0001-000000000012',
   -12.0580, -75.2870, 'Chupaca', 'cobranza',
   'Parcela Meza', 'agro', 3000, 2000,
   'completada', 0,
   'Visita de cobranza. Acuerdo de pago en cuotas.', FALSE),

  -- Fichas de prospectos nuevos sin user_id (solo datos de campo)
  ('eeeeeeee-0001-0001-0001-000000000009',
   'bbbbbbbb-0001-0001-0001-000000000002',
   NULL,  -- Prospecto aún sin cuenta
   -12.0660, -75.2055, 'Huancayo', 'prospeccion',
   'Librería Central', 'comercio',
   4500, 2200, 'borrador', 10000,
   'Prospecto nuevo. DNI pendiente de verificar. Interesado en crédito comercio.', FALSE),

  ('eeeeeeee-0001-0001-0001-000000000010',
   'bbbbbbbb-0001-0001-0001-000000000003',
   'cccccccc-0001-0001-0001-000000000020',
   -12.0445, -75.2100, 'El Tambo', 'renovacion',
   'Transporte Salcedo', 'transporte', 6500, 3200,
   'completada', 20000,
   'Tercer crédito. Historial impecable. Ampliación de flota.', FALSE);

-- Actualizar campos de sincronización para fichas offline
UPDATE public.fichas_campo
   SET sincronizada_at = NOW() - INTERVAL '2 hours'
 WHERE creada_offline = TRUE
   AND estado_ficha = 'sincronizada';

-- ════════════════════════════════════════════════════════════
-- 8. RUTA PLANIFICADA — Lista del día de hoy (carga automática)
-- Simula lo que ve el asesor al encender la tablet
-- ════════════════════════════════════════════════════════════
INSERT INTO public.rutas_planificadas
  (asesor_id, fecha_ruta, cliente_user_id,
   latitud_cliente, longitud_cliente, referencia_dir,
   tipo_visita, monto_estimado, hora_sugerida,
   estado, cargado_automatico)
VALUES
  -- Ruta de Jessica (ASE-001) — hoy
  ('dddddddd-0001-0001-0001-000000000001',
   CURRENT_DATE,
   'cccccccc-0001-0001-0001-000000000001',
   -12.0653, -75.2049, 'Mercado Modelo, puesto 14 - Jr. Puno',
   'renovacion', 8000, '08:30', 'pendiente', TRUE),

  ('dddddddd-0001-0001-0001-000000000001',
   CURRENT_DATE,
   'cccccccc-0001-0001-0001-000000000003',
   -12.0658, -75.2052, 'Av. Huancavelica frente a bodega el sol',
   'renovacion', 12000, '10:00', 'pendiente', TRUE),

  ('dddddddd-0001-0001-0001-000000000001',
   CURRENT_DATE,
   'cccccccc-0001-0001-0001-000000000005',
   -12.0645, -75.2041, 'Jr. Loreto 240, tienda esquina',
   'seguimiento', 6000, '11:30', 'pendiente', TRUE),

  -- Ruta de Mario (ASE-002) — hoy
  ('dddddddd-0001-0001-0001-000000000002',
   CURRENT_DATE,
   'cccccccc-0001-0001-0001-000000000004',
   -12.0445, -75.2112, 'Terminal El Tambo, paradero 3',
   'renovacion', 15000, '08:00', 'visitado', TRUE),

  ('dddddddd-0001-0001-0001-000000000002',
   CURRENT_DATE,
   'cccccccc-0001-0001-0001-000000000010',
   -12.0450, -75.2108, 'Av. Ferrocarril 890, taller mecánico',
   'prospeccion', 9000, '10:00', 'pendiente', TRUE),

  -- Ruta de Lucía (ASE-003) — hoy
  ('dddddddd-0001-0001-0001-000000000003',
   CURRENT_DATE,
   'cccccccc-0001-0001-0001-000000000006',
   -12.0820, -75.2120, 'Comunidad Huayucachi — chacra entrada por puente',
   'renovacion', 18000, '07:30', 'visitado', TRUE),

  ('dddddddd-0001-0001-0001-000000000003',
   CURRENT_DATE,
   'cccccccc-0001-0001-0001-000000000008',
   -12.0580, -75.2860, 'Carretera Chupaca km 3.5 — granja cuyes',
   'renovacion', 22000, '09:30', 'pendiente', TRUE);

-- Marcar primera visita de Mario como ya visitada con ficha generada
UPDATE public.rutas_planificadas
   SET estado = 'visitado',
       ficha_generada_id = 'eeeeeeee-0001-0001-0001-000000000003'
 WHERE asesor_id = 'dddddddd-0001-0001-0001-000000000002'
   AND cliente_user_id = 'cccccccc-0001-0001-0001-000000000004';

-- ════════════════════════════════════════════════════════════
-- 9. METAS DEL MES — Período actual
-- ════════════════════════════════════════════════════════════
INSERT INTO public.metas_asesores
  (asesor_id, periodo,
   meta_visitas, meta_creditos, meta_monto,
   real_visitas, real_creditos, real_monto)
VALUES
  ('dddddddd-0001-0001-0001-000000000001',
   TO_CHAR(NOW(), 'YYYY-MM'), 80, 25, 180000, 52, 16, 112000),
  ('dddddddd-0001-0001-0001-000000000002',
   TO_CHAR(NOW(), 'YYYY-MM'), 80, 25, 180000, 61, 19, 148000),
  ('dddddddd-0001-0001-0001-000000000003',
   TO_CHAR(NOW(), 'YYYY-MM'), 60, 18, 120000, 44, 13, 88000),
  ('dddddddd-0001-0001-0001-000000000004',
   TO_CHAR(NOW(), 'YYYY-MM'), 60, 18, 100000, 38, 11, 72000);

-- Sincronizar métricas en tabla asesores_negocio
UPDATE public.asesores_negocio an
   SET visitas_mes_actual  = ma.real_visitas,
       creditos_mes_actual = ma.real_creditos,
       monto_mes_actual    = ma.real_monto
  FROM public.metas_asesores ma
 WHERE ma.asesor_id = an.id
   AND ma.periodo = TO_CHAR(NOW(), 'YYYY-MM');

-- ════════════════════════════════════════════════════════════
-- VERIFICACIÓN FINAL
-- ════════════════════════════════════════════════════════════
SELECT
  'usuarios_mock'         AS tabla, COUNT(*) AS registros FROM public.usuarios_mock
UNION ALL SELECT 'agencias',            COUNT(*) FROM public.agencias
UNION ALL SELECT 'asesores_negocio',    COUNT(*) FROM public.asesores_negocio
UNION ALL SELECT 'perfiles_clientes',   COUNT(*) FROM public.perfiles_clientes
UNION ALL SELECT 'movimientos_mensual', COUNT(*) FROM public.movimientos_mensuales
UNION ALL SELECT 'features_scoring',    COUNT(*) FROM public.features_scoring
UNION ALL SELECT 'scores_transacc.',    COUNT(*) FROM public.scores_transaccionales
UNION ALL SELECT 'fichas_campo',        COUNT(*) FROM public.fichas_campo
UNION ALL SELECT 'rutas_planificadas',  COUNT(*) FROM public.rutas_planificadas
UNION ALL SELECT 'metas_asesores',      COUNT(*) FROM public.metas_asesores
ORDER BY tabla;

-- ── Vista rápida: scores generados ───────────────────────
SELECT
  pc.nombres || ' ' || pc.apellidos AS cliente,
  pc.tipo_negocio, pc.zona_negocio,
  st.score, st.segmento, st.recomendacion,
  st.monto_max_sugerido
FROM public.scores_transaccionales st
JOIN public.perfiles_clientes pc ON pc.user_id = st.user_id
ORDER BY st.score DESC;

-- ============================================================
-- FIN — 03_seed_demo_local.sql · v1.0
-- Siguiente: ejecutar 04_test_scoring_local.sql
-- ============================================================
```

## 04 - Tests y validacion

Origen: `/Users/cc/Downloads/04_test_scoring_local.sql`

```sql
-- ============================================================
-- SCRIPT 04 — Tests y Consultas de Validación (LOCAL)
-- App Móvil Fuerza de Ventas · v1.0
-- ============================================================
-- EJECUTAR: 5to de 5  (después de 03_seed_demo_local.sql)
-- TIEMPO ESTIMADO: < 5 segundos
-- DONDE: pgAdmin 4 → Query Tool sobre DB: bd_appmovil_fventas
-- ============================================================
-- QUÉ PRUEBA:
--   TEST 1: Verificar scoring de todos los clientes
--   TEST 2: Simular evaluar_credito_campo() (llamada de la app)
--   TEST 3: Vista agenda del asesor (pantalla de inicio app)
--   TEST 4: Embudo de colocación (dashboard supervisor)
--   TEST 5: Renovaciones pendientes (carga automática mañana)
--   TEST 6: Query de segmentos para Power BI
-- ============================================================

-- ════════════════════════════════════════════════════════════
-- TEST 1 — Distribución de scores (validar el motor)
-- ════════════════════════════════════════════════════════════

SELECT
  st.segmento,
  COUNT(*) AS clientes,
  ROUND(AVG(st.score), 1) AS score_promedio,
  MIN(st.score) AS score_min,
  MAX(st.score) AS score_max,
  ROUND(AVG(st.monto_max_sugerido)) AS monto_max_prom
FROM public.scores_transaccionales st
GROUP BY st.segmento
ORDER BY st.segmento;

-- Detalle por cliente
SELECT
  pc.nombres || ' ' || pc.apellidos  AS cliente,
  pc.tipo_negocio,
  pc.zona_negocio,
  pc.ingreso_mensual_est,
  pc.deuda_actual,
  st.score,
  st.segmento,
  st.recomendacion,
  st.monto_max_sugerido
FROM public.scores_transaccionales st
JOIN public.perfiles_clientes pc ON pc.user_id = st.user_id
ORDER BY st.score DESC;

-- ════════════════════════════════════════════════════════════
-- TEST 2 — Simular llamada desde la app móvil
-- evaluar_credito_campo(ficha_id, monto, plazo)
-- Esta función es lo que llama .NET MAUI / Flutter al enviar la ficha
-- ════════════════════════════════════════════════════════════

-- CASO A: Rosa Condori — solicita S/ 8,000 a 12 meses
SELECT 'Rosa Condori — S/ 8,000 / 12 meses' AS caso,
  public.evaluar_credito_campo(
    'eeeeeeee-0001-0001-0001-000000000001'::UUID,  -- ficha_id
    8000,   -- monto solicitado
    12      -- plazo meses
  ) AS resultado_json;

-- CASO B: Juan Huanca — solicita S/ 25,000 a 18 meses
SELECT 'Juan Huanca — S/ 25,000 / 18 meses' AS caso,
  public.evaluar_credito_campo(
    'eeeeeeee-0001-0001-0001-000000000002'::UUID,
    25000, 18
  ) AS resultado_json;

-- CASO C: Flora Ayala — perfil medio, solicita S/ 5,000
SELECT 'Flora Ayala — S/ 5,000 / 12 meses' AS caso,
  public.evaluar_credito_campo(
    'eeeeeeee-0001-0001-0001-000000000004'::UUID,
    5000, 12
  ) AS resultado_json;

-- CASO D: Efraín Ramos (agro, deuda alta) — solicita S/ 18,000
SELECT 'Efraín Ramos — S/ 18,000 / 24 meses' AS caso,
  public.evaluar_credito_campo(
    'eeeeeeee-0001-0001-0001-000000000005'::UUID,
    18000, 24
  ) AS resultado_json;

-- ════════════════════════════════════════════════════════════
-- TEST 3 — Vista Agenda del Asesor
-- Lo que ve Jessica (ASE-001) al abrir la app en la mañana
-- ════════════════════════════════════════════════════════════

SELECT
  asesor,
  tipo_visita,
  cliente,
  negocio_nombre,
  distrito,
  monto_solicitado,
  score_obtenido,
  segmento,
  estado_ficha,
  CASE WHEN creada_offline THEN '📴 offline' ELSE '🌐 online' END AS modo_captura
FROM public.vw_agenda_asesor
WHERE asesor_id = 'bbbbbbbb-0001-0001-0001-000000000002'
ORDER BY fecha_visita DESC;

-- ════════════════════════════════════════════════════════════
-- TEST 4 — Embudo de Colocación (dashboard supervisor)
-- Equivale al reporte de KPIs de la tesis (30→56 créditos/asesor)
-- ════════════════════════════════════════════════════════════

SELECT
  asesor,
  fichas_total,
  completadas,
  pre_aprobados,
  aprobados,
  desembolsados,
  TO_CHAR(monto_desembolsado,'FM999,990.00') AS monto_soles
FROM public.vw_embudo_colocacion;

-- ════════════════════════════════════════════════════════════
-- TEST 5 — Renovaciones pendientes para mañana
-- Esta lista se carga automáticamente en la app cada mañana
-- ════════════════════════════════════════════════════════════

SELECT
  cliente,
  tipo_negocio,
  zona_negocio,
  score,
  segmento,
  TO_CHAR(monto_max_sugerido, 'FM999,990') AS monto_max_soles,
  recomendacion,
  estado_credito,
  asesor_asignado,
  vigente_hasta
FROM public.vw_renovaciones_pendientes
LIMIT 10;

-- ════════════════════════════════════════════════════════════
-- TEST 6 — Query para Power BI (Dashboard FieldIQ)
-- ════════════════════════════════════════════════════════════

-- Colocaciones por asesor y agencia
SELECT
  ag.nombre AS agencia,
  um.nombre || ' ' || um.apellido AS asesor,
  an.especialidad,
  ma.periodo,
  ma.meta_visitas, ma.real_visitas, ma.pct_visitas,
  ma.meta_creditos, ma.real_creditos, ma.pct_creditos,
  TO_CHAR(ma.meta_monto, 'FM999,990') AS meta_monto_soles,
  TO_CHAR(ma.real_monto, 'FM999,990') AS real_monto_soles,
  ma.pct_monto
FROM public.metas_asesores ma
JOIN public.asesores_negocio an ON an.id = ma.asesor_id
JOIN public.usuarios_mock um    ON um.id = an.user_id
JOIN public.agencias ag         ON ag.id = an.agencia_id
ORDER BY ma.pct_monto DESC;

-- Score por zona (para mapa de calor en Power BI)
SELECT
  pc.zona_negocio,
  pc.tipo_negocio,
  COUNT(*) AS clientes,
  ROUND(AVG(st.score), 1) AS score_promedio,
  COUNT(*) FILTER (WHERE st.segmento IN ('A','B')) AS clientes_premium,
  ROUND(AVG(st.monto_max_sugerido)) AS monto_potencial_prom
FROM public.scores_transaccionales st
JOIN public.perfiles_clientes pc ON pc.user_id = st.user_id
GROUP BY pc.zona_negocio, pc.tipo_negocio
ORDER BY score_promedio DESC;

-- ════════════════════════════════════════════════════════════
-- TEST 7 — Validar fórmula de cuota (sistema francés)
-- Verificar que cuota_estimada en creditos_preaprobados es correcta
-- ════════════════════════════════════════════════════════════

SELECT
  pc.nombres || ' ' || pc.apellidos AS cliente,
  cp.monto_preaprobado,
  cp.plazo_meses,
  cp.tasa_mensual || '%' AS TEM,
  cp.cuota_estimada       AS cuota_calculada_SQL,
  -- Verificación manual: C = M * [i*(1+i)^n / ((1+i)^n - 1)]
  ROUND(
    cp.monto_preaprobado
    * ((cp.tasa_mensual/100) * POWER(1 + cp.tasa_mensual/100, cp.plazo_meses))
    / (POWER(1 + cp.tasa_mensual/100, cp.plazo_meses) - 1)
  , 2) AS cuota_verificacion,
  cp.score_aprobacion,
  cp.estado,
  cp.vigente_hasta
FROM public.creditos_preaprobados cp
JOIN public.perfiles_clientes pc ON pc.user_id = cp.cliente_user_id
ORDER BY cp.score_aprobacion DESC;

-- ════════════════════════════════════════════════════════════
-- RESUMEN DE VALIDACIÓN
-- ════════════════════════════════════════════════════════════

WITH resumen AS (
  SELECT 'Usuarios totales'      AS metrica, COUNT(*)::TEXT AS valor FROM public.usuarios_mock
  UNION ALL SELECT 'Asesores activos',    COUNT(*)::TEXT FROM public.asesores_negocio WHERE activo
  UNION ALL SELECT 'Agencias activas',    COUNT(*)::TEXT FROM public.agencias WHERE activa
  UNION ALL SELECT 'Clientes con perfil', COUNT(*)::TEXT FROM public.perfiles_clientes
  UNION ALL SELECT 'Clientes con score',  COUNT(*)::TEXT FROM public.scores_transaccionales
  UNION ALL SELECT 'Fichas de campo',     COUNT(*)::TEXT FROM public.fichas_campo
  UNION ALL SELECT 'Fichas offline sync', COUNT(*)::TEXT FROM public.fichas_campo WHERE creada_offline
  UNION ALL SELECT 'Pre-aprobados',       COUNT(*)::TEXT FROM public.creditos_preaprobados
  UNION ALL SELECT 'Rutas hoy',           COUNT(*)::TEXT FROM public.rutas_planificadas WHERE fecha_ruta = CURRENT_DATE
  UNION ALL SELECT 'Movim. históricos',   COUNT(*)::TEXT FROM public.movimientos_mensuales
)
SELECT metrica, valor FROM resumen;

-- ============================================================
-- FIN — 04_test_scoring_local.sql · v1.0
--
-- ✅ Si todos los tests retornan filas: BD lista para la app móvil
-- 📱 Conectar desde la app usando credenciales de postgresql local
--    Host: localhost  |  Puerto: 5432  |  DB: bd_appmovil_fventas
--    User: postgres   |  Tablas clave: fichas_campo, asesores_negocio
-- ============================================================
```

