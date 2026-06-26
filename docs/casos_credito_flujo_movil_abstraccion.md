# Abstraccion de 30 casos de credito empresarial - flujo movil

Fuente: `/Users/cc/Downloads/ENUNCIADOS_30_CASOS_CREDITO_FLUJO_MOVIL (1) (1).pdf`.

Este documento abstrae los 30 casos del PDF en campos cargables a la base `bd_core_mobile`. El PDF trae cronogramas abreviados (cuotas 1, 2, 3, puntos suspensivos y ultima cuota), por lo que el cronograma completo debe recalcularse con amortizacion francesa usando `monto_aprobado`, `plazo_meses`, `tea_referencial` y dia de pago.

## Verificacion de extraccion

- Paginas del PDF verificadas con `pdfinfo`: 21.
- Casos detectados por encabezado `Caso N`: 30, consecutivos del 1 al 30, sin faltantes.
- Resumen de decisiones validado contra el PDF: 24 aprobados/desembolsados sin condicion, 3 condicionados con monto reducido y 3 rechazados. Operativamente, 27 casos generan credito y cronograma.
- Campos parseados sin errores en los 30 casos: solicitante, DNI, telefono, negocio, solicitud, visita, pre-evaluacion, buro, decision y desembolso cuando aplica.
- Revision visual realizada sobre paginas renderizadas 2, 18 y 21 para contrastar: caso aprobado inicial, caso condicionado y cierre con rechazos/resumen.

## Reglas comunes

- Producto: Credito Empresarial - Microempresa.
- Canal inicial de la solicitud: `cliente`.
- Estado inicial de solicitud: `enviado`.
- Tipo de gestion en cartera: `NUEVA_SOLICITUD`.
- Resultado de visita: `visitado`.
- Moneda: `PEN`.
- Tipo de cuota: `mensual`.
- Documentos esperados para cada caso: DNI anverso, DNI reverso, sustento de negocio, foto de negocio y foto de visita.
- Para casos aprobados o condicionados, el estado final operativo queda en `desembolsado` y se crea credito + cronograma.
- Para casos rechazados, no se crea credito ni cronograma; se registra `motivo_rechazo` y estado final `rechazado`.

## Tabla maestra

| Caso | Cliente | DNI | Negocio | Distrito | Ingreso | Gasto | Solicitado | Plazo | TEA | Garantia | Pre-eval | Buro | Decision | Aprobado | Cuota | Estado final |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Anaximandro Quispe | 40118120 | Bodega - Bodega Don Anaxi | El Tambo | S/ 2,200.00 | S/ 900.00 | S/ 1,000.00 | 12 meses | 43.92% | sin garantia | APTO (85) | NORMAL / 1 ent. / S/ 4,500.00 / 0 dias | aprobado | S/ 1,000.00 | S/ 100.95 | desembolsado |
| 2 | Eulalia Mamani | 41223341 | Restaurante - Picanteria La Eulalia | Chilca | S/ 3,000.00 | S/ 1,400.00 | S/ 3,000.00 | 12 meses | 40.92% | sin garantia | APTO (85) | NORMAL / 2 ent. / S/ 12,000.00 / 0 dias | aprobado | S/ 3,000.00 | S/ 299.59 | desembolsado |
| 3 | Teofilo Huaman | 42330336 | Carpinteria - Maderas Huaman | Pilcomayo | S/ 4,200.00 | S/ 1,800.00 | S/ 5,000.00 | 18 meses | 43.92% | sin garantia | APTO (85) | NORMAL / 1 ent. / S/ 6,000.00 / 0 dias | aprobado | S/ 5,000.00 | S/ 366.02 | desembolsado |
| 4 | Casandra Flores | 43440349 | Abarrotes - Distribuidora Casandra | Huancayo | S/ 7,000.00 | S/ 2,600.00 | S/ 8,000.00 | 6 meses | 43.92% | sin garantia | APTO (85) | NORMAL / 2 ent. / S/ 14,000.00 / 0 dias | aprobado | S/ 8,000.00 | S/ 1,480.73 | desembolsado |
| 5 | Demostenes Rojas | 40556071 | Ferreteria - Ferreteria El Constructor | San Agustin de Cajas | S/ 5,200.00 | S/ 2,100.00 | S/ 10,000.00 | 12 meses | 43.92% | hipotecaria | APTO (85) | NORMAL / 2 ent. / S/ 12,000.00 / 0 dias | aprobado | S/ 10,000.00 | S/ 1,009.46 | desembolsado |
| 6 | Hipatia Condori | 41669066 | Textil - Confecciones Hipatia | El Tambo | S/ 6,800.00 | S/ 2,900.00 | S/ 12,000.00 | 24 meses | 40.92% | hipotecaria | APTO (85) | NORMAL / 1 ent. / S/ 6,000.00 / 0 dias | aprobado | S/ 12,000.00 | S/ 700.94 | desembolsado |
| 7 | Anibal Vargas | 43773379 | Transporte - Transportes Anibal | Concepcion | S/ 9,500.00 | S/ 4,200.00 | S/ 15,000.00 | 18 meses | 43.92% | vehicular | APTO (85) | NORMAL / 2 ent. / S/ 14,000.00 / 0 dias | aprobado | S/ 15,000.00 | S/ 1,098.07 | desembolsado |
| 8 | Penelope Apaza | 40886086 | Avicola - Granja Penelope | Sapallanga | S/ 8,800.00 | S/ 3,600.00 | S/ 18,000.00 | 24 meses | 43.92% | hipotecaria | APTO (85) | NORMAL / 1 ent. / S/ 6,000.00 / 0 dias | aprobado | S/ 18,000.00 | S/ 1,072.10 | desembolsado |
| 9 | Heraclito Ccahua | 41990091 | Comercio - Importaciones Heraclito | Huancayo | S/ 12,000.00 | S/ 5,000.00 | S/ 20,000.00 | 36 meses | 43.92% | hipotecaria | APTO (85) | NORMAL / 2 ent. / S/ 12,000.00 / 0 dias | aprobado | S/ 20,000.00 | S/ 927.12 | desembolsado |
| 10 | Cleopatra Soto | 43003039 | Farmacia - Botica Cleopatra | Chupaca | S/ 11,000.00 | S/ 4,400.00 | S/ 25,000.00 | 24 meses | 40.92% | hipotecaria | APTO (85) | NORMAL / 2 ent. / S/ 14,000.00 / 0 dias | aprobado | S/ 25,000.00 | S/ 1,460.29 | desembolsado |
| 11 | Esquilo Ramos | 40110010 | Bodega - Minimarket Esquilo | Huayucachi | S/ 1,900.00 | S/ 800.00 | S/ 2,000.00 | 12 meses | 43.92% | sin garantia | APTO (85) | NORMAL / 1 ent. / S/ 4,500.00 / 0 dias | aprobado | S/ 2,000.00 | S/ 201.89 | desembolsado |
| 12 | Ariadna Quispe | 41226021 | Peluqueria - Estilos Ariadna | El Tambo | S/ 3,300.00 | S/ 1,300.00 | S/ 4,000.00 | 18 meses | 43.92% | sin garantia | APTO (85) | NORMAL / 2 ent. / S/ 12,000.00 / 0 dias | aprobado | S/ 4,000.00 | S/ 292.82 | desembolsado |
| 13 | Sofocles Huanca | 43336033 | Panaderia - Panaderia Sofocles | Sicaya | S/ 5,600.00 | S/ 2,300.00 | S/ 6,000.00 | 12 meses | 40.92% | sin garantia | APTO (85) | NORMAL / 0 ent. / S/ 0.00 / 0 dias | aprobado | S/ 6,000.00 | S/ 599.17 | desembolsado |
| 14 | Casiopea Torres | 40550055 | Mecanica - Taller Casiopea | Pilcomayo | S/ 7,400.00 | S/ 3,000.00 | S/ 7,500.00 | 6 meses | 43.92% | sin garantia | APTO (85) | DEFICIENTE / 2 ent. / S/ 16,000.00 / 45 dias | aprobado | S/ 7,500.00 | S/ 1,388.18 | desembolsado |
| 15 | Aristofanes Cruz | 41669166 | Agropecuario - Insumos Aristofanes | Orcotuna | S/ 8,200.00 | S/ 3,300.00 | S/ 9,000.00 | 24 meses | 43.92% | hipotecaria | APTO (85) | NORMAL / 1 ent. / S/ 6,000.00 / 0 dias | aprobado | S/ 9,000.00 | S/ 536.05 | desembolsado |
| 16 | Calipso Mendoza | 43880088 | Calzado - Calzados Calipso | Huancayo | S/ 7,900.00 | S/ 3,100.00 | S/ 11,000.00 | 18 meses | 40.92% | hipotecaria | APTO (85) | CPP / 1 ent. / S/ 9,000.00 / 20 dias | aprobado | S/ 11,000.00 | S/ 793.03 | desembolsado |
| 17 | Demetrio Quispe | 40119019 | Comercio - Mayorista Demetrio | Jauja | S/ 11,500.00 | S/ 4,700.00 | S/ 13,500.00 | 12 meses | 43.92% | hipotecaria | APTO (85) | NORMAL / 2 ent. / S/ 14,000.00 / 0 dias | aprobado | S/ 13,500.00 | S/ 1,362.77 | desembolsado |
| 18 | Antigona Flores | 41226126 | Restaurante - Recreo Antigona | Concepcion | S/ 9,200.00 | S/ 3,900.00 | S/ 16,000.00 | 36 meses | 43.92% | hipotecaria | APTO (85) | NORMAL / 1 ent. / S/ 6,000.00 / 0 dias | aprobado | S/ 16,000.00 | S/ 741.70 | desembolsado |
| 19 | Pitagoras Rojas | 43339033 | Ferreteria - Ferreteria Pitagoras | El Tambo | S/ 13,000.00 | S/ 5,200.00 | S/ 17,000.00 | 24 meses | 40.92% | hipotecaria | APTO (85) | NORMAL / 0 ent. / S/ 0.00 / 0 dias | aprobado | S/ 17,000.00 | S/ 993.00 | desembolsado |
| 20 | Berenice Apaza | 40556056 | Textil - Tejidos Berenice | San Jeronimo de Tunan | S/ 8,600.00 | S/ 3,500.00 | S/ 19,000.00 | 18 meses | 43.92% | hipotecaria | APTO (85) | NORMAL / 1 ent. / S/ 6,000.00 / 0 dias | aprobado | S/ 19,000.00 | S/ 1,390.89 | desembolsado |
| 21 | Anaxagoras Huaman | 43889089 | Transporte - Carga Anaxagoras | Huancayo | S/ 14,000.00 | S/ 5,800.00 | S/ 22,000.00 | 36 meses | 43.92% | vehicular | APTO (85) | NORMAL / 2 ent. / S/ 14,000.00 / 0 dias | aprobado | S/ 22,000.00 | S/ 1,019.83 | desembolsado |
| 22 | Climene Vargas | 41003001 | Avicola - Avicola Climene | Sapallanga | S/ 13,500.00 | S/ 5,500.00 | S/ 24,000.00 | 24 meses | 40.92% | hipotecaria | APTO (85) | NORMAL / 2 ent. / S/ 12,000.00 / 0 dias | aprobado | S/ 24,000.00 | S/ 1,401.88 | desembolsado |
| 23 | Epaminondas Soto | 40115011 | Bodega - Bodega Epaminondas | Pucara | S/ 2,600.00 | S/ 1,000.00 | S/ 1,500.00 | 6 meses | 43.92% | sin garantia | APTO (85) | NORMAL / 2 ent. / S/ 12,000.00 / 0 dias | aprobado | S/ 1,500.00 | S/ 277.64 | desembolsado |
| 24 | Lisistrata Ramos | 41336036 | Comercio - Variedades Lisistrata | Huancayo | S/ 4,100.00 | S/ 1,700.00 | S/ 3,500.00 | 12 meses | 43.92% | sin garantia | APTO (85) | NORMAL / 1 ent. / S/ 6,000.00 / 0 dias | aprobado | S/ 3,500.00 | S/ 353.31 | desembolsado |
| 25 | Filoctetes Cruz | 41552052 | Restaurante - Cevicheria Filoctetes | Chilca | S/ 3,800.00 | S/ 2,200.00 | S/ 11,000.00 | 18 meses | 40.92% | sin garantia | APTO (85) | CPP / 2 ent. / S/ 18,000.00 / 15 dias | condicionado | S/ 7,000.00 | S/ 504.66 | desembolsado |
| 26 | Calirroe Mendoza | 41888088 | Calzado - Calzados Calirroe | El Tambo | S/ 5,000.00 | S/ 2,600.00 | S/ 16,000.00 | 24 meses | 43.92% | hipotecaria | APTO (85) | CPP / 1 ent. / S/ 9,000.00 / 20 dias | condicionado | S/ 10,000.00 | S/ 595.61 | desembolsado |
| 27 | Tucidides Quispe | 42220022 | Ferreteria - Ferreteria Tucidides | Concepcion | S/ 6,200.00 | S/ 2,900.00 | S/ 20,000.00 | 24 meses | 40.92% | hipotecaria | APTO (85) | CPP / 2 ent. / S/ 18,000.00 / 15 dias | condicionado | S/ 14,000.00 | S/ 817.76 | desembolsado |
| 28 | Aquiles Mamani | 43337037 | Comercio - Comercial Aquiles | Huancayo | S/ 9,000.00 | S/ 3,600.00 | S/ 15,000.00 | 24 meses | 43.92% | hipotecaria | APTO (85) | PERDIDA / 4 ent. / S/ 40,000.00 / 210 dias | rechazado | - | - | rechazado |
| 29 | Medea Apaza | 41884084 | Bodega - Bodega Medea | Pilcomayo | S/ 1,800.00 | S/ 1,100.00 | S/ 14,000.00 | 18 meses | 43.92% | sin garantia | REVISAR (60) | DUDOSO / 3 ent. / S/ 25,000.00 / 95 dias | rechazado | - | - | rechazado |
| 30 | Esquines Rojas | 43334034 | Transporte - Fletes Esquines | Jauja | S/ 7,000.00 | S/ 3,200.00 | S/ 30,000.00 | 24 meses | 43.92% | vehicular | APTO (85) | DUDOSO / 3 ent. / S/ 25,000.00 / 95 dias | rechazado | - | - | rechazado |

## Fichas por caso

### Caso 01 - Anaximandro Quispe

- Cliente: DNI `40118120`, telefono `964110201`.
- Negocio: Bodega `Bodega Don Anaxi`, distrito El Tambo, antiguedad 48 meses.
- Flujo financiero: ingreso mensual S/ 2,200.00; gasto mensual S/ 900.00.
- Solicitud: monto S/ 1,000.00; plazo 12 meses; TEA 43.92%; sin seguro de desgravamen; garantia `sin garantia`; destino: Capital de trabajo: compra de mercaderia; cuota de referencia S/ 100.95.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `normal`, visita `visitado`, coordenadas lat -12.0581, lng -75.2027.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 1 entidad(es), deuda total S/ 4,500.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 1,000.00.
- Desembolso: 02/02/2026 con pago mensual el dia 03; cuota mensual final S/ 100.95.

### Caso 02 - Eulalia Mamani

- Cliente: DNI `41223341`, telefono `964110202`.
- Negocio: Restaurante `Picanteria La Eulalia`, distrito Chilca, antiguedad 36 meses.
- Flujo financiero: ingreso mensual S/ 3,000.00; gasto mensual S/ 1,400.00.
- Solicitud: monto S/ 3,000.00; plazo 12 meses; TEA 40.92%; con seguro de desgravamen; garantia `sin garantia`; destino: Compra de cocina industrial; cuota de referencia S/ 299.59.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `media`, visita `visitado`, coordenadas lat -12.0921, lng -75.2105.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 2 entidad(es), deuda total S/ 12,000.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 3,000.00.
- Desembolso: 05/02/2026 con pago mensual el dia 05; cuota mensual final S/ 299.59.

### Caso 03 - Teofilo Huaman

- Cliente: DNI `42330336`, telefono `964110203`.
- Negocio: Carpinteria `Maderas Huaman`, distrito Pilcomayo, antiguedad 60 meses.
- Flujo financiero: ingreso mensual S/ 4,200.00; gasto mensual S/ 1,800.00.
- Solicitud: monto S/ 5,000.00; plazo 18 meses; TEA 43.92%; sin seguro de desgravamen; garantia `sin garantia`; destino: Maquinaria: sierra y cepillo; cuota de referencia S/ 366.02.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `media`, visita `visitado`, coordenadas lat -12.0496, lng -75.2486.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 1 entidad(es), deuda total S/ 6,000.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 5,000.00.
- Desembolso: 10/02/2026 con pago mensual el dia 10; cuota mensual final S/ 366.02.

### Caso 04 - Casandra Flores

- Cliente: DNI `43440349`, telefono `964110204`.
- Negocio: Abarrotes `Distribuidora Casandra`, distrito Huancayo, antiguedad 84 meses.
- Flujo financiero: ingreso mensual S/ 7,000.00; gasto mensual S/ 2,600.00.
- Solicitud: monto S/ 8,000.00; plazo 6 meses; TEA 43.92%; sin seguro de desgravamen; garantia `sin garantia`; destino: Reposicion de stock por campana; cuota de referencia S/ 1,480.73.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `alta`, visita `visitado`, coordenadas lat -12.0651, lng -75.2049.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 2 entidad(es), deuda total S/ 14,000.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 8,000.00.
- Desembolso: 15/02/2026 con pago mensual el dia 15; cuota mensual final S/ 1,480.73.

### Caso 05 - Demostenes Rojas

- Cliente: DNI `40556071`, telefono `964110205`.
- Negocio: Ferreteria `Ferreteria El Constructor`, distrito San Agustin de Cajas, antiguedad 30 meses.
- Flujo financiero: ingreso mensual S/ 5,200.00; gasto mensual S/ 2,100.00.
- Solicitud: monto S/ 10,000.00; plazo 12 meses; TEA 43.92%; sin seguro de desgravamen; garantia `hipotecaria`; destino: Ampliacion de local; cuota de referencia S/ 1,009.46.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `alta`, visita `visitado`, coordenadas lat -12.0188, lng -75.2271.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 2 entidad(es), deuda total S/ 12,000.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 10,000.00.
- Desembolso: 01/03/2026 con pago mensual el dia 03; cuota mensual final S/ 1,009.46.

### Caso 06 - Hipatia Condori

- Cliente: DNI `41669066`, telefono `964110206`.
- Negocio: Textil `Confecciones Hipatia`, distrito El Tambo, antiguedad 54 meses.
- Flujo financiero: ingreso mensual S/ 6,800.00; gasto mensual S/ 2,900.00.
- Solicitud: monto S/ 12,000.00; plazo 24 meses; TEA 40.92%; con seguro de desgravamen; garantia `hipotecaria`; destino: Compra de maquinas remalladoras; cuota de referencia S/ 700.94.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `media`, visita `visitado`, coordenadas lat -12.0612, lng -75.2118.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 1 entidad(es), deuda total S/ 6,000.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 12,000.00.
- Desembolso: 05/03/2026 con pago mensual el dia 05; cuota mensual final S/ 700.94.

### Caso 07 - Anibal Vargas

- Cliente: DNI `43773379`, telefono `964110207`.
- Negocio: Transporte `Transportes Anibal`, distrito Concepcion, antiguedad 42 meses.
- Flujo financiero: ingreso mensual S/ 9,500.00; gasto mensual S/ 4,200.00.
- Solicitud: monto S/ 15,000.00; plazo 18 meses; TEA 43.92%; sin seguro de desgravamen; garantia `vehicular`; destino: Cuota inicial de vehiculo de carga; cuota de referencia S/ 1,098.07.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `alta`, visita `visitado`, coordenadas lat -11.9182, lng -75.3142.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 2 entidad(es), deuda total S/ 14,000.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 15,000.00.
- Desembolso: 10/03/2026 con pago mensual el dia 10; cuota mensual final S/ 1,098.07.

### Caso 08 - Penelope Apaza

- Cliente: DNI `40886086`, telefono `964110208`.
- Negocio: Avicola `Granja Penelope`, distrito Sapallanga, antiguedad 72 meses.
- Flujo financiero: ingreso mensual S/ 8,800.00; gasto mensual S/ 3,600.00.
- Solicitud: monto S/ 18,000.00; plazo 24 meses; TEA 43.92%; sin seguro de desgravamen; garantia `hipotecaria`; destino: Ampliacion de galpon; cuota de referencia S/ 1,072.10.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `alta`, visita `visitado`, coordenadas lat -12.1581, lng -75.1762.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 1 entidad(es), deuda total S/ 6,000.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 18,000.00.
- Desembolso: 15/03/2026 con pago mensual el dia 15; cuota mensual final S/ 1,072.10.

### Caso 09 - Heraclito Ccahua

- Cliente: DNI `41990091`, telefono `964110209`.
- Negocio: Comercio `Importaciones Heraclito`, distrito Huancayo, antiguedad 96 meses.
- Flujo financiero: ingreso mensual S/ 12,000.00; gasto mensual S/ 5,000.00.
- Solicitud: monto S/ 20,000.00; plazo 36 meses; TEA 43.92%; sin seguro de desgravamen; garantia `hipotecaria`; destino: Capital para nueva sucursal; cuota de referencia S/ 927.12.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `alta`, visita `visitado`, coordenadas lat -12.0668, lng -75.2103.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 2 entidad(es), deuda total S/ 12,000.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 20,000.00.
- Desembolso: 02/04/2026 con pago mensual el dia 03; cuota mensual final S/ 927.12.

### Caso 10 - Cleopatra Soto

- Cliente: DNI `43003039`, telefono `964110210`.
- Negocio: Farmacia `Botica Cleopatra`, distrito Chupaca, antiguedad 66 meses.
- Flujo financiero: ingreso mensual S/ 11,000.00; gasto mensual S/ 4,400.00.
- Solicitud: monto S/ 25,000.00; plazo 24 meses; TEA 40.92%; con seguro de desgravamen; garantia `hipotecaria`; destino: Equipamiento y stock farmaceutico; cuota de referencia S/ 1,460.29.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `alta`, visita `visitado`, coordenadas lat -12.056, lng -75.287.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 2 entidad(es), deuda total S/ 14,000.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 25,000.00.
- Desembolso: 05/04/2026 con pago mensual el dia 05; cuota mensual final S/ 1,460.29.

### Caso 11 - Esquilo Ramos

- Cliente: DNI `40110010`, telefono `964110211`.
- Negocio: Bodega `Minimarket Esquilo`, distrito Huayucachi, antiguedad 24 meses.
- Flujo financiero: ingreso mensual S/ 1,900.00; gasto mensual S/ 800.00.
- Solicitud: monto S/ 2,000.00; plazo 12 meses; TEA 43.92%; sin seguro de desgravamen; garantia `sin garantia`; destino: Compra de congeladora; cuota de referencia S/ 201.89.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `normal`, visita `visitado`, coordenadas lat -12.1339, lng -75.209.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 1 entidad(es), deuda total S/ 4,500.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 2,000.00.
- Desembolso: 10/04/2026 con pago mensual el dia 10; cuota mensual final S/ 201.89.

### Caso 12 - Ariadna Quispe

- Cliente: DNI `41226021`, telefono `964110212`.
- Negocio: Peluqueria `Estilos Ariadna`, distrito El Tambo, antiguedad 40 meses.
- Flujo financiero: ingreso mensual S/ 3,300.00; gasto mensual S/ 1,300.00.
- Solicitud: monto S/ 4,000.00; plazo 18 meses; TEA 43.92%; sin seguro de desgravamen; garantia `sin garantia`; destino: Mobiliario y equipos de salon; cuota de referencia S/ 292.82.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `media`, visita `visitado`, coordenadas lat -12.0573, lng -75.2161.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 2 entidad(es), deuda total S/ 12,000.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 4,000.00.
- Desembolso: 15/04/2026 con pago mensual el dia 15; cuota mensual final S/ 292.82.

### Caso 13 - Sofocles Huanca

- Cliente: DNI `43336033`, telefono `964110213`.
- Negocio: Panaderia `Panaderia Sofocles`, distrito Sicaya, antiguedad 58 meses.
- Flujo financiero: ingreso mensual S/ 5,600.00; gasto mensual S/ 2,300.00.
- Solicitud: monto S/ 6,000.00; plazo 12 meses; TEA 40.92%; con seguro de desgravamen; garantia `sin garantia`; destino: Horno rotativo; cuota de referencia S/ 599.17.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `media`, visita `visitado`, coordenadas lat -12.0228, lng -75.3134.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 0 entidad(es), deuda total S/ 0.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 6,000.00.
- Desembolso: 02/05/2026 con pago mensual el dia 03; cuota mensual final S/ 599.17.

### Caso 14 - Casiopea Torres

- Cliente: DNI `40550055`, telefono `964110214`.
- Negocio: Mecanica `Taller Casiopea`, distrito Pilcomayo, antiguedad 50 meses.
- Flujo financiero: ingreso mensual S/ 7,400.00; gasto mensual S/ 3,000.00.
- Solicitud: monto S/ 7,500.00; plazo 6 meses; TEA 43.92%; sin seguro de desgravamen; garantia `sin garantia`; destino: Herramienta neumatica; cuota de referencia S/ 1,388.18.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `media`, visita `visitado`, coordenadas lat -12.0512, lng -75.2451.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS DEFICIENTE, 2 entidad(es), deuda total S/ 16,000.00, mayor mora 45 dias.
- Decision: `aprobado`; monto aprobado S/ 7,500.00.
- Desembolso: 05/05/2026 con pago mensual el dia 05; cuota mensual final S/ 1,388.18.

### Caso 15 - Aristofanes Cruz

- Cliente: DNI `41669166`, telefono `964110215`.
- Negocio: Agropecuario `Insumos Aristofanes`, distrito Orcotuna, antiguedad 78 meses.
- Flujo financiero: ingreso mensual S/ 8,200.00; gasto mensual S/ 3,300.00.
- Solicitud: monto S/ 9,000.00; plazo 24 meses; TEA 43.92%; sin seguro de desgravamen; garantia `hipotecaria`; destino: Capital para campana agricola; cuota de referencia S/ 536.05.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `alta`, visita `visitado`, coordenadas lat -11.976, lng -75.3361.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 1 entidad(es), deuda total S/ 6,000.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 9,000.00.
- Desembolso: 10/05/2026 con pago mensual el dia 10; cuota mensual final S/ 536.05.

### Caso 16 - Calipso Mendoza

- Cliente: DNI `43880088`, telefono `964110216`.
- Negocio: Calzado `Calzados Calipso`, distrito Huancayo, antiguedad 62 meses.
- Flujo financiero: ingreso mensual S/ 7,900.00; gasto mensual S/ 3,100.00.
- Solicitud: monto S/ 11,000.00; plazo 18 meses; TEA 40.92%; con seguro de desgravamen; garantia `hipotecaria`; destino: Compra de cuero y maquinaria; cuota de referencia S/ 793.03.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `media`, visita `visitado`, coordenadas lat -12.0689, lng -75.2055.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS CPP, 1 entidad(es), deuda total S/ 9,000.00, mayor mora 20 dias.
- Decision: `aprobado`; monto aprobado S/ 11,000.00.
- Desembolso: 15/05/2026 con pago mensual el dia 15; cuota mensual final S/ 793.03.

### Caso 17 - Demetrio Quispe

- Cliente: DNI `40119019`, telefono `964110217`.
- Negocio: Comercio `Mayorista Demetrio`, distrito Jauja, antiguedad 90 meses.
- Flujo financiero: ingreso mensual S/ 11,500.00; gasto mensual S/ 4,700.00.
- Solicitud: monto S/ 13,500.00; plazo 12 meses; TEA 43.92%; sin seguro de desgravamen; garantia `hipotecaria`; destino: Reposicion de inventario mayorista; cuota de referencia S/ 1,362.77.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `alta`, visita `visitado`, coordenadas lat -11.7752, lng -75.4995.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 2 entidad(es), deuda total S/ 14,000.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 13,500.00.
- Desembolso: 02/06/2026 con pago mensual el dia 03; cuota mensual final S/ 1,362.77.

### Caso 18 - Antigona Flores

- Cliente: DNI `41226126`, telefono `964110218`.
- Negocio: Restaurante `Recreo Antigona`, distrito Concepcion, antiguedad 70 meses.
- Flujo financiero: ingreso mensual S/ 9,200.00; gasto mensual S/ 3,900.00.
- Solicitud: monto S/ 16,000.00; plazo 36 meses; TEA 43.92%; sin seguro de desgravamen; garantia `hipotecaria`; destino: Ampliacion y remodelacion; cuota de referencia S/ 741.70.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `alta`, visita `visitado`, coordenadas lat -11.9201, lng -75.311.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 1 entidad(es), deuda total S/ 6,000.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 16,000.00.
- Desembolso: 05/06/2026 con pago mensual el dia 05; cuota mensual final S/ 741.70.

### Caso 19 - Pitagoras Rojas

- Cliente: DNI `43339033`, telefono `964110219`.
- Negocio: Ferreteria `Ferreteria Pitagoras`, distrito El Tambo, antiguedad 100 meses.
- Flujo financiero: ingreso mensual S/ 13,000.00; gasto mensual S/ 5,200.00.
- Solicitud: monto S/ 17,000.00; plazo 24 meses; TEA 40.92%; con seguro de desgravamen; garantia `hipotecaria`; destino: Compra de stock estructural; cuota de referencia S/ 993.00.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `alta`, visita `visitado`, coordenadas lat -12.0599, lng -75.2143.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 0 entidad(es), deuda total S/ 0.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 17,000.00.
- Desembolso: 10/06/2026 con pago mensual el dia 10; cuota mensual final S/ 993.00.

### Caso 20 - Berenice Apaza

- Cliente: DNI `40556056`, telefono `964110220`.
- Negocio: Textil `Tejidos Berenice`, distrito San Jeronimo de Tunan, antiguedad 46 meses.
- Flujo financiero: ingreso mensual S/ 8,600.00; gasto mensual S/ 3,500.00.
- Solicitud: monto S/ 19,000.00; plazo 18 meses; TEA 43.92%; sin seguro de desgravamen; garantia `hipotecaria`; destino: Maquinaria de tejido plano; cuota de referencia S/ 1,390.89.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `alta`, visita `visitado`, coordenadas lat -11.9871, lng -75.2899.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 1 entidad(es), deuda total S/ 6,000.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 19,000.00.
- Desembolso: 15/06/2026 con pago mensual el dia 15; cuota mensual final S/ 1,390.89.

### Caso 21 - Anaxagoras Huaman

- Cliente: DNI `43889089`, telefono `964110221`.
- Negocio: Transporte `Carga Anaxagoras`, distrito Huancayo, antiguedad 84 meses.
- Flujo financiero: ingreso mensual S/ 14,000.00; gasto mensual S/ 5,800.00.
- Solicitud: monto S/ 22,000.00; plazo 36 meses; TEA 43.92%; sin seguro de desgravamen; garantia `vehicular`; destino: Cuota inicial de camion; cuota de referencia S/ 1,019.83.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `alta`, visita `visitado`, coordenadas lat -12.0644, lng -75.2088.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 2 entidad(es), deuda total S/ 14,000.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 22,000.00.
- Desembolso: 02/07/2026 con pago mensual el dia 03; cuota mensual final S/ 1,019.83.

### Caso 22 - Climene Vargas

- Cliente: DNI `41003001`, telefono `964110222`.
- Negocio: Avicola `Avicola Climene`, distrito Sapallanga, antiguedad 76 meses.
- Flujo financiero: ingreso mensual S/ 13,500.00; gasto mensual S/ 5,500.00.
- Solicitud: monto S/ 24,000.00; plazo 24 meses; TEA 40.92%; con seguro de desgravamen; garantia `hipotecaria`; destino: Equipamiento de planta; cuota de referencia S/ 1,401.88.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `alta`, visita `visitado`, coordenadas lat -12.156, lng -75.179.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 2 entidad(es), deuda total S/ 12,000.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 24,000.00.
- Desembolso: 05/07/2026 con pago mensual el dia 05; cuota mensual final S/ 1,401.88.

### Caso 23 - Epaminondas Soto

- Cliente: DNI `40115011`, telefono `964110223`.
- Negocio: Bodega `Bodega Epaminondas`, distrito Pucara, antiguedad 28 meses.
- Flujo financiero: ingreso mensual S/ 2,600.00; gasto mensual S/ 1,000.00.
- Solicitud: monto S/ 1,500.00; plazo 6 meses; TEA 43.92%; sin seguro de desgravamen; garantia `sin garantia`; destino: Compra de vitrinas; cuota de referencia S/ 277.64.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `normal`, visita `visitado`, coordenadas lat -12.1701, lng -75.1611.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 2 entidad(es), deuda total S/ 12,000.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 1,500.00.
- Desembolso: 10/07/2026 con pago mensual el dia 10; cuota mensual final S/ 277.64.

### Caso 24 - Lisistrata Ramos

- Cliente: DNI `41336036`, telefono `964110224`.
- Negocio: Comercio `Variedades Lisistrata`, distrito Huancayo, antiguedad 52 meses.
- Flujo financiero: ingreso mensual S/ 4,100.00; gasto mensual S/ 1,700.00.
- Solicitud: monto S/ 3,500.00; plazo 12 meses; TEA 43.92%; sin seguro de desgravamen; garantia `sin garantia`; destino: Capital de trabajo; cuota de referencia S/ 353.31.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `media`, visita `visitado`, coordenadas lat -12.0633, lng -75.2071.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS NORMAL, 1 entidad(es), deuda total S/ 6,000.00, mayor mora 0 dias.
- Decision: `aprobado`; monto aprobado S/ 3,500.00.
- Desembolso: 15/07/2026 con pago mensual el dia 15; cuota mensual final S/ 353.31.

### Caso 25 - Filoctetes Cruz

- Cliente: DNI `41552052`, telefono `964110225`.
- Negocio: Restaurante `Cevicheria Filoctetes`, distrito Chilca, antiguedad 18 meses.
- Flujo financiero: ingreso mensual S/ 3,800.00; gasto mensual S/ 2,200.00.
- Solicitud: monto S/ 11,000.00; plazo 18 meses; TEA 40.92%; con seguro de desgravamen; garantia `sin garantia`; destino: Ampliacion de local nuevo; cuota de referencia S/ 793.03.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `media`, visita `visitado`, coordenadas lat -12.093, lng -75.209.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS CPP, 2 entidad(es), deuda total S/ 18,000.00, mayor mora 15 dias.
- Decision: `condicionado`; monto aprobado S/ 7,000.00. Motivo/condicion: Antiguedad del negocio menor a 24 meses y carga de gastos alta: el comite aprueba un monto menor.
- Desembolso: 02/08/2026 con pago mensual el dia 03; cuota mensual final S/ 504.66.

### Caso 26 - Calirroe Mendoza

- Cliente: DNI `41888088`, telefono `964110226`.
- Negocio: Calzado `Calzados Calirroe`, distrito El Tambo, antiguedad 34 meses.
- Flujo financiero: ingreso mensual S/ 5,000.00; gasto mensual S/ 2,600.00.
- Solicitud: monto S/ 16,000.00; plazo 24 meses; TEA 43.92%; sin seguro de desgravamen; garantia `hipotecaria`; destino: Maquinaria de mayor capacidad; cuota de referencia S/ 952.98.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `media`, visita `visitado`, coordenadas lat -12.0588, lng -75.2129.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS CPP, 1 entidad(es), deuda total S/ 9,000.00, mayor mora 20 dias.
- Decision: `condicionado`; monto aprobado S/ 10,000.00. Motivo/condicion: Calificacion CPP con 20 dias de mora reciente: se aprueba monto reducido con seguimiento.
- Desembolso: 05/08/2026 con pago mensual el dia 05; cuota mensual final S/ 595.61.

### Caso 27 - Tucidides Quispe

- Cliente: DNI `42220022`, telefono `964110227`.
- Negocio: Ferreteria `Ferreteria Tucidides`, distrito Concepcion, antiguedad 40 meses.
- Flujo financiero: ingreso mensual S/ 6,200.00; gasto mensual S/ 2,900.00.
- Solicitud: monto S/ 20,000.00; plazo 24 meses; TEA 40.92%; con seguro de desgravamen; garantia `hipotecaria`; destino: Compra de stock y montacarga; cuota de referencia S/ 1,168.23.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `alta`, visita `visitado`, coordenadas lat -11.9176, lng -75.3155.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS CPP, 2 entidad(es), deuda total S/ 18,000.00, mayor mora 15 dias.
- Decision: `condicionado`; monto aprobado S/ 14,000.00. Motivo/condicion: Endeudamiento externo en 2 entidades y relacion monto/ingreso ajustada: el comite condiciona el monto.
- Desembolso: 10/08/2026 con pago mensual el dia 10; cuota mensual final S/ 817.76.

### Caso 28 - Aquiles Mamani

- Cliente: DNI `43337037`, telefono `964110228`.
- Negocio: Comercio `Comercial Aquiles`, distrito Huancayo, antiguedad 60 meses.
- Flujo financiero: ingreso mensual S/ 9,000.00; gasto mensual S/ 3,600.00.
- Solicitud: monto S/ 15,000.00; plazo 24 meses; TEA 43.92%; sin seguro de desgravamen; garantia `hipotecaria`; destino: Capital de trabajo; cuota de referencia S/ 893.42.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `alta`, visita `visitado`, coordenadas lat -12.0657, lng -75.2099.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS PERDIDA, 4 entidad(es), deuda total S/ 40,000.00, mayor mora 210 dias; en lista de inhabilitados.
- Decision: `rechazado`; motivo: Registrado en lista de inhabilitados del sistema financiero; la solicitud se bloquea en la consulta de buro. No se genera cronograma. Registrar el motivo de rechazo y cerrar el expediente en estado rechazado.
- Desembolso: no aplica; no se genera cronograma.

### Caso 29 - Medea Apaza

- Cliente: DNI `41884084`, telefono `964110229`.
- Negocio: Bodega `Bodega Medea`, distrito Pilcomayo, antiguedad 22 meses.
- Flujo financiero: ingreso mensual S/ 1,800.00; gasto mensual S/ 1,100.00.
- Solicitud: monto S/ 14,000.00; plazo 18 meses; TEA 43.92%; sin seguro de desgravamen; garantia `sin garantia`; destino: Compra de camioneta para reparto; cuota de referencia S/ 1,024.87.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `media`, visita `visitado`, coordenadas lat -12.0489, lng -75.247.
- Pre-evaluacion y buro: REVISAR con puntaje 60; SBS DUDOSO, 3 entidad(es), deuda total S/ 25,000.00, mayor mora 95 dias.
- Decision: `rechazado`; motivo: El monto solicitado supera ampliamente la capacidad de pago estimada (pre-evaluacion NO_PROCEDE). No se genera cronograma. Registrar el motivo de rechazo y cerrar el expediente en estado rechazado.
- Desembolso: no aplica; no se genera cronograma.

### Caso 30 - Esquines Rojas

- Cliente: DNI `43334034`, telefono `964110230`.
- Negocio: Transporte `Fletes Esquines`, distrito Jauja, antiguedad 30 meses.
- Flujo financiero: ingreso mensual S/ 7,000.00; gasto mensual S/ 3,200.00.
- Solicitud: monto S/ 30,000.00; plazo 24 meses; TEA 43.92%; sin seguro de desgravamen; garantia `vehicular`; destino: Compra de unidad de transporte; cuota de referencia S/ 1,786.83.
- Asignacion: gestion `NUEVA_SOLICITUD`, prioridad `alta`, visita `visitado`, coordenadas lat -11.774, lng -75.501.
- Pre-evaluacion y buro: APTO con puntaje 85; SBS DUDOSO, 3 entidad(es), deuda total S/ 25,000.00, mayor mora 95 dias.
- Decision: `rechazado`; motivo: Calificacion SBS DUDOSO con 95 dias de mora vigente en 3 entidades: no procede el otorgamiento. No se genera cronograma. Registrar el motivo de rechazo y cerrar el expediente en estado rechazado.
- Desembolso: no aplica; no se genera cronograma.

## Como los agregare correctamente a la base de datos

1. Usar el script idempotente creado: `database/core_financiero_postgresql/08_DML_30_casos_credito_flujo_movil.sql`.
2. Insertar o actualizar los 30 clientes por `numero_documento`, marcandolos como prospectos si no existen en el core actual. Campos destino: `clientes.numero_documento`, `nombres`, `apellidos`, `telefono`, `tipo_negocio`, `nombre_negocio`, `antiguedad_negocio_meses`, `ingresos_estimados`, `lat`, `lng`, `calificacion_sbs` y `es_prospecto`.
3. Crear acceso en `usuarios_cliente` para cada DNI con la clave demo `1234`, solo si no existe. Esto permite registrar/probar cada solicitud desde App Clientes.
4. Asignar cada caso a un asesor existente. La opcion mas limpia es usar `A002`/codigo `0002` como asesor operador demo, o repartir por agencia segun distrito si se quiere simular cartera territorial. En ambos casos se debe tomar `asesor_id` y `agencia_id` desde las tablas existentes, no hardcodear UUIDs.
5. Insertar `solicitudes_credito` con `canal = cliente`, `estado = enviado` para la etapa inicial; si se quiere dejar el flujo ya resuelto para demo, actualizar luego a `desembolsado` en aprobados/condicionados y `rechazado` en rechazados. Los campos principales salen directamente de la tabla maestra: negocio, monto, plazo, garantia, destino, cuota, TEA, lat/lng y montos aprobados.
6. Insertar una consulta en `consultas_buro` por caso con calificacion SBS, entidades, deuda total, dias de mayor mora y bandera `en_lista_negra` para el caso 28.
7. Insertar `solicitudes_decisiones` para conservar la decision del comite: `aprobado`, `condicionado` o `rechazado`. En condicionados, guardar el monto reducido y la condicion adicional; en rechazados, guardar el motivo.
8. Para los 27 casos con desembolso (24 aprobados + 3 condicionados), crear `cr_creditos` con codigo deterministico, por ejemplo `CRED-FM-001` a `CRED-FM-027`, `producto = Credito Empresarial - Microempresa`, monto desembolsado igual al monto aprobado, TEA, plazo y fecha de desembolso.
9. Generar el cronograma completo en `cr_cronograma_pagos` con amortizacion francesa: `TEM = power(1 + TEA/100, 1/12) - 1`, cuota fija redondeada a 2 decimales, fechas por dia de pago indicado y ajuste de saldo a `0.00` en la ultima cuota.
10. Insertar documentos placeholder en `solicitudes_documentos` para los cinco tipos esperados por caso, usando rutas demo estables. Esto deja el expediente completo para UI y pruebas.
11. El script ya esta agregado al orden de ejecucion de `database/core_financiero_postgresql/99_run_all.sql` despues de `07_DML_cuentas_movimientos_demo.sql`; para entonces ya existen tablas base y tabla de decisiones.
12. Verificar con consultas de conteo: 30 solicitudes de estos casos, 27 creditos, suma de 510 cuotas de cronograma, 30 consultas de buro, 30 decisiones y 150 documentos placeholder.

Conteo esperado de cuotas completas: 3 caso(s) de 6 meses, 7 caso(s) de 12 meses, 6 caso(s) de 18 meses, 8 caso(s) de 24 meses, 3 caso(s) de 36 meses. Total = `510` cuotas. Este conteo excluye los 3 rechazados y debe usarse como control final al generar cronogramas.

## Consultas de validacion sugeridas

```sql
SELECT COUNT(*) FROM solicitudes_credito WHERE numero_expediente LIKE 'FM-%';
SELECT estado, COUNT(*) FROM solicitudes_credito WHERE numero_expediente LIKE 'FM-%' GROUP BY estado ORDER BY estado;
SELECT COUNT(*) FROM consultas_buro cb JOIN solicitudes_credito sc ON sc.id = cb.solicitud_id WHERE sc.numero_expediente LIKE 'FM-%';
SELECT COUNT(*) FROM solicitudes_decisiones sd JOIN solicitudes_credito sc ON sc.id = sd.solicitud_id WHERE sc.numero_expediente LIKE 'FM-%';
SELECT COUNT(*) FROM cr_creditos WHERE cod_cuenta_credito LIKE 'CRED-FM-%';
SELECT COUNT(*) FROM cr_cronograma_pagos WHERE cod_cuenta_credito LIKE 'CRED-FM-%';
```
