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
