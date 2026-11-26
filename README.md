# BD - El Buey Grill Bar S.R.L.

Proyecto académico y aplicado de ingeniería de datos, modelado y Business Intelligence desarrollado para **El Buey Grill Bar S.R.L.** El objetivo central del repositorio es consolidar la base de datos operativa, automatizar el procesamiento y transformación de datos, y construir tableros analíticos que apoyen la toma de decisiones del negocio.

## Descripción del proyecto

En el sector gastronómico y de restobares, el control de operaciones, ventas, clientes, productos y movimiento diario requiere contar con datos confiables y estructurados. Este repositorio reúne los componentes técnicos del sistema de información y analítica de **El Buey Grill Bar S.R.L.**, articulando desde la estructura relacional y rutinas SQL hasta el procesamiento distribuido con PySpark y la visualización ejecutiva en Power BI.

## Arquitectura y componentes

- **Base de datos y programación SQL (`SQL Server`):** Respaldo de base de datos (`buey.bak`), scripts DDL y DML, procesos ETL, funciones, triggers y vistas orientados a garantizar la integridad de la información y facilitar la explotación analítica.
- **Procesamiento y análisis con PySpark (`PySpark_el_buey.ipynb`):** Cuaderno interactivo enfocado en la carga, limpieza, transformación y análisis de datos utilizando Apache Spark / PySpark.
- **Business Intelligence y visualización (`BIRESTAURANTE.pbix`):** Modelo analítico y dashboard interactivo en Power BI diseñado para monitorear indicadores clave y tendencias del negocio (se recomienda descargar el archivo mediante **View raw** y abrirlo en **Power BI Desktop** para interactuar con los filtros y visualizaciones).

## Vista previa del dashboard

<img width="1116" height="876" alt="image" src="https://github.com/user-attachments/assets/5d0833d0-abac-48cf-a9ad-46468f578a5e" />
<img width="1117" height="663" alt="image" src="https://github.com/user-attachments/assets/851a61d6-63b8-4c61-ab5b-f969db5d69c7" />
<img width="1116" height="715" alt="image" src="https://github.com/user-attachments/assets/63e0806b-ae4b-4f5a-8916-0810852c3d84" />
<img width="1150" height="780" alt="image" src="https://github.com/user-attachments/assets/b14a5d6b-5e1c-4f1d-80ad-cbc37e88be3e" />


## Guía de ejecución y uso

1. **Base de datos en SQL Server:**
- Abre **SQL Server Management Studio (SSMS)** y conéctate a tu instancia de SQL Server.
- Restaura el respaldo de la base de datos y ejecuta o revisa los scripts correspondientes (DDL/DML, ETL, vistas, funciones y triggers) según el entorno de pruebas.
2. **Notebook con PySpark:**
- Abre `PySpark_el_buey.ipynb` en **Google Colab**, **Jupyter** o **Visual Studio Code**.
- Verifica la disponibilidad del entorno de Spark/PySpark y ejecuta las celdas de forma secuencial para replicar el procesamiento y los resultados.
3. **Tablero en Power BI:**
- Descarga `BIRESTAURANTE.pbix` desde el repositorio usando **View raw**.
- Ábrelo con **Power BI Desktop**, revisa las conexiones/orígenes de datos si es necesario y explora las páginas del informe.

## Tecnologías y herramientas

- **Motor de base de datos y BI:** Microsoft SQL Server, T-SQL, Power BI Desktop
- **Procesamiento de datos:** Python, Apache Spark / PySpark
- **Control de versiones:** Git y GitHub
