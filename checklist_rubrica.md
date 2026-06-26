# Checklist desde la rubrica - Proyecto Final Movil Banco Andino

Fuente: `/Users/cc/Downloads/RUBRICA_PROYECTO_FINAL_MOVIL.pdf`

Puntaje total: 20 puntos  
Criterios: 5 criterios x 4 puntos cada uno

Alcance: Las tres piezas deben comportarse como un solo sistema que comparte la misma base de datos (`bd_core_mobile`), se conecta al nucleo financiero (`bd_core_financiero`) mediante el puente de sincronizacion, y permite flujos completos de extremo a extremo: el asesor origina un credito en campo -> el Core lo evalua/aprueba/desembolsa -> el cliente lo ve reflejado en su app.

## Criterio 1 - Integracion end-to-end (FVentas <-> Core Mobile <-> AppClientes) (4 pts)

Evalua que las tres piezas compartan la misma base de datos y que el flujo cruce de un sistema a otro sin rupturas, incluyendo el puente al nucleo financiero.

- [ ] Las tres piezas comparten la misma base de datos.
- [ ] El flujo cruza de un sistema a otro sin rupturas.
- [ ] El flujo incluye el puente al nucleo financiero.
- [ ] El asesor registra una solicitud desde la App FVentas.
- [ ] La solicitud se encola en `sync_outbox`.
- [ ] La solicitud se promueve al Core (`bd_core_financiero`: `dcliente`/`dsolicitud`).
- [ ] El credito/desembolso se refleja de vuelta en las tablas espejo `cr_*`.
- [ ] El credito/desembolso aparece en la App Clientes.
- [ ] La App Clientes muestra creditos.
- [ ] La App Clientes muestra cronograma.
- [ ] La App Clientes muestra saldo.
- [ ] La App Clientes muestra movimientos.
- [ ] El flujo completo esta verificado sobre una sola `bd_core_mobile`.
- [ ] El flujo cruza las tres piezas pero requiere algun paso manual, por ejemplo disparar `POST /sync/promover` a mano.
- [ ] Algun dato no se sincroniza automaticamente.
- [ ] FVentas, App Clientes y Core funcionan por separado sobre la misma BD.
- [ ] No hay un flujo que conecte FVentas, App Clientes y Core.
- [ ] No hay puente al nucleo.
- [ ] No hay reflejo en la app de clientes.
- [ ] Los sistemas estan aislados, usan BDs distintas, o no hay integracion.

## Criterio 2 - App Fuerza de Ventas: originacion de credito en campo (4 pts)

Evalua el flujo del oficial de credito: gestion de cartera, ficha, pre-evaluacion, buro, solicitud y desembolso, alineado a la normativa de originacion.

- [ ] Implementa cartera offline-first.
- [ ] La cartera incluye filtros/orden.
- [ ] La cartera incluye marca de visita (GPS).
- [ ] Implementa ficha del cliente.
- [ ] La ficha del cliente incluye posicion.
- [ ] La ficha del cliente incluye historial.
- [ ] La ficha del cliente incluye oferta.
- [ ] La ficha del cliente incluye semaforo de riesgo.
- [ ] Implementa pre-evaluacion (elegibilidad/sujeto de credito).
- [ ] Implementa consulta de buro (SBS + lista negra).
- [ ] La consulta de buro incluye consentimiento firmado.
- [ ] Implementa solicitud por stepper.
- [ ] La solicitud incluye simulador de cronograma (RF-47).
- [ ] La solicitud incluye firma.
- [ ] Implementa transmision/expediente.
- [ ] Registra realmente en backend.
- [ ] Implementa el flujo completo pero faltan 1-2 piezas, por ejemplo simulador de cuotas sin cronograma, o buro sin lista negra/consentimiento.
- [ ] Implementa flujo basico solicitud -> envio sin reglas de originacion reales.
- [ ] No incluye pre-evaluacion, scoring ni buro.
- [ ] No hay logica de originacion o es inventada/incoherente.

## Criterio 3 - App Clientes (Homebanking movil): autoservicio (4 pts)

Evalua que el cliente autenticado consulte y opere sus productos sobre los datos reales del Core compartido.

- [ ] El cliente autenticado consulta sus productos sobre los datos reales del Core compartido.
- [ ] El cliente autenticado opera sus productos sobre los datos reales del Core compartido.
- [ ] Implementa login del cliente con DNI.
- [ ] Muestra perfil.
- [ ] Muestra cuentas de ahorro (saldo).
- [ ] Muestra creditos con cronograma de cuotas.
- [ ] Muestra movimientos.
- [ ] Muestra tarjetas.
- [ ] Muestra notificaciones.
- [ ] Registra operaciones (transferencia/pago).
- [ ] Las operaciones impactan la BD.
- [ ] Todos los datos provienen de `bd_core_mobile`/espejo `cr_*`.
- [ ] Los datos son coherentes con lo originado en FVentas.
- [ ] La consulta de productos esta completa, pero falta una vista, por ejemplo tarjetas o notificaciones.
- [ ] Las operaciones no persisten/impactan saldos.
- [ ] Solo existe login + una o dos consultas de productos.
- [ ] No hay cronograma ni operaciones.
- [ ] No existe la app de clientes o no opera sobre datos reales.

## Criterio 4 - Seguridad y control de acceso por roles (RBAC + JWT) (4 pts)

Evalua autenticacion, autorizacion por cargo y que cada actor (asesor, supervisor/admin, cliente) solo pueda hacer lo que le corresponde, validado en el backend.

- [ ] Implementa autenticacion.
- [ ] Implementa autorizacion por cargo.
- [ ] Cada actor (asesor, supervisor/admin, cliente) solo puede hacer lo que le corresponde.
- [ ] El control de acceso esta validado en el backend.
- [ ] Implementa login con JWT en las tres piezas.
- [ ] Implementa login del asesor en FVentas.
- [ ] Implementa login del cliente en App Clientes.
- [ ] Guarda el token en almacenamiento seguro (`flutter_secure_storage`).
- [ ] Implementa bloqueo por 5 intentos persistente.
- [ ] Implementa matriz de permisos por rol (asesor / supervisor / administrador / cliente).
- [ ] Restringe acciones, por ejemplo reportes solo supervisor/admin.
- [ ] Restringe endpoints de cliente solo con su propio token.
- [ ] Las acciones restringidas estan bloqueadas en backend con 401/403 a quien no corresponde.
- [ ] JWT + roles funcionan, pero algun permiso esta mal asignado.
- [ ] JWT + roles funcionan, pero algun permiso esta validado solo parcialmente en backend.
- [ ] Hay login pero el control de roles es parcial o solo en el frontend.
- [ ] No hay autenticacion real o cualquier usuario puede hacer cualquier cosa.

## Criterio 5 - Calidad de datos, arquitectura y documentacion (4 pts)

Evalua la consistencia de la BD compartida, la arquitectura en capas de cada pieza y la documentacion de respaldo.

- [ ] La BD compartida es consistente.
- [ ] Cada pieza tiene arquitectura en capas.
- [ ] Existe documentacion de respaldo.
- [ ] `bd_core_mobile` tiene integridad referencial.
- [ ] `bd_core_mobile` incluye tablas espejo `cr_*` del nucleo.
- [ ] El puente `sync_outbox`/`sync_log` es consistente.
- [ ] Los datos demo estan calibrados.
- [ ] Los datos demo incluyen mora con semaforo.
- [ ] Los datos demo incluyen productos coherentes.
- [ ] El Core tiene arquitectura por capas (`rutas -> controladores -> servicios/repositorios -> BD`).
- [ ] Flutter usa MVVM/Riverpod offline-first.
- [ ] Flutter esta organizado en `data`/`domain`/`presentation`.
- [ ] DDL y scripts SQL/seed estan versionados.
- [ ] Existen Historias de Usuario.
- [ ] Existen RF.
- [ ] Existen diagramas UML completos.
- [ ] Los diagramas UML incluyen clases.
- [ ] Los diagramas UML incluyen secuencia.
- [ ] Los diagramas UML incluyen componentes.
- [ ] Los diagramas UML incluyen casos de uso.
- [ ] Los diagramas UML incluyen estados.
- [ ] Arquitectura y datos son correctos, pero documentacion, UML o scripts estan incompletos.
- [ ] Funciona pero con datos inconsistentes o sin documentacion.
- [ ] Datos incoherentes, sin estructura ni documentacion.

## Resumen de puntaje

- [ ] Criterio 1 - Integracion end-to-end (FVentas <-> Core Mobile <-> Clientes): 4 pts.
- [ ] Criterio 2 - App Fuerza de Ventas - originacion de credito en campo: 4 pts.
- [ ] Criterio 3 - App Clientes (Homebanking movil) - autoservicio: 4 pts.
- [ ] Criterio 4 - Seguridad y RBAC (JWT + roles): 4 pts.
- [ ] Criterio 5 - Calidad de datos, arquitectura y documentacion: 4 pts.
- [ ] TOTAL: 20 pts.

## Escala de calificacion

- [ ] 18 - 20: Sobresaliente.
- [ ] 14 - 17: Notable.
- [ ] 11 - 13: Aprobado.
- [ ] 0 - 10: Desaprobado.

## Hoja de autoevaluacion

- [ ] Integracion end-to-end (FVentas <-> Core <-> Clientes): nivel obtenido, pts / 4, evidencia / observacion.
- [ ] App Fuerza de Ventas - originacion: nivel obtenido, pts / 4, evidencia / observacion.
- [ ] App Clientes - autoservicio: nivel obtenido, pts / 4, evidencia / observacion.
- [ ] Seguridad y RBAC: nivel obtenido, pts / 4, evidencia / observacion.
- [ ] Calidad de datos, arquitectura y documentacion: nivel obtenido, pts / 4, evidencia / observacion.
- [ ] TOTAL: / 20.

## Estado operativo actualizado - 2026-06-25

Esta seccion complementa la rubrica con el flujo funcional definido para los cuatro sistemas. No modifica la transcripcion original.

### Backend / Core Mobile

- [x] FastAPI esta integrado y responde.
- [x] Usa `bd_core_mobile` como base operacional.
- [x] Implementa JWT para clientes y asesores.
- [x] Expone productos del cliente: cuentas, creditos, cronograma, movimientos, tarjetas y notificaciones.
- [x] Registra solicitudes creadas por el vendedor.
- [x] Encola solicitudes en `sync_outbox`.
- [x] Promueve solicitudes a `bd_core_financiero.dcliente` y `dsolicitud`.
- [x] Expone un endpoint para que el cliente cree una solicitud inicial de prestamo.
- [x] Expone una bandeja administrativa de todas las solicitudes pendientes para el frontend web.
- [x] Expone endpoints RBAC para aprobar, rechazar o condicionar solicitudes.
- [x] Registra usuario decisor, fecha, monto aprobado y motivo de rechazo.
- [x] Al aprobar, genera desembolso, credito, cronograma y movimientos.
- [x] Sincroniza automaticamente el resultado a las tablas espejo `cr_*`.
- [x] Procesa transferencias/pagos afectando saldos y movimientos reales.

### Mobile Cliente

- [x] Login con DNI y JWT.
- [x] Consulta perfil, cuentas, saldos, creditos y cronograma.
- [x] Consulta movimientos, tarjetas y notificaciones.
- [x] Registra transferencias/pagos como operaciones pendientes.
- [x] Valida cuenta destino y fondos disponibles.
- [x] Confirma transferencias/pagos e impacta saldos.
- [x] Genera movimientos contables visibles despues de operar.
- [x] Permite iniciar una solicitud de prestamo.
- [x] Captura monto, plazo, destino y negocio/ingresos.
- [x] Muestra el estado de la solicitud iniciada por el cliente.
- [x] Muestra aprobacion, rechazo, motivo o desembolso final.

### Mobile Empleado / Vendedor

- [x] Login de asesor con JWT.
- [x] Consulta cartera asignada.
- [x] Tiene stepper de solicitud, pre-evaluacion, buro y simulador referencial.
- [x] Registra una solicitud y expediente en backend.
- [x] Recibe solicitudes iniciadas previamente por clientes y asignadas a su bandeja de estados.
- [x] Completa la solicitud del cliente sin volver a crearla desde cero.
- [x] Completa datos financieros, coordenadas, consentimiento y firma del expediente.
- [x] Transmite coordenadas de la visita al completar el expediente.
- [x] Envia el expediente completado a revision web.
- [ ] Funciona offline-first con persistencia local y sincronizacion posterior.

### Frontend Web Administrativo

- [x] Existe una aplicacion web administrativa independiente (`lib/main_admin.dart`).
- [x] Implementa login de supervisor/administrador.
- [x] Lista y filtra solicitudes por estado.
- [x] Muestra expediente, cliente, vendedor, condiciones e informacion financiera.
- [x] Permite aprobar una solicitud indicando monto.
- [x] Permite rechazar una solicitud indicando motivo obligatorio.
- [x] Protege decisiones con RBAC de supervisor/administrador (403 para operador probado).
- [x] Persiste auditoria de cada decision.
- [x] Dispara desembolso y actualizacion de `cr_*` al aprobar.
- [x] Notifica el resultado a cliente y vendedor.

### Flujo end-to-end objetivo

- [x] Cliente inicia solicitud de prestamo desde Mobile Cliente.
- [x] Backend registra la solicitud y la asigna a un vendedor.
- [x] Vendedor recibe la solicitud asignada.
- [x] Vendedor completa el expediente con datos financieros y ubicacion.
- [x] Frontend web recibe el expediente para evaluacion.
- [x] Supervisor/admin aprueba o rechaza.
- [x] Si aprueba, backend desembolsa y crea credito, cronograma y movimientos.
- [x] Mobile Cliente muestra el nuevo credito, solicitud, saldo y movimientos.
- [x] Mobile Vendedor muestra el estado final al refrescar su bandeja.
- [x] El flujo queda auditado y sincronizado automaticamente en `bd_core_mobile`.
