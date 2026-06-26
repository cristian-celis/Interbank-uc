# Guion de demo en video

Objetivo: mostrar el happy path completo en 4 sistemas sin explicar detalles internos.

## 1. Preparacion

Reiniciar datos de la demo:

```bash
cd /Users/cc/Developer/Interbank_uc/backend/core_mobile_fastapi
.venv/bin/python -m scripts.reset_demo_video
```

Levantar backend:

```bash
cd /Users/cc/Developer/Interbank_uc/backend/core_mobile_fastapi
.venv/bin/uvicorn main:app --reload --host 127.0.0.1 --port 8003
```

Ejecutar cada comando Flutter en una terminal distinta, pero iniciarlos uno por
uno. Esperar a que aparezca la pantalla de la primera app antes de iniciar la
siguiente. Flutter comparte la carpeta `build/` y dos arranques simultaneos
pueden dejar una pantalla en blanco.

Levantar Mobile Cliente:

```bash
cd /Users/cc/Developer/Interbank_uc
/Users/cc/Developer/flutter/bin/flutter run -d chrome \
  -t lib/main_clientes.dart \
  --dart-define=DATA_SOURCE=api \
  --dart-define=API_BASE_URL=http://127.0.0.1:8003
```

Levantar Mobile Vendedor:

```bash
cd /Users/cc/Developer/Interbank_uc
/Users/cc/Developer/flutter/bin/flutter run -d chrome \
  -t lib/main_ventas.dart \
  --dart-define=DATA_SOURCE=api \
  --dart-define=API_BASE_URL=http://127.0.0.1:8003
```

Levantar Web Administrativo:

```bash
cd /Users/cc/Developer/Interbank_uc
/Users/cc/Developer/flutter/bin/flutter run -d chrome \
  -t lib/main_admin.dart \
  --dart-define=API_BASE_URL=http://127.0.0.1:8003
```

## 2. Credenciales

- Cliente: DNI precargado `40000001`, clave `1234`.
- Vendedor asignado: codigo `0002`, clave `1234`.
- Supervisor web: codigo `0001`, clave `1234`.

## 3. Escena A - Transferencia del cliente

1. Ingresar a Mobile Cliente.
2. Mostrar saldo inicial de S/ 5,000.
3. Abrir `Pagar`.
4. Destino: `AHO-0002`.
5. Monto: `50`.
6. Pulsar `Registrar operacion`.
7. Volver a Inicio o pulsar refrescar.

Resultado esperado:

- Mensaje `Operacion registrada en Core Mobile`.
- Saldo disminuye a S/ 4,950.
- Aparece movimiento `Transferencia` por -S/ 50.

## 4. Escena B - Cliente solicita prestamo

1. Abrir pestaña `Prestamo`.
2. Mantener datos demo:
   - Monto: S/ 12,000.
   - Ingreso: S/ 5,000.
   - Negocio: Bodega familiar.
   - Destino: Capital de trabajo.
3. Pulsar `Crear solicitud`.

Resultado esperado:

- Mensaje de solicitud creada.
- Aparece expediente en `Mis solicitudes`.
- Estado `borrador`.
- Vendedor asignado: Lucia Flores Mamani (`0002`).

## 5. Escena C - Vendedor visita y completa

1. Ingresar a Mobile Vendedor con `0002 / 1234`.
2. Abrir `Estados`.
3. Pulsar refrescar si la solicitud no aparece aun.
4. Localizar el expediente del cliente Maria Flores Lazo.
5. Pulsar `Completar`.

Resultado esperado:

- El expediente cambia a estado de revision/comite.
- Se registran ingresos, gastos, patrimonio, coordenadas, firma y consentimiento demo.

Frase sugerida:

> El vendedor recibe la solicitud que inicio el cliente, realiza la visita y completa el expediente.

## 6. Escena D - Supervisor aprueba en web

1. Ingresar a Web Administrativo con `0001 / 1234`.
2. Filtrar `recibido_comite`.
3. Mostrar cliente, vendedor, monto, destino e ingresos.
4. Pulsar `Aprobar`.
5. Mantener monto S/ 12,000 o reducirlo.
6. Observacion: `Capacidad de pago validada`.
7. Confirmar.

Resultado esperado:

- La solicitud cambia a `desembolsado`.
- Se crea credito, cronograma, movimiento y notificaciones.

## 7. Escena E - Cliente ve el desembolso

1. Volver a Mobile Cliente.
2. Pulsar el icono refrescar.
3. Mostrar el nuevo saldo.
4. Mostrar `Desembolso de prestamo` en movimientos.
5. Abrir `Creditos` y mostrar `Prestamo movil` con cronograma.
6. Abrir `Prestamo` y mostrar la solicitud como `desembolsado`.

Frase sugerida:

> La decision tomada en el frontend web se refleja inmediatamente en la app del cliente.

## 8. Cierre

Resumen sugerido:

> El cliente inicia la operacion, el vendedor completa el expediente, el supervisor decide desde web y el backend actualiza saldos, creditos, cronogramas, movimientos y notificaciones.

## Plan B

Si una pantalla no actualiza inmediatamente:

1. Pulsar el icono refrescar.
2. Cambiar de pestaña y volver.
3. Como ultimo recurso, recargar la pagina del navegador e ingresar nuevamente.
