# Avance del proyecto Interbank UC

## Objetivo Funcional Actual

El sistema se compone de cuatro aplicaciones:

1. Backend/Core Mobile.
2. Mobile Cliente.
3. Mobile Empleado/Vendedor.
4. Frontend Web Administrativo.

Flujo objetivo:

1. El cliente inicia una solicitud de prestamo desde Mobile Cliente.
2. El backend registra y asigna la solicitud a un vendedor.
3. El vendedor visita al cliente y completa el expediente.
4. El frontend web permite a supervisor/admin aprobar o rechazar.
5. La aprobacion genera desembolso, credito, cronograma y movimientos.
6. El resultado se refleja en Mobile Cliente y Mobile Vendedor.

El flujo actual todavia difiere: la solicitud nace en Mobile Vendedor y no existe Frontend Web Administrativo.

## Hecho

- Dos apps Flutter separadas por flavor y entrypoint:
  - `clientes` con `lib/main_clientes.dart`.
  - `ventas` con `lib/main_ventas.dart`.
- Backend FastAPI integrado en `backend/core_mobile_fastapi`.
- Base principal `bd_core_mobile` creada y cargada con 22 tablas:
  - `cr_creditos`, `cr_cronograma_pagos`, `cr_cuentas_ahorro`, `cr_movimientos`.
  - `usuarios_cliente`, `tarjetas`, `notificaciones`, `operaciones_cliente`.
  - `sync_outbox`, `sync_log`.
- Datos demo cargados:
  - 30 asesores.
  - 600 clientes.
  - 600 creditos.
  - 13,500 cuotas.
  - 20 tarjetas y 20 notificaciones demo.
- FastAPI con JWT, bloqueo por intentos, login de asesor y login de cliente por DNI.
- App Clientes conectada por REST al Core Mobile:
  - perfil, cuentas, creditos, cronograma, movimientos, tarjetas, notificaciones.
  - operaciones cliente persistidas en `/cliente/operaciones`.
- App Fuerza de Ventas conectada por REST al Core Mobile:
  - cartera, solicitudes, historial de solicitudes.
  - solicitudes encoladas en `sync_outbox`.
- Puente local probado:
  - solicitud -> `sync_outbox` -> `/sync/promover` -> `bd_core_financiero.dcliente/dsolicitud`.
- `bd_core_financiero` creado como arnes local minimo porque no se entrego schema completo del core financiero.

## Validado

- `flutter analyze`: sin issues.
- `flutter test`: 2 tests pasan.
- FastAPI `/` y `/docs`: OK.
- Login asesor `0001 / 1234`: OK.
- Login cliente `40000001 / 1234`: OK.
- Promocion de solicitud al core financiero minimo: OK.

## Pendiente Contra Rubrica

- Completar UI de originacion con stepper real.
- Exponer pre-evaluacion y buro en la pantalla, consumiendo `/pre-evaluar` y `/buro/consulta`.
- Registrar consentimiento firmado de buro y firma del cliente de forma visible.
- Capturar o simular GPS de visita desde la UI y enviarlo a `/cartera/{id}/visita` o `/clientes/{id}/ubicacion`.
- Agregar simulador de cronograma RF-47 visible antes de enviar solicitud.
- Recalcular puntaje final de rubrica con evidencia actualizada.
