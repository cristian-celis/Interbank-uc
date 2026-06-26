-- ============================================================================
-- bd_core_mobile — Runner maestro (ejecuta todo en orden con psql)
-- ----------------------------------------------------------------------------
-- Uso desde esta carpeta:
--   1) Crear la base (una sola vez):
--        psql -U postgres -h localhost -c "CREATE DATABASE bd_core_mobile;"
--   2) Cargar todo:
--        psql -U postgres -h localhost -d bd_core_mobile -f 99_run_all.sql
--
-- NOTA: si la base ya tiene datos y quieres recrearla desde cero,
--       descomenta la linea del 00_DDL_drop (BORRA TODO).
-- ============================================================================

\echo '>>> (00) DROP de tablas (desactivado por defecto)'
-- \i 00_DDL_drop_tables_core_mobile.sql

\echo '>>> (01) Creando tablas...'
\i 01_DDL_create_tables_core_mobile.sql

\echo '>>> (02) Catalogos: agencias + asesores...'
\i 02_DML_catalogos_core_mobile.sql

\echo '>>> (03) Clientes + accesos app...'
\i 03_DML_clientes_core_mobile.sql

\echo '>>> (04) Cartera: creditos + cronograma + cobranza...'
\i 04_DML_cartera_core_mobile.sql

\echo '>>> (05) Extras app clientes: tarjetas + notificaciones...'
\i 05_DML_app_cliente_extras_core_mobile.sql

\echo '>>> (06) Workflow de creditos y auditoria...'
\i 06_DDL_workflow_creditos.sql

\echo '>>> (07) Cuentas y movimientos demo...'
\i 07_DML_cuentas_movimientos_demo.sql

\echo '>>> (08) 30 casos credito flujo movil...'
\i 08_DML_30_casos_credito_flujo_movil.sql

\echo '>>> Carga completa.'
