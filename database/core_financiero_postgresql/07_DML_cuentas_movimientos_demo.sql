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
