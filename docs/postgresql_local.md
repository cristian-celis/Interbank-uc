# PostgreSQL local para Interbank UC

## Que instalar en macOS

Para esta entrega conviene usar el instalador oficial de PostgreSQL para macOS,
porque instala el servidor, crea el usuario administrador `postgres` y suele
incluir pgAdmin 4 para ejecutar los scripts del profesor desde una interfaz.

Descarga:

- PostgreSQL macOS: https://www.postgresql.org/download/macosx/
- pgAdmin 4, si tu instalador no lo trae: https://www.pgadmin.org/download/

Durante la instalacion anota la password del usuario `postgres`. En los ejemplos
de esta guia se usa `postgres`, pero puedes poner la password que hayas elegido.

## Base de datos requerida por los scripts

Los scripts compartidos por el profesor estan preparados para la base:

```text
bd_appmovil_fventas
```

Orden de ejecucion:

1. `/Users/cc/Downloads/00_setup_base_local.sql`
2. `/Users/cc/Downloads/01_scoring_tablas_funciones_local.sql`
3. `/Users/cc/Downloads/02_agencias_asesores_local.sql`
4. `/Users/cc/Downloads/03_seed_demo_local.sql`
5. `/Users/cc/Downloads/04_test_scoring_local.sql`

El script `04_test_scoring_local.sql` es de validacion. Si devuelve filas en sus
consultas, la BD quedo lista para la app.

## Configuracion con pgAdmin

1. Abre pgAdmin 4.
2. Conectate al servidor local `PostgreSQL` con la password del usuario
   `postgres`.
3. Clic derecho en `Databases` -> `Create` -> `Database...`.
4. Nombre: `bd_appmovil_fventas`.
5. Owner: `postgres`.
6. Abre `Query Tool` sobre la base `bd_appmovil_fventas`.
7. Abre y ejecuta los cinco scripts en el orden indicado arriba.

## Configuracion por terminal

Si `psql` esta disponible en tu terminal:

```bash
createdb -U postgres bd_appmovil_fventas
psql -U postgres -d bd_appmovil_fventas -f /Users/cc/Downloads/00_setup_base_local.sql
psql -U postgres -d bd_appmovil_fventas -f /Users/cc/Downloads/01_scoring_tablas_funciones_local.sql
psql -U postgres -d bd_appmovil_fventas -f /Users/cc/Downloads/02_agencias_asesores_local.sql
psql -U postgres -d bd_appmovil_fventas -f /Users/cc/Downloads/03_seed_demo_local.sql
psql -U postgres -d bd_appmovil_fventas -f /Users/cc/Downloads/04_test_scoring_local.sql
```

En esta Mac, antes de instalar PostgreSQL, `psql` no esta disponible en PATH.
Despues de instalarlo, si el comando sigue sin aparecer, agrega el binario de
PostgreSQL al PATH o usa pgAdmin.

## Correr la app contra PostgreSQL

La app mantiene mocks por defecto para que los tests no dependan de una BD. Para
activar PostgreSQL local, corre Flutter con `DATA_SOURCE=postgres`.

iOS simulator o macOS local:

```bash
flutter run \
  --dart-define=DATA_SOURCE=postgres \
  --dart-define=PG_HOST=localhost \
  --dart-define=PG_PORT=5432 \
  --dart-define=PG_DATABASE=bd_appmovil_fventas \
  --dart-define=PG_USER=postgres \
  --dart-define=PG_PASSWORD=postgres
```

Android emulator:

```bash
flutter run \
  --dart-define=DATA_SOURCE=postgres \
  --dart-define=PG_HOST=10.0.2.2 \
  --dart-define=PG_PORT=5432 \
  --dart-define=PG_DATABASE=bd_appmovil_fventas \
  --dart-define=PG_USER=postgres \
  --dart-define=PG_PASSWORD=postgres
```

Celular fisico:

```bash
flutter run \
  --dart-define=DATA_SOURCE=postgres \
  --dart-define=PG_HOST=IP_DE_TU_MAC \
  --dart-define=PG_PORT=5432 \
  --dart-define=PG_DATABASE=bd_appmovil_fventas \
  --dart-define=PG_USER=postgres \
  --dart-define=PG_PASSWORD=postgres
```

Para celular fisico, el celular y la Mac deben estar en la misma red Wi-Fi. La
Mac debe permitir conexiones entrantes a PostgreSQL en el puerto `5432`.

## Usuarios demo

Los datos semilla incluyen asesores y clientes. Para probar fuerza de ventas:

```text
jessica.quispe@fieldiq.pe
```

La password ingresada en la app no se valida criptograficamente en el modo local
academico; el login busca el correo en `usuarios_mock`.

## Nota de arquitectura

Esta conexion directa Flutter -> PostgreSQL sirve para demo local y requisito
academico. En produccion, lo correcto seria:

```text
App Flutter -> API backend -> PostgreSQL
```

Una app movil directa a PostgreSQL expone credenciales y depende de la red local.
