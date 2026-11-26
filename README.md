# BD - El Buey Grill Bar S.R.L.

Proyecto integral de ingeniería de datos, administración de bases de datos y Business Intelligence desarrollado para **El Buey Grill Bar S.R.L.** El objetivo principal del repositorio es consolidar la base de datos operativa, automatizar la extracción, limpieza y transformación de datos, y proporcionar herramientas analíticas que respalden la toma de decisiones comerciales y operativas del negocio.

## Descripción del proyecto

En la gestión de restaurantes y restobares, el control preciso de ventas, inventario, clientes, pedidos y desempeño por productos resulta clave para optimizar la rentabilidad. Este repositorio reúne los distintos entregables técnicos del proyecto de **El Buey Grill Bar S.R.L.**, abarcando desde el modelado relacional y programación en SQL Server hasta el procesamiento de datos con PySpark, la visualización ejecutiva en Power BI y la documentación técnica completa.

## Estructura y componentes del repositorio

* **Respaldo de base de datos (`buey.bak`):** Copia de seguridad completa de la base de datos en SQL Server lista para ser restaurada en un entorno local o de pruebas.
* **Scripts y programación SQL (`SQL Server`):** Conjunto de scripts DDL y DML, rutinas ETL, procedimientos, funciones, triggers y vistas diseñados para mantener la integridad referencial y preparar los datos para análisis.
* **Procesamiento y análisis con PySpark (`PySpark_el_buey.ipynb`):** Cuaderno de trabajo enfocado en la carga, limpieza, transformación y análisis exploratorio de datos mediante Apache Spark / PySpark.
* **Dashboard de Business Intelligence (`BIRESTAURANTE.pbix`):** Modelo analítico y reporte interactivo en Power BI para el seguimiento de indicadores clave (KPIs) y tendencias del restaurante (descárgalo mediante **View raw** y ábrelo en **Power BI Desktop**).
* **Informe final del proyecto (`2026-2_ISC-Informe_Proyecto_Final_BASAV2.pdf`):** Documentación técnica detallada que recoge el planteamiento, arquitectura, diseño del modelo, desarrollo e interpretación de resultados del proyecto.

## Guía de ejecución y uso

1. **Restaurar la base de datos en SQL Server:**
   * Abre **SQL Server Management Studio (SSMS)** y conéctate a tu servidor local.
   * Haz clic derecho sobre **Bases de datos > Restaurar base de datos...**, selecciona **Dispositivo** y carga el archivo `buey.bak`.
   * Revisa o ejecuta los scripts SQL complementarios (DDL/DML, ETL, vistas, funciones y triggers) según tus pruebas.
2. **Ejecutar el análisis en PySpark:**
   * Abre `PySpark_el_buey.ipynb` en **Google Colab**, **Jupyter Notebook** o **Visual Studio Code**.
   * Asegúrate de tener configurado el entorno de Spark/PySpark y ejecuta las celdas en orden secuencial.
3. **Explorar el dashboard en Power BI:**
   * Descarga `BIRESTAURANTE.pbix` desde el repositorio haciendo clic en **View raw**.
   * Ábrelo con **Power BI Desktop** para interactuar con las páginas, gráficos y segmentadores.
4. **Consultar la documentación:**
   * Abre `2026-2_ISC-Informe_Proyecto_Final_BASAV2.pdf` directamente desde GitHub para revisar el sustento metodológico y técnico completo.

## Tecnologías utilizadas

* **Base de datos y BI:** Microsoft SQL Server, T-SQL, SQL Server Management Studio (SSMS), Power BI Desktop
* **Procesamiento de datos:** Python, Apache Spark / PySpark
* **Documentación y control de versiones:** Git, GitHub
