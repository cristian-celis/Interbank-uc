# Interbank UC

Proyecto movil academico para Banco Andino / Interbank UC:

- **App Clientes**: home banking movil.
- **App Fuerza de Ventas**: originacion de credito en campo.
- **Core Mobile FastAPI**: backend operacional compartido.
- **PostgreSQL `bd_core_mobile`**: base compartida con tablas espejo `cr_*` y cola `sync_outbox`.

## Arquitectura

El proyecto usa capas en Flutter:

- `lib/features/*/domain`: entidades, contratos de repositorio y casos de uso.
- `lib/features/*/data`: modelos y repositorios concretos.
- `lib/features/*/presentation`: pantallas y widgets.
- `lib/shared/data`: data sources y estrategias.
- `backend/core_mobile_fastapi`: FastAPI con rutas, controladores, repositorios, servicios y modelos.
- `database/core_financiero_postgresql`: DDL/DML de `bd_core_mobile`.

La app Flutter usa el backend FastAPI por defecto mediante `DATA_SOURCE=api`.

## Base De Datos

Base principal:

```text
bd_core_mobile
```

Usuario local usado:

```text
postgres / jcelis
```

`bd_appmovil_fventas` queda solo como referencia historica local; las apps ya no la usan como camino de ejecucion.

## Backend

Levantar FastAPI:

```bash
cd backend/core_mobile_fastapi
.venv/bin/uvicorn main:app --host 127.0.0.1 --port 8003
```

Verificacion:

```bash
curl http://127.0.0.1:8003/
```

Docs:

```text
http://127.0.0.1:8003/docs
```

Usuarios demo:

- Asesor: `0001` / `1234`
- Cliente: `40000001` / `1234`

## Ejecutar En Navegador

Iniciar las aplicaciones Flutter una por una. Aunque cada comando permanezca
abierto en su propia terminal, hay que esperar a que una app cargue antes de
ejecutar la siguiente para evitar escrituras simultaneas en `build/`.

App Clientes:

```bash
/Users/cc/Developer/flutter/bin/flutter run -d chrome \
  -t lib/main_clientes.dart \
  --dart-define=DATA_SOURCE=api \
  --dart-define=API_BASE_URL=http://127.0.0.1:8003
```

App Fuerza de Ventas:

```bash
/Users/cc/Developer/flutter/bin/flutter run -d chrome \
  -t lib/main_ventas.dart \
  --dart-define=DATA_SOURCE=api \
  --dart-define=API_BASE_URL=http://127.0.0.1:8003
```

Frontend Web Administrativo:

```bash
/Users/cc/Developer/flutter/bin/flutter run -d chrome \
  -t lib/main_admin.dart \
  --dart-define=API_BASE_URL=http://127.0.0.1:8003
```

Acceso web supervisor:

```text
0001 / 1234
```

## Verificacion

```bash
/Users/cc/Developer/flutter/bin/flutter analyze
/Users/cc/Developer/flutter/bin/flutter test
```

## Flujo End-To-End Local

1. Iniciar backend FastAPI.
2. Entrar a App Clientes con `40000001 / 1234`.
3. Crear una solicitud desde la pestaña `Prestamo`.
4. Entrar a App Ventas con el vendedor asignado y pulsar `Completar`.
5. Entrar al Frontend Web con supervisor `0001 / 1234`.
6. Aprobar o rechazar el expediente.
7. Al aprobar, el backend genera credito, cronograma, movimiento de desembolso y notificaciones.
8. Refrescar App Clientes para ver el nuevo producto y saldo.

La asignacion de vendedor usa balanceo por cantidad de solicitudes activas.

En este entorno, `bd_core_financiero` contiene un esquema minimo local con `dcliente` y `dsolicitud`, porque no se entrego un schema completo del core financiero.
