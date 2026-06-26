# Evaluacion imparcial contra `checklist_rubrica.md`

Fecha: 2026-06-18  
Base evaluada: codigo actual en `/Users/cc/Developer/Interbank_uc`  
Checklist base: `checklist_rubrica.md`

## Resultado

**Puntaje estimado imparcial: 14.25 / 20 - Notable**

- Criterio 1 - Integracion end-to-end: **2.5 / 4**
- Criterio 2 - App Fuerza de Ventas: **3.0 / 4**
- Criterio 3 - App Clientes: **3.25 / 4**
- Criterio 4 - Seguridad y RBAC: **2.5 / 4**
- Criterio 5 - Datos, arquitectura y documentacion: **3.0 / 4**

La mejora respecto al primer analisis es sustancial: ahora existe FastAPI, `bd_core_mobile`, tablas `cr_*`, JWT, `sync_outbox`, app clientes con productos reales y solicitudes que se promueven a `dcliente/dsolicitud`. La razon principal para no asignar 18+ es que el core financiero es un arnes minimo local, no hay aprobacion/desembolso completo, y el credito originado no vuelve automaticamente a `cr_*` para aparecer como nuevo producto del cliente.

## Verificaciones Ejecutadas

- ✅ `flutter analyze`: sin issues.
- ✅ `flutter test`: 2 tests pasan.
- ✅ FastAPI responde en `http://127.0.0.1:8003/`.
- ✅ PostgreSQL local accesible con `postgres / jcelis`.
- ✅ `bd_core_mobile`: 22 tablas.
- ✅ `bd_core_financiero`: 2 tablas (`dcliente`, `dsolicitud`) como arnes minimo.

Conteos observados:

- `bd_core_mobile.sync_outbox`: 1
- `bd_core_mobile.sync_log`: 1
- `bd_core_mobile.solicitudes_credito`: 1
- `bd_core_mobile.cr_creditos`: 600
- `bd_core_mobile.cr_cronograma_pagos`: 13,500
- `bd_core_mobile.tarjetas`: 20
- `bd_core_mobile.notificaciones`: 20
- `bd_core_mobile.operaciones_cliente`: 1
- `bd_core_financiero.dcliente`: 1
- `bd_core_financiero.dsolicitud`: 1

## Criterio 1 - Integracion end-to-end (2.5 / 4)

Estado general: **⚠️ Cumple parcialmente**

| Item evaluable | Estado | Evidencia / observacion |
|---|---:|---|
| Tres piezas comparten `bd_core_mobile` | ⚠️ Parcial | Flutter usa FastAPI por defecto (`lib/app/dependency_bootstrap.dart:4-15`) y FastAPI usa `bd_core_mobile`; `bd_core_financiero` es separado por diseno. |
| Flujo cruza sistemas sin rupturas | ⚠️ Parcial | La app ventas crea solicitud via `/solicitudes`; backend la encola y promueve. No hay retorno automatico a cliente. |
| Puente al nucleo financiero | ✅ Cumple | `/sync/promover` existe (`backend/core_mobile_fastapi/app/routes/rtr_sync.py:11-17`) y `svc_promocion` escribe `dcliente/dsolicitud` (`backend/core_mobile_fastapi/app/services/svc_promocion.py:28-97`). |
| Asesor registra solicitud desde FVentas | ✅ Cumple | UI envia solicitud (`lib/features/sales/presentation/sales_home_page.dart:409-417`) y data source llama `/solicitudes` (`lib/shared/data/bank_data_source_strategy.dart:602-623`). |
| Solicitud se encola en `sync_outbox` | ✅ Cumple | Insercion en `sync_outbox` en `rep_solicitudes.py:74-93`; DB observada: `sync_outbox=1`. |
| Solicitud se promueve a `dcliente/dsolicitud` | ✅ Cumple con salvedad | Promocion probada; DB observada: `dcliente=1`, `dsolicitud=1`. Salvedad: core financiero es minimo local, no schema completo. |
| Credito/desembolso se refleja de vuelta en `cr_*` | ❌ No cumple | No hay proceso que tome `dsolicitud`, apruebe/desembolse y actualice `cr_creditos`, `cr_cronograma_pagos`, `cr_movimientos`. |
| App Clientes ve el credito originado por FVentas | ❌ No cumple | App Clientes lee creditos existentes desde `/cliente/creditos`; no se probo ni existe codigo de reflejo del nuevo desembolso. |
| App Clientes muestra creditos, cronograma, saldo y movimientos | ✅ Cumple | `getCustomerSnapshot` consume `/cliente/cuentas`, `/cliente/creditos`, cronograma, movimientos (`bank_data_source_strategy.dart:430-486`). |
| Flujo completo sobre una sola `bd_core_mobile` | ⚠️ Parcial | La capa mobile si usa `bd_core_mobile`; el nucleo financiero es otra DB minima (`bd_core_financiero`), como exige el puente, pero incompleta. |

Justificacion de puntaje: supera "Regular" porque existe puente y flujo mobile->core, pero no alcanza "Excelente" porque falta aprobacion/desembolso y sincronizacion de vuelta a `cr_*`. Tampoco es "Bueno" pleno si se interpreta que debe cruzar las tres piezas hasta App Clientes con el credito originado.

## Criterio 2 - App Fuerza de Ventas (3.0 / 4)

Estado general: **⚠️ Cumple parcialmente alto**

| Item evaluable | Estado | Evidencia / observacion |
|---|---:|---|
| Cartera offline-first | ⚠️ Parcial | Hay cartera desde `/cartera`; switch "Modo campo offline" visible (`sales_home_page.dart:380-388`), pero no hay persistencia local offline real. |
| Filtros/orden de cartera | ⚠️ Parcial | Backend devuelve `orden_manual`; no se ve control de filtros/orden en UI. |
| Marca de visita GPS | ⚠️ Parcial | Backend soporta `lat/lng` (`sch_cartera.py`, `rep_cartera.py`), pero UI no captura GPS real ni envia visita con coordenadas. |
| Ficha del cliente: posicion, historial, oferta, riesgo | ⚠️ Parcial | Backend tiene `/clientes/{id}/ficha`; UI de cartera muestra score/riesgo/productos resumidos, pero no ficha completa navegable. |
| Pre-evaluacion | ✅ Cumple | Data source llama `/pre-evaluar` antes de crear solicitud (`bank_data_source_strategy.dart:585-596`). |
| Buro SBS + lista negra | ✅ Cumple simulado | Data source llama `/buro/consulta`; backend simula SBS/lista negra (`rtr_buro.py:40-69`). |
| Consentimiento firmado | ⚠️ Parcial | UI muestra "Consentimiento firmado" (`sales_home_page.dart:347-350`), pero no captura firma/consentimiento real ni guarda en `consultas_buro.firma_consentimiento_base64`. |
| Solicitud por stepper | ✅ Cumple | `Stepper` en `sales_home_page.dart:275-423`. |
| Simulador de cronograma RF-47 | ✅ Cumple parcial | Simulador visible (`sales_home_page.dart:1053-1102`), pero solo calcula cuota referencial, no cronograma completo cuota por cuota. |
| Firma de solicitud | ⚠️ Parcial | Se envia `firma_cliente_base64: firma-demo-*` (`bank_data_source_strategy.dart:620`), no firma real. |
| Transmision/expediente y registro backend | ✅ Cumple | Solicitud se registra en `solicitudes_credito` y retorna expediente; backend encola `sync_outbox`. |

Justificacion de puntaje: el flujo de originacion ya es funcional y conectado al backend. Las brechas son principalmente "realismo operativo": GPS, offline real, consentimiento/firma real y cronograma completo.

## Criterio 3 - App Clientes (3.25 / 4)

Estado general: **⚠️ Cumple parcialmente alto**

| Item evaluable | Estado | Evidencia / observacion |
|---|---:|---|
| Login cliente con DNI | ✅ Cumple | `/cliente/login` por `numero_documento` (`rtr_cliente.py:22-30`); Flutter envia DNI (`bank_data_source_strategy.dart:402-419`). |
| Perfil | ✅ Cumple | `/cliente/perfil` consumido en `getCustomerSnapshot` (`bank_data_source_strategy.dart:430-431`). |
| Cuentas de ahorro y saldo | ✅ Cumple | `/cliente/cuentas` y mapeo de saldos (`bank_data_source_strategy.dart:432-454`). |
| Creditos con cronograma | ✅ Cumple | `/cliente/creditos` + `/cronograma` (`bank_data_source_strategy.dart:433-476`). |
| Movimientos | ✅ Cumple | `/cliente/movimientos` (`bank_data_source_strategy.dart:434-486`). |
| Tarjetas | ✅ Cumple | `/cliente/tarjetas`; UI pestaña Tarjetas (`customer_home_page.dart:360-388`). |
| Notificaciones | ✅ Cumple | `/cliente/notificaciones`; UI las lista (`customer_home_page.dart:390-402`). |
| Operaciones transferencia/pago | ✅ Cumple parcial | UI registra operacion (`customer_home_page.dart:48-75`), data source llama `/cliente/operaciones` (`bank_data_source_strategy.dart:560-578`). |
| Operaciones impactan BD | ✅ Cumple | DB observada: `operaciones_cliente=1`. |
| Operaciones impactan saldos | ❌ No cumple | La operacion queda como registro `pendiente`; no se descuenta saldo ni se genera movimiento `cr_movimientos`. |
| Datos provienen de `bd_core_mobile`/`cr_*` | ✅ Cumple | Endpoints consultan tablas mobile y `cr_*` (`rtr_cliente.py:41-86`, `rep_cliente.py`). |
| Coherencia con lo originado en FVentas | ❌ No cumple | El credito originado no vuelve como nuevo credito desembolsado visible en App Clientes. |

Justificacion de puntaje: la app clientes es la parte mas solida actualmente. Pierde puntos por no impactar saldos/movimientos y por no cerrar el circuito con la originacion nueva.

## Criterio 4 - Seguridad y RBAC (2.5 / 4)

Estado general: **⚠️ Cumple parcialmente**

| Item evaluable | Estado | Evidencia / observacion |
|---|---:|---|
| Login con JWT | ✅ Cumple | `create_access_token` con `python-jose` (`cfg_security.py:14-20`). |
| Login asesor y cliente | ✅ Cumple | Asesor `/auth/login`; cliente `/cliente/login`. |
| Endpoints protegidos por token | ✅ Cumple parcial | `get_current_asesor` y `get_current_cliente` validan payloads (`cfg_auth.py:7-24`). |
| Bloqueo por 5 intentos persistente | ✅ Cumple parcial | Asesor incrementa y bloquea (`ctl_auth.py:19-23`); cliente bloquea (`ctl_auth_cliente.py:19-23`). Persistencia depende de columnas DB. |
| Matriz asesor/supervisor/admin/cliente | ⚠️ Parcial | Tokens incluyen `perfil`; pero las rutas verifican principalmente "asesor" vs "cliente", no permisos finos supervisor/admin. |
| Reportes solo supervisor/admin | ❌ No cumple | `/reportes/productividad` solo requiere asesor autenticado, no valida perfil supervisor/admin. |
| Cliente solo con su propio token | ✅ Cumple parcial | Endpoints usan `cliente_id` del token (`rtr_cliente.py:33-86`); cronograma por codigo credito no valida explicitamente propiedad en la ruta (`rtr_cliente.py:51-57`). |
| Backend responde 401/403 a no autorizados | ⚠️ Parcial | Ausencia/invalidacion de token produce 401; no hay 403 por permisos finos. |
| Token en `flutter_secure_storage` | ❌ No cumple | `pubspec.yaml` no incluye `flutter_secure_storage`; tokens estan en memoria (`bank_data_source_strategy.dart:368-370`). |

Justificacion de puntaje: hay autenticacion real con JWT y bloqueo, pero RBAC no esta completo y Flutter no almacena tokens de forma segura.

## Criterio 5 - Datos, arquitectura y documentacion (3.0 / 4)

Estado general: **⚠️ Cumple parcialmente alto**

| Item evaluable | Estado | Evidencia / observacion |
|---|---:|---|
| `bd_core_mobile` con integridad referencial | ✅ Cumple | DDL con FK en `01_DDL_create_tables_core_mobile.sql`; DB cargada con 22 tablas. |
| Tablas espejo `cr_*` | ✅ Cumple | `cr_creditos`, `cr_cronograma_pagos`, `cr_cuentas_ahorro`, `cr_movimientos`; conteos verificados. |
| `sync_outbox`/`sync_log` consistente | ✅ Cumple | Tablas existen, conteos observados, promocion registra log. |
| Datos demo calibrados | ✅ Cumple parcial | 600 clientes, 600 creditos, 13,500 cuotas, tarjetas/notificaciones; falta demo de desembolso derivado de solicitud nueva. |
| Arquitectura Core rutas/controladores/servicios/repositorios/BD | ✅ Cumple | `backend/core_mobile_fastapi/app/routes`, `controllers`, `services`, `repositories`, `models`. |
| Flutter MVVM/Riverpod offline-first | ❌ No cumple | No hay `riverpod` en `pubspec.yaml`; se usa `StatefulWidget` + Clean Architecture/repositorios. Offline real no esta implementado. |
| Flutter `data/domain/presentation` | ✅ Cumple | Estructura presente en `lib/features/*`. |
| DDL y SQL/seed versionados | ✅ Cumple | `database/core_financiero_postgresql/*.sql`, incluyendo runner y seed extra. |
| Historias de Usuario + RF | ⚠️ Parcial | Hay menciones RF/HU en comentarios/backend, pero no documento formal completo. |
| UML completo: clases/secuencia/componentes/casos/estados | ❌ No cumple | Busqueda de archivos UML/drawio/puml no encontro artefactos. |
| Documentacion operativa | ✅ Cumple parcial | README actualizado con backend/comandos web; quedan docs legacy que mencionan `bd_appmovil_fventas`. |

Justificacion de puntaje: datos y backend estan bastante alineados con rubrica; cae por falta de Riverpod/offline-first formal, UML/HU/RF completos y core financiero real.

## Items No Verificables Automaticamente

- 🔍 Probar en navegador que las pantallas renderizan sin errores visuales: ejecutar los comandos del README y validar login manual.
- 🔍 Validar experiencia de usuario del stepper y simulador RF-47: abrir App Ventas, enviar solicitud y revisar tarjeta de estado.
- 🔍 Validar propiedad estricta del cronograma: intentar pedir cronograma de otro cliente con token de cliente actual. Esto requiere prueba manual/API adicional; por codigo no se ve validacion de ownership en `rtr_cliente.py:51-57`.

## Conclusion Imparcial

El proyecto ya no esta en estado "demo aislada"; ahora tiene una arquitectura end-to-end razonable y varias piezas criticas de la rubrica funcionan. Sin embargo, **no cumple aun como flujo bancario completo Excelente**, porque el desembolso no vuelve a la app clientes, el core financiero es minimo, la seguridad no tiene RBAC fino ni almacenamiento seguro, y faltan artefactos formales de documentacion/UML.

Calificacion defendible ante evaluador: **14 a 15 / 20**. Uso **14.25 / 20** como estimacion conservadora.
