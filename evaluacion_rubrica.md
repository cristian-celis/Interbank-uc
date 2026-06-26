# Evaluacion del proyecto contra checklist de rubrica

Proyecto analizado: `/Users/cc/Developer/Interbank_uc`  
Checklist base: `/Users/cc/Developer/Interbank_uc/checklist_rubrica.md`  
Fecha de evaluacion: 2026-06-18

## Resultado ejecutivo

Evaluacion estatica estimada: **7 / 20 - Desaprobado**

- Criterio 1 - Integracion end-to-end: **0.5 / 4**. Hay dos apps Flutter y data source compartido, pero no existe Core Mobile/FastAPI, `bd_core_mobile`, `bd_core_financiero`, `sync_outbox`, `sync_log`, tablas `cr_*`, ni promocion/desembolso end-to-end.
- Criterio 2 - App Fuerza de Ventas: **2 / 4**. Existe flujo basico de cartera/ruta/solicitud, ficha resumida, captura simulada y envio a PostgreSQL local, pero faltan GPS real, stepper, firma, simulador de cronograma RF-47, SBS/lista negra/consentimiento y reglas completas de originacion.
- Criterio 3 - App Clientes: **2 / 4**. Existe login, perfil, saldos, cuentas, creditos con cronograma, movimientos y pago/transferencia validada en UI, pero no hay tarjetas, notificaciones reales, persistencia/impacto de operaciones, ni datos desde `bd_core_mobile`/`cr_*`.
- Criterio 4 - Seguridad/RBAC/JWT: **1 / 4**. Hay login y bloqueo de entrada por rol en frontend, pero no hay JWT, almacenamiento seguro, bloqueo por intentos, RBAC backend ni 401/403.
- Criterio 5 - Calidad/arquitectura/documentacion: **1.5 / 4**. Hay Clean Architecture Flutter, SQL/documentacion local y FK parciales, pero no arquitectura Core por capas, no Riverpod, no BD objetivo de la rubrica, no UML/RF/historias completas.

Limitaciones de verificacion:

- No pude ejecutar `flutter test` ni `flutter analyze` porque `flutter` no esta instalado o no esta en PATH en este entorno (`zsh: command not found: flutter`).
- No hay repositorio Git detectado en `/Users/cc/Developer/Interbank_uc` (`fatal: not a git repository`).
- No se levanto la app visualmente; las pantallas y flujos se evaluaron por codigo fuente.

## Criterio 1 - Integracion end-to-end (FVentas <-> Core Mobile <-> AppClientes) (4 pts)

- ⚠️ **Cumple parcialmente** - Las tres piezas comparten la misma base de datos.  
  Evidencia: hay dos apps Flutter con entrypoints separados (`/Users/cc/Developer/Interbank_uc/lib/main_clientes.dart:6`, `/Users/cc/Developer/Interbank_uc/lib/main_ventas.dart:6`) y ambas usan `buildAppDependencies()` (`/Users/cc/Developer/Interbank_uc/lib/app/dependency_bootstrap.dart:3`). Pero la BD configurada es `bd_appmovil_fventas`, no `bd_core_mobile` (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:98`, `/Users/cc/Developer/Interbank_uc/README.md:28`).
- ❌ **No cumple** - El flujo cruza de un sistema a otro sin rupturas.  
  Evidencia: la solicitud de ventas se inserta en `public.fichas_campo` (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:509`) y clientes lee cuentas/movimientos/creditos de otras tablas (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:470`), sin codigo que conecte solicitud -> aprobacion/desembolso -> app clientes.
- ❌ **No cumple** - El flujo incluye el puente al nucleo financiero.  
  Evidencia: no hay ocurrencias de `sync_outbox`, `sync_log`, `bd_core_financiero`, `dcliente` o `dsolicitud` en el proyecto, salvo el checklist.
- ✅ **Cumple** - El asesor registra una solicitud desde la App FVentas.  
  Evidencia: pantalla `Nueva solicitud` con formulario y boton `Enviar solicitud` (`/Users/cc/Developer/Interbank_uc/lib/features/sales/presentation/sales_home_page.dart:264`, `/Users/cc/Developer/Interbank_uc/lib/features/sales/presentation/sales_home_page.dart:358`); envio a `submitCreditApplication` (`/Users/cc/Developer/Interbank_uc/lib/features/sales/presentation/sales_home_page.dart:53`).
- ❌ **No cumple** - La solicitud se encola en `sync_outbox`.  
  Evidencia: la insercion real va a `public.fichas_campo`, no a `sync_outbox` (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:511`).
- ❌ **No cumple** - La solicitud se promueve al Core (`bd_core_financiero`: `dcliente`/`dsolicitud`).  
  Evidencia: no hay backend Core ni referencias a esas tablas.
- ❌ **No cumple** - El credito/desembolso se refleja de vuelta en las tablas espejo `cr_*`.  
  Evidencia: no existen tablas `cr_*` en `/Users/cc/Developer/Interbank_uc/database/schema.sql:1` ni en la lista de tablas del SQL del profesor (`/Users/cc/Developer/Interbank_uc/docs/postgresql_profesor_unificado.md:210`).
- ❌ **No cumple** - El credito/desembolso aparece en la App Clientes.  
  Evidencia: los creditos del cliente vienen de mocks (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:201`) o de `creditos_preaprobados` (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:724`), no del desembolso originado por FVentas.
- ✅ **Cumple** - La App Clientes muestra creditos.  
  Evidencia: pestaña `Creditos` (`/Users/cc/Developer/Interbank_uc/lib/features/banking/presentation/customer_home_page.dart:121`) y tarjetas de credito (`/Users/cc/Developer/Interbank_uc/lib/features/banking/presentation/customer_home_page.dart:724`).
- ✅ **Cumple** - La App Clientes muestra cronograma.  
  Evidencia: renderiza `credit.schedule` (`/Users/cc/Developer/Interbank_uc/lib/features/banking/presentation/customer_home_page.dart:783`) y cuotas (`/Users/cc/Developer/Interbank_uc/lib/features/banking/presentation/customer_home_page.dart:821`).
- ✅ **Cumple** - La App Clientes muestra saldo.  
  Evidencia: saldo total y cuentas (`/Users/cc/Developer/Interbank_uc/lib/features/banking/presentation/customer_home_page.dart:167`, `/Users/cc/Developer/Interbank_uc/lib/features/banking/presentation/customer_home_page.dart:181`).
- ✅ **Cumple** - La App Clientes muestra movimientos.  
  Evidencia: `Ultimos movimientos` y lista desde `snapshot.movements` (`/Users/cc/Developer/Interbank_uc/lib/features/banking/presentation/customer_home_page.dart:171`).
- ❌ **No cumple** - El flujo completo esta verificado sobre una sola `bd_core_mobile`.  
  Evidencia: la configuracion usa `bd_appmovil_fventas` (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:98`).
- ❌ **No cumple** - El flujo cruza las tres piezas pero requiere algun paso manual, por ejemplo disparar `POST /sync/promover` a mano.  
  Evidencia: no existe endpoint `POST /sync/promover` ni backend HTTP.
- 🔍 **No verificable automaticamente** - Algun dato no se sincroniza automaticamente.  
  Pasos: ejecutar FVentas contra PostgreSQL, crear solicitud con `Modo campo offline` desactivado, luego entrar a App Clientes con el mismo cliente/DNI y verificar si aparece un credito nuevo con saldo/cronograma/movimientos. Resultado esperado para cumplir: debe aparecer sin editar BD manualmente. Por codigo, no hay conexion implementada.
- ⚠️ **Cumple parcialmente** - FVentas, App Clientes y Core funcionan por separado sobre la misma BD.  
  Evidencia: FVentas y Clientes comparten estrategia de datos; no existe Core. Ver `/Users/cc/Developer/Interbank_uc/lib/app/app_dependencies.dart:45`.
- ✅ **Cumple** - No hay un flujo que conecte FVentas, App Clientes y Core.  
  Evidencia: hallazgo negativo confirmado por ausencia de Core/FastAPI y puente.
- ✅ **Cumple** - No hay puente al nucleo.  
  Evidencia: no hay `sync_outbox`, `sync_log` ni endpoints de sincronizacion.
- ✅ **Cumple** - No hay reflejo en la app de clientes.  
  Evidencia: el alta de solicitud no escribe las tablas leidas por App Clientes (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:505`, `/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:715`).
- ⚠️ **Cumple parcialmente** - Los sistemas estan aislados, usan BDs distintas, o no hay integracion.  
  Evidencia: no son BDs distintas cuando se usa PostgreSQL local, pero si falta integracion end-to-end.

## Criterio 2 - App Fuerza de Ventas: originacion de credito en campo (4 pts)

- ⚠️ **Cumple parcialmente** - Implementa cartera offline-first.  
  Evidencia: existe cartera diaria (`/Users/cc/Developer/Interbank_uc/lib/features/sales/presentation/sales_home_page.dart:205`) y bandera `offlineCaptured` (`/Users/cc/Developer/Interbank_uc/lib/features/sales/presentation/sales_home_page.dart:34`), pero la documentacion declara pendiente la persistencia local offline (`/Users/cc/Developer/Interbank_uc/docs/progreso.md:41`).
- ❌ **No cumple** - La cartera incluye filtros/orden.  
  Evidencia: la UI lista `portfolio.dailyVisits.map` sin controles de filtro u orden (`/Users/cc/Developer/Interbank_uc/lib/features/sales/presentation/sales_home_page.dart:209`).
- ❌ **No cumple** - La cartera incluye marca de visita (GPS).  
  Evidencia: hay boton `Navegar` vacio (`/Users/cc/Developer/Interbank_uc/lib/features/sales/presentation/sales_home_page.dart:920`) y no hay dependencia/geolocalizacion en `pubspec.yaml`.
- ✅ **Cumple** - Implementa ficha del cliente.  
  Evidencia: cada visita incluye `creditFile` con score/riesgo/productos/comportamiento (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:254`).
- ❌ **No cumple** - La ficha del cliente incluye posicion.  
  Evidencia: no se encontro campo de posicion/geolocalizacion en entidad o UI.
- ✅ **Cumple** - La ficha del cliente incluye historial.  
  Evidencia: `paymentBehavior` muestra comportamiento de pago (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:258`).
- ⚠️ **Cumple parcialmente** - La ficha del cliente incluye oferta.  
  Evidencia: la ruta muestra monto estimado desde `monto_estimado` (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:828`), pero no una oferta formal de credito en pantalla.
- ✅ **Cumple** - La ficha del cliente incluye semaforo de riesgo.  
  Evidencia: `riskLevel` desde mock o segmento scoring (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:256`, `/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:856`).
- ⚠️ **Cumple parcialmente** - Implementa pre-evaluacion (elegibilidad/sujeto de credito).  
  Evidencia: usa scoring/recomendacion local (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:829`, `/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:939`), pero no reglas completas de elegibilidad/sujeto de credito en la pantalla.
- ⚠️ **Cumple parcialmente** - Implementa consulta de buro (SBS + lista negra).  
  Evidencia: solo aparece `Buro demo`/`Scoring PostgreSQL` (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:327`, `/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:907`); no hay SBS ni lista negra.
- ❌ **No cumple** - La consulta de buro incluye consentimiento firmado.  
  Evidencia: no se encontro consentimiento ni firma.
- ❌ **No cumple** - Implementa solicitud por stepper.  
  Evidencia: la solicitud es un unico `Form`/`Column`, no `Stepper` (`/Users/cc/Developer/Interbank_uc/lib/features/sales/presentation/sales_home_page.dart:273`).
- ❌ **No cumple** - La solicitud incluye simulador de cronograma (RF-47).  
  Evidencia: no hay simulador ni RF-47; busqueda solo encontro cronograma en App Clientes.
- ❌ **No cumple** - La solicitud incluye firma.  
  Evidencia: no hay campos o dependencias de firma.
- ⚠️ **Cumple parcialmente** - Implementa transmision/expediente.  
  Evidencia: envia solicitud y documentos simulados (`/Users/cc/Developer/Interbank_uc/lib/features/sales/presentation/sales_home_page.dart:67`), y muestra `transmitted` (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:573`), pero no expediente real completo.
- ⚠️ **Cumple parcialmente** - Registra realmente en backend.  
  Evidencia: registra en PostgreSQL local directo (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:509`), pero no en backend FastAPI/Core.
- ✅ **Cumple** - Implementa el flujo completo pero faltan 1-2 piezas, por ejemplo simulador de cuotas sin cronograma, o buro sin lista negra/consentimiento.  
  Evidencia: faltan mas de 1-2 piezas; como descriptor de nivel, el proyecto queda por debajo de "Bueno".
- ✅ **Cumple** - Implementa flujo basico solicitud -> envio sin reglas de originacion reales.  
  Evidencia: formulario + envio (`/Users/cc/Developer/Interbank_uc/lib/features/sales/presentation/sales_home_page.dart:53`) con validaciones basicas.
- ⚠️ **Cumple parcialmente** - No incluye pre-evaluacion, scoring ni buro.  
  Evidencia: si incluye scoring/buro simulado, pero no SBS/lista negra/consentimiento.
- ❌ **No cumple** - No hay logica de originacion o es inventada/incoherente.  
  Evidencia: si hay logica basica coherente de captura/solicitud, aunque incompleta.

## Criterio 3 - App Clientes (Homebanking movil): autoservicio (4 pts)

- ⚠️ **Cumple parcialmente** - El cliente autenticado consulta sus productos sobre los datos reales del Core compartido.  
  Evidencia: consulta snapshot (`/Users/cc/Developer/Interbank_uc/lib/features/banking/presentation/customer_home_page.dart:35`), pero desde mock o PostgreSQL local, no Core compartido.
- ❌ **No cumple** - El cliente autenticado opera sus productos sobre los datos reales del Core compartido.  
  Evidencia: `Validar operacion` solo cambia un mensaje en memoria (`/Users/cc/Developer/Interbank_uc/lib/features/banking/presentation/customer_home_page.dart:47`).
- ⚠️ **Cumple parcialmente** - Implementa login del cliente con DNI.  
  Evidencia: el formulario tiene DNI (`/Users/cc/Developer/Interbank_uc/lib/shared/presentation/login_page.dart:32`), pero login usa email/password (`/Users/cc/Developer/Interbank_uc/lib/shared/presentation/login_page.dart:127`) y PostgreSQL busca por email (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:416`).
- ✅ **Cumple** - Muestra perfil.  
  Evidencia: pestaña `Perfil` (`/Users/cc/Developer/Interbank_uc/lib/features/banking/presentation/customer_home_page.dart:131`) y `_ProfileTab` (`/Users/cc/Developer/Interbank_uc/lib/features/banking/presentation/customer_home_page.dart:323`).
- ✅ **Cumple** - Muestra cuentas de ahorro (saldo).  
  Evidencia: pestaña `Cuentas` y saldo (`/Users/cc/Developer/Interbank_uc/lib/features/banking/presentation/customer_home_page.dart:181`).
- ✅ **Cumple** - Muestra creditos con cronograma de cuotas.  
  Evidencia: `_CreditCard` y `_ScheduleTile` (`/Users/cc/Developer/Interbank_uc/lib/features/banking/presentation/customer_home_page.dart:724`, `/Users/cc/Developer/Interbank_uc/lib/features/banking/presentation/customer_home_page.dart:821`).
- ✅ **Cumple** - Muestra movimientos.  
  Evidencia: `Ultimos movimientos` (`/Users/cc/Developer/Interbank_uc/lib/features/banking/presentation/customer_home_page.dart:171`).
- ❌ **No cumple** - Muestra tarjetas.  
  Evidencia: no se encontro modulo/vista de tarjetas; solo menciones de "Pago tarjeta credito" como movimiento mock (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:189`).
- ⚠️ **Cumple parcialmente** - Muestra notificaciones.  
  Evidencia: hay icono de notificaciones sin accion (`/Users/cc/Developer/Interbank_uc/lib/features/banking/presentation/customer_home_page.dart:70`).
- ⚠️ **Cumple parcialmente** - Registra operaciones (transferencia/pago).  
  Evidencia: formulario de transferencia/pago existe (`/Users/cc/Developer/Interbank_uc/lib/features/banking/presentation/customer_home_page.dart:238`), pero solo valida.
- ❌ **No cumple** - Las operaciones impactan la BD.  
  Evidencia: `_simulateTransfer` solo asigna `_transferMessage` (`/Users/cc/Developer/Interbank_uc/lib/features/banking/presentation/customer_home_page.dart:47`); no hay metodo de repositorio para persistir operaciones.
- ❌ **No cumple** - Todos los datos provienen de `bd_core_mobile`/espejo `cr_*`.  
  Evidencia: datos desde mock o `bd_appmovil_fventas`, no `cr_*`.
- ❌ **No cumple** - Los datos son coherentes con lo originado en FVentas.  
  Evidencia: no hay relacion entre solicitud insertada en `fichas_campo` y creditos mostrados en cliente.
- ✅ **Cumple** - La consulta de productos esta completa, pero falta una vista, por ejemplo tarjetas o notificaciones.  
  Evidencia: faltan tarjetas y notificaciones reales.
- ✅ **Cumple** - Las operaciones no persisten/impactan saldos.  
  Evidencia: `_simulateTransfer` no escribe BD ni muta saldo.
- ❌ **No cumple** - Solo existe login + una o dos consultas de productos.  
  Evidencia: hay mas vistas: dashboard, cuentas, creditos, pagos, perfil.
- ❌ **No cumple** - No hay cronograma ni operaciones.  
  Evidencia: si hay cronograma y formulario de operaciones, aunque operaciones son simuladas.
- ❌ **No cumple** - No existe la app de clientes o no opera sobre datos reales.  
  Evidencia: existe app de clientes (`/Users/cc/Developer/Interbank_uc/lib/app/customer_banking_app.dart:7`), pero no opera datos reales del Core.

## Criterio 4 - Seguridad y control de acceso por roles (RBAC + JWT) (4 pts)

- ⚠️ **Cumple parcialmente** - Implementa autenticacion.  
  Evidencia: existe pantalla login (`/Users/cc/Developer/Interbank_uc/lib/shared/presentation/login_page.dart:111`), pero modo local no valida password criptograficamente (`/Users/cc/Developer/Interbank_uc/docs/postgresql_local.md:116`).
- ⚠️ **Cumple parcialmente** - Implementa autorizacion por cargo.  
  Evidencia: `_canEnterDestination` limita cliente/asesor en frontend (`/Users/cc/Developer/Interbank_uc/lib/shared/presentation/login_page.dart:164`).
- ⚠️ **Cumple parcialmente** - Cada actor (asesor, supervisor/admin, cliente) solo puede hacer lo que le corresponde.  
  Evidencia: cliente/asesor se separan por frontend; no hay supervisor/admin en la app ni backend que lo haga cumplir.
- ❌ **No cumple** - El control de acceso esta validado en el backend.  
  Evidencia: no hay backend; PostgreSQL local es accedido directo desde Flutter.
- ❌ **No cumple** - Implementa login con JWT en las tres piezas.  
  Evidencia: no hay dependencia ni codigo JWT en `pubspec.yaml` (`/Users/cc/Developer/Interbank_uc/pubspec.yaml:30`).
- ⚠️ **Cumple parcialmente** - Implementa login del asesor en FVentas.  
  Evidencia: `SalesForceApp` inicia en `LoginPage` para ventas (`/Users/cc/Developer/Interbank_uc/lib/app/sales_force_app.dart:18`), pero sin JWT/password real.
- ⚠️ **Cumple parcialmente** - Implementa login del cliente en App Clientes.  
  Evidencia: `CustomerBankingApp` inicia en `LoginPage` para clientes (`/Users/cc/Developer/Interbank_uc/lib/app/customer_banking_app.dart:18`), pero sin JWT/password real.
- ❌ **No cumple** - Guarda el token en almacenamiento seguro (`flutter_secure_storage`).  
  Evidencia: `pubspec.yaml` no incluye `flutter_secure_storage`.
- ❌ **No cumple** - Implementa bloqueo por 5 intentos persistente.  
  Evidencia: no hay contador de intentos ni almacenamiento persistente.
- ⚠️ **Cumple parcialmente** - Implementa matriz de permisos por rol (asesor / supervisor / administrador / cliente).  
  Evidencia: solo enum `customer`/`salesOfficer` y mapeo de `asesor`/`admin` a `salesOfficer` (`/Users/cc/Developer/Interbank_uc/lib/features/auth/domain/entities/auth_user.dart:1`, `/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:577`); no matriz completa.
- ❌ **No cumple** - Restringe acciones, por ejemplo reportes solo supervisor/admin.  
  Evidencia: no hay reportes supervisor/admin.
- ❌ **No cumple** - Restringe endpoints de cliente solo con su propio token.  
  Evidencia: no hay endpoints ni tokens.
- ❌ **No cumple** - Las acciones restringidas estan bloqueadas en backend con 401/403 a quien no corresponde.  
  Evidencia: no hay backend HTTP.
- ❌ **No cumple** - JWT + roles funcionan, pero algun permiso esta mal asignado.  
  Evidencia: no hay JWT.
- ❌ **No cumple** - JWT + roles funcionan, pero algun permiso esta validado solo parcialmente en backend.  
  Evidencia: no hay JWT ni backend.
- ✅ **Cumple** - Hay login pero el control de roles es parcial o solo en el frontend.  
  Evidencia: `_canEnterDestination` en UI (`/Users/cc/Developer/Interbank_uc/lib/shared/presentation/login_page.dart:164`).
- ⚠️ **Cumple parcialmente** - No hay autenticacion real o cualquier usuario puede hacer cualquier cosa.  
  Evidencia: hay login UI, pero el modo local no valida password criptograficamente y no hay backend/JWT.

## Criterio 5 - Calidad de datos, arquitectura y documentacion (4 pts)

- ⚠️ **Cumple parcialmente** - La BD compartida es consistente.  
  Evidencia: `database/schema.sql` define FK basicas (`/Users/cc/Developer/Interbank_uc/database/schema.sql:10`), pero no la BD objetivo de rubrica.
- ✅ **Cumple** - Cada pieza tiene arquitectura en capas.  
  Evidencia: README declara `domain`, `data`, `presentation` (`/Users/cc/Developer/Interbank_uc/README.md:14`), y carpetas existen en `lib/features/*`.
- ⚠️ **Cumple parcialmente** - Existe documentacion de respaldo.  
  Evidencia: README, `docs/progreso.md`, `docs/postgresql_local.md`, `docs/postgresql_profesor_unificado.md`; faltan HU/RF/UML completos.
- ⚠️ **Cumple parcialmente** - `bd_core_mobile` tiene integridad referencial.  
  Evidencia: no existe `bd_core_mobile`; el esquema local tiene FK en tablas como `savings_accounts.customer_id` (`/Users/cc/Developer/Interbank_uc/database/schema.sql:12`).
- ❌ **No cumple** - `bd_core_mobile` incluye tablas espejo `cr_*` del nucleo.  
  Evidencia: no existen tablas `cr_*`.
- ❌ **No cumple** - El puente `sync_outbox`/`sync_log` es consistente.  
  Evidencia: no existen `sync_outbox` ni `sync_log`.
- ⚠️ **Cumple parcialmente** - Los datos demo estan calibrados.  
  Evidencia: mocks y seeds tienen saldos/creditos/scoring (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:160`, `/Users/cc/Developer/Interbank_uc/docs/progreso.md:16`), pero no datos del ecosistema Core requerido.
- ⚠️ **Cumple parcialmente** - Los datos demo incluyen mora con semaforo.  
  Evidencia: mock menciona una mora menor y riesgo medio (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:269`).
- ✅ **Cumple** - Los datos demo incluyen productos coherentes.  
  Evidencia: cuentas, movimientos, creditos, servicios en mock (`/Users/cc/Developer/Interbank_uc/lib/shared/data/bank_data_source_strategy.dart:160`).
- ❌ **No cumple** - El Core tiene arquitectura por capas (`rutas -> controladores -> servicios/repositorios -> BD`).  
  Evidencia: no hay Core/FastAPI ni archivos Python backend.
- ❌ **No cumple** - Flutter usa MVVM/Riverpod offline-first.  
  Evidencia: no hay dependencia Riverpod en `pubspec.yaml`; la app usa `StatefulWidget`, repositorios/use cases y estrategia de datos.
- ✅ **Cumple** - Flutter esta organizado en `data`/`domain`/`presentation`.  
  Evidencia: README y estructura (`/Users/cc/Developer/Interbank_uc/README.md:16`).
- ⚠️ **Cumple parcialmente** - DDL y scripts SQL/seed estan versionados.  
  Evidencia: existe `database/schema.sql` y documento SQL unificado, pero la guia apunta a scripts en `/Users/cc/Downloads`, fuera del repo (`/Users/cc/Developer/Interbank_uc/docs/postgresql_local.md:27`).
- ❌ **No cumple** - Existen Historias de Usuario.  
  Evidencia: no se encontraron archivos de historias.
- ❌ **No cumple** - Existen RF.  
  Evidencia: no se encontraron documentos RF; solo menciones no estructuradas.
- ❌ **No cumple** - Existen diagramas UML completos.  
  Evidencia: no se encontraron archivos `.puml`, `.drawio` ni documentos UML.
- ❌ **No cumple** - Los diagramas UML incluyen clases.  
  Evidencia: no hay UML.
- ❌ **No cumple** - Los diagramas UML incluyen secuencia.  
  Evidencia: no hay UML.
- ❌ **No cumple** - Los diagramas UML incluyen componentes.  
  Evidencia: no hay UML.
- ❌ **No cumple** - Los diagramas UML incluyen casos de uso.  
  Evidencia: no hay UML.
- ❌ **No cumple** - Los diagramas UML incluyen estados.  
  Evidencia: no hay UML.
- ✅ **Cumple** - Arquitectura y datos son correctos, pero documentacion, UML o scripts estan incompletos.  
  Evidencia: arquitectura Flutter correcta y documentacion parcial, pero sin UML/HU/RF completos.
- ⚠️ **Cumple parcialmente** - Funciona pero con datos inconsistentes o sin documentacion.  
  Evidencia: hay documentacion parcial; no se pudo ejecutar Flutter para confirmar funcionamiento.
- ❌ **No cumple** - Datos incoherentes, sin estructura ni documentacion.  
  Evidencia: si hay estructura y documentacion parcial.

## Resumen de puntaje

- ⚠️ **Cumple parcialmente** - Criterio 1 - Integracion end-to-end (FVentas <-> Core Mobile <-> Clientes): **0.5 / 4**.
- ⚠️ **Cumple parcialmente** - Criterio 2 - App Fuerza de Ventas - originacion de credito en campo: **2 / 4**.
- ⚠️ **Cumple parcialmente** - Criterio 3 - App Clientes (Homebanking movil) - autoservicio: **2 / 4**.
- ⚠️ **Cumple parcialmente** - Criterio 4 - Seguridad y RBAC (JWT + roles): **1 / 4**.
- ⚠️ **Cumple parcialmente** - Criterio 5 - Calidad de datos, arquitectura y documentacion: **1.5 / 4**.
- ❌ **No cumple** - TOTAL: **7 / 20**.

## Escala de calificacion

- ❌ **No cumple** - 18 - 20: Sobresaliente.
- ❌ **No cumple** - 14 - 17: Notable.
- ❌ **No cumple** - 11 - 13: Aprobado.
- ✅ **Cumple** - 0 - 10: Desaprobado.

## Hoja de autoevaluacion

- ⚠️ **Cumple parcialmente** - Integracion end-to-end (FVentas <-> Core <-> Clientes): nivel obtenido **Insuficiente**, pts **0.5 / 4**, evidencia: falta Core/puente/tablas objetivo.
- ⚠️ **Cumple parcialmente** - App Fuerza de Ventas - originacion: nivel obtenido **Regular**, pts **2 / 4**, evidencia: flujo basico solicitud/envio, sin piezas normativas completas.
- ⚠️ **Cumple parcialmente** - App Clientes - autoservicio: nivel obtenido **Regular**, pts **2 / 4**, evidencia: consultas varias, operaciones simuladas y sin datos Core.
- ⚠️ **Cumple parcialmente** - Seguridad y RBAC: nivel obtenido **Insuficiente/Regular bajo**, pts **1 / 4**, evidencia: login UI y rol frontend, sin JWT/backend.
- ⚠️ **Cumple parcialmente** - Calidad de datos, arquitectura y documentacion: nivel obtenido **Regular bajo**, pts **1.5 / 4**, evidencia: arquitectura Flutter y SQL parcial, sin Core/UML/RF/HU.
- ✅ **Cumple** - TOTAL: **7 / 20**.

## Pasos manuales recomendados para comprobar en la app

### App Clientes

1. Ejecutar: `flutter run --flavor clientes -t lib/main_clientes.dart`.
2. En login, usar el correo demo que aparece precargado o un cliente de PostgreSQL si se corre con `DATA_SOURCE=postgres`.
3. Resultado esperado: entrar a la app `Clientes`.
4. Ir a `Inicio`: debe verse saldo total y ultimos movimientos.
5. Ir a `Cuentas`: deben verse cuentas de ahorro y saldos.
6. Ir a `Creditos`: debe verse al menos un credito y su cronograma de cuotas.
7. Ir a `Pagar`: ingresar destino `Luz del Sur` y monto `10.00`; pulsar `Validar operacion`.
8. Resultado esperado actual: aparece mensaje de operacion validada. Para cumplir la rubrica, deberia persistir en BD e impactar saldo; por codigo no ocurre.
9. Pulsar icono de notificaciones.
10. Resultado esperado actual: no ocurre nada. Para cumplir la rubrica, deberia abrir lista real de notificaciones.

### App Fuerza de Ventas

1. Ejecutar: `flutter run --flavor ventas -t lib/main_ventas.dart`.
2. Ingresar con un asesor demo, por ejemplo `jessica.quispe@fieldiq.pe` si se usa PostgreSQL local.
3. Resultado esperado: entrar a `Fuerza de Ventas`.
4. Ir a `Cartera`: comprobar lista de clientes/visitas.
5. Buscar filtros/orden: resultado esperado actual, no hay controles.
6. Ir a `Ruta`: comprobar panel de ruta y boton de navegacion.
7. Pulsar `Navegar`: resultado esperado actual, no hay accion real ni GPS.
8. Ir a `Solicitud`: llenar cliente, DNI/RUC, telefono, actividad, monto `15000`; dejar `Modo campo offline` activo; pulsar `Enviar solicitud`.
9. Resultado esperado actual: se muestra tarjeta de estado/pipeline. Para cumplir la rubrica, deberia haber stepper, firma, consentimiento, SBS/lista negra y simulador de cronograma RF-47.
10. Repetir con `Modo campo offline` desactivado y PostgreSQL activo.
11. Resultado esperado para cumplimiento end-to-end: la solicitud deberia promoverse al Core, generar credito/desembolso y aparecer en App Clientes. Por codigo no hay puente ni Core, asi que no deberia ocurrir automaticamente.

### Verificacion con PostgreSQL local

1. Crear BD `bd_appmovil_fventas` y cargar los scripts indicados en `/Users/cc/Developer/Interbank_uc/docs/postgresql_local.md:25`.
2. Ejecutar clientes o ventas con:

```bash
flutter run \
  --dart-define=DATA_SOURCE=postgres \
  --dart-define=PG_HOST=localhost \
  --dart-define=PG_PORT=5432 \
  --dart-define=PG_DATABASE=bd_appmovil_fventas \
  --dart-define=PG_USER=postgres \
  --dart-define=PG_PASSWORD=postgres
```

3. Crear una solicitud desde FVentas con modo online.
4. Consultar en BD:

```sql
select * from public.fichas_campo order by created_at desc limit 5;
```

5. Resultado esperado actual: la ficha aparece en `fichas_campo`.
6. Consultar tablas requeridas por rubrica:

```sql
select to_regclass('public.sync_outbox');
select to_regclass('public.sync_log');
select to_regclass('public.cr_creditos');
```

7. Resultado esperado actual: tablas no existentes, salvo que se hayan creado fuera del proyecto.
