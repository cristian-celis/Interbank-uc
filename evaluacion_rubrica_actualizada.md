# Evaluacion actualizada contra rubrica

Fecha: 2026-06-18  
Base principal actual: `bd_core_mobile` + FastAPI `backend/core_mobile_fastapi`  
Nota: no se entrego schema completo de `bd_core_financiero`; se creo un arnes local minimo con `dcliente` y `dsolicitud` para validar el puente.

## Puntaje Estimado

**15 / 20 - Notable**

- Criterio 1 - Integracion end-to-end: **3 / 4**
- Criterio 2 - App Fuerza de Ventas: **3 / 4**
- Criterio 3 - App Clientes: **3.5 / 4**
- Criterio 4 - Seguridad y RBAC: **2.5 / 4**
- Criterio 5 - Datos, arquitectura y documentacion: **3 / 4**

## Criterio 1 - Integracion end-to-end

Estado: **⚠️ Cumple parcialmente alto**

Evidencia:

- FastAPI integrado en `backend/core_mobile_fastapi`.
- `bd_core_mobile` creada con 22 tablas, incluyendo `cr_*`, `sync_outbox` y `sync_log`.
- Solicitud creada desde `/solicitudes` se encola en `sync_outbox`.
- `/sync/promover` procesa la cola y escribe en `bd_core_financiero.dcliente` y `bd_core_financiero.dsolicitud`.
- Prueba realizada: `aplicados=1`, `errores=0`, `dcliente=1`, `dsolicitud=1`.

Falta:

- No hay core financiero completo, solo arnes local minimo.
- No hay flujo automatico de aprobacion/desembolso que actualice de vuelta `cr_creditos`, `cr_cronograma_pagos` y `cr_movimientos` para reflejar la solicitud nueva en App Clientes.

## Criterio 2 - App Fuerza de Ventas

Estado: **⚠️ Cumple parcialmente alto**

Evidencia:

- App Ventas consume FastAPI por `DATA_SOURCE=api`.
- Login asesor JWT: `0001 / 1234`.
- Cartera desde `/cartera`.
- Solicitud ahora se presenta como stepper.
- Se consulta pre-evaluacion `/pre-evaluar`.
- Se consulta buro `/buro/consulta` con SBS + lista negra simulada.
- Envio de solicitud incluye firma demo (`firma_cliente_base64`).
- Solicitud registra backend y cola `sync_outbox`.
- UI muestra simulador de cronograma RF-47 referencial.

Falta:

- GPS real desde navegador/dispositivo y marca de visita enviada por UI.
- Consentimiento firmado real, no solo demo visible.
- Captura real de documentos/camara.
- Offline-first persistente local aun no esta implementado.

## Criterio 3 - App Clientes

Estado: **✅ Cumple casi completo**

Evidencia:

- Login cliente por DNI: `40000001 / 1234`.
- Datos desde FastAPI y `bd_core_mobile`.
- Perfil, cuentas, creditos, cronograma y movimientos desde endpoints `/cliente/*`.
- Tarjetas y notificaciones visibles en pestaña propia.
- Operaciones se registran en `/cliente/operaciones` y persisten en `operaciones_cliente`.
- Datos provienen de tablas espejo `cr_*`.

Falta:

- La operacion queda en estado `pendiente`; falta promocion completa a `foperaciones` del core financiero completo.
- Falta que un credito originado por FVentas, aprobado/desembolsado, aparezca automaticamente como nuevo producto del cliente.

## Criterio 4 - Seguridad y RBAC

Estado: **⚠️ Cumple parcialmente**

Evidencia:

- JWT con `python-jose`.
- Login asesor y cliente.
- Endpoints protegidos con Bearer token.
- Bloqueo por 5 intentos implementado en backend para asesor/cliente.
- Separacion de payload entre asesor (`asesor_id`) y cliente (`cliente_id`).

Falta:

- Flutter no usa `flutter_secure_storage`; el token queda en memoria del data source.
- Matriz completa asesor/supervisor/administrador/cliente no esta expresada en todas las rutas.
- Reportes no restringen explicitamente supervisor/admin; dependen solo de asesor autenticado.

## Criterio 5 - Datos, arquitectura y documentacion

Estado: **⚠️ Cumple parcialmente alto**

Evidencia:

- `bd_core_mobile` con integridad referencial y tablas `cr_*`.
- `sync_outbox`/`sync_log` consistentes y probados.
- Core FastAPI con rutas, controladores, repositorios, servicios/modelos y BD.
- Flutter mantiene capas `data/domain/presentation`.
- DDL/DML versionados en `database/core_financiero_postgresql`.
- README actualizado con comandos web y backend.

Falta:

- Flutter no usa Riverpod/MVVM formal.
- No hay UML completo versionado.
- No hay documento formal de Historias de Usuario + RF completo.
- Core financiero completo no esta disponible; se uso arnes minimo.

## Comandos Validados

```bash
/Users/cc/Developer/flutter/bin/flutter analyze
/Users/cc/Developer/flutter/bin/flutter test
/Users/cc/Developer/flutter/bin/flutter build web -t lib/main_clientes.dart --dart-define=DATA_SOURCE=api --dart-define=API_BASE_URL=http://127.0.0.1:8003
/Users/cc/Developer/flutter/bin/flutter build web -t lib/main_ventas.dart --dart-define=DATA_SOURCE=api --dart-define=API_BASE_URL=http://127.0.0.1:8003
```
