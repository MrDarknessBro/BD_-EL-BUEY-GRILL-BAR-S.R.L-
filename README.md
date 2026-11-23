# BD - El Buey Grill Bar S.R.L.

Repositorio con los scripts de base de datos transaccional en **SQL Server**, programacion interna, modelo estrella y vistas de origen/ETL para **El Buey Grill Bar S.R.L.**

## Contenido del repositorio

- `buey.bak`: Respaldo de base de datos de SQL Server.
- `sql/01_ddl/`
  - `01 Crear BD y 20 Tablas.sql`: Creacion de la base de datos y las 20 tablas transaccionales en `dbo`.
- `sql/02_dml_cargas/`
  - `02 Carga de productos y empleados.sql`: Catalogo base, roles, empleados y mesas.
  - `03 Insumos_recetas_proveedores.sql`: Proveedores, insumos, recetas y variantes.
  - `04_parte_01_carga_datos_operacionales.sql` ... `04_parte_XX_carga_datos_operacionales.sql`: Datos operacionales divididos en partes menores a 1 MB para visualizacion directa en GitHub.
- `sql/03_modelo_y_vistas/`
  - `05 Crear Modelo estrella.sql`: Tablas dimensionales y de hechos.
  - `06 funciones triggers y vistas.sql`: Funciones, triggers y vistas.
  - `07 vistas Origen.sql`: Vistas de origen / preparacion de datos.

## Orden de ejecucion sugerido

1. Restaurar `buey.bak` **o** ejecutar los scripts en orden del `01` al `07` (ejecutando las partes de `04` en orden secuencial `01`, `02`, ...) en SQL Server Management Studio (SSMS).
2. Validar conteos de registros y vistas antes de conectar herramientas de analisis o visualizacion.