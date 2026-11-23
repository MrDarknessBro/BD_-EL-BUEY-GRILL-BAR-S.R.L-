
USE [BD_RestaurantBueyGrill];
GO

IF SCHEMA_ID(N'etl') IS NULL
    EXEC(N'CREATE SCHEMA etl');
GO


CREATE OR ALTER VIEW etl.vw_DimProducto AS
SELECT 
    p.IdProducto AS IdProductoOrigen,
    p.IdCategoria AS IdCategoriaOrigen,
    c.Nombre AS Categoria,
    p.Nombre AS NombreProducto,
    p.Precio AS PrecioMenuConIGV,
    p.Estado
FROM dbo.Producto p
JOIN dbo.Categoria c ON c.IdCategoria = p.IdCategoria;
GO


CREATE OR ALTER VIEW etl.vw_DimCliente AS
SELECT 
    IdCliente AS IdClienteOrigen,
    CONCAT(Nombres, N' ', Apellidos) AS NombreCliente,
    CAST(FechaRegistro AS DATE) AS FechaRegistro
FROM dbo.Cliente

UNION ALL

SELECT 
    0,
    N'Consumidor no identificado',
    CAST(NULL AS DATE);
GO


CREATE OR ALTER VIEW etl.vw_DimEmpleado AS
SELECT 
    e.IdEmpleado AS IdEmpleadoOrigen,
    CONCAT(e.Nombres, N' ', e.Apellidos) AS NombreEmpleado,
    r.Nombre AS Rol
FROM dbo.Empleado e
JOIN dbo.Rol r ON r.IdRol = e.IdRol;
GO


CREATE OR ALTER VIEW etl.vw_DimProveedor AS
SELECT 
    IdProveedor AS IdProveedorOrigen,
    RazonSocial AS Proveedor,
    Especialidad
FROM dbo.Proveedor;
GO


CREATE OR ALTER VIEW etl.vw_DimInsumo AS
SELECT 
    IdInsumo AS IdInsumoOrigen,
    Nombre AS Insumo,
    UnidadMedida
FROM dbo.Insumo;
GO


CREATE OR ALTER VIEW etl.vw_DimMetodoPago AS
SELECT 
    IdMetodoPago AS IdMetodoPagoOrigen,
    Nombre AS MetodoPago
FROM dbo.MetodoPago;
GO


CREATE OR ALTER VIEW etl.vw_FactVentas AS
SELECT 
    dp.IdDetallePedido AS IdDetallePedidoOrigen,
    p.IdPedido AS IdPedidoOrigen,
    v.IdVenta AS IdVentaOrigen,
    CAST(CONVERT(CHAR(8), v.FechaVenta, 112) AS INT) AS FechaKey,
    dp.IdProducto AS IdProductoOrigen,
    ISNULL(p.IdCliente, 0) AS IdClienteOrigen,
    p.IdEmpleado AS IdEmpleadoOrigen,
    v.IdMetodoPago AS IdMetodoPagoOrigen,
    p.TipoPedido,
    p.Estado AS EstadoPedido,
    v.Estado AS EstadoVenta,
    dp.Cantidad,
    dp.PrecioUnitario AS PrecioUnitarioConIGV,
    CAST(
        ROUND(dp.Importe / CAST(1.18 AS DECIMAL(5,2)), 2)
        AS DECIMAL(14,2)
    ) AS ImporteSinIGV,
    dp.Importe - CAST(
        ROUND(dp.Importe / CAST(1.18 AS DECIMAL(5,2)), 2)
        AS DECIMAL(14,2)
    ) AS IGV,
    dp.Importe AS ImporteConIGV
FROM dbo.DetallePedido dp
JOIN dbo.Pedido p ON p.IdPedido = dp.IdPedido
JOIN dbo.Venta v ON v.IdPedido = p.IdPedido
WHERE p.Estado = N'Entregado'
  AND v.Estado = N'Pagada';
GO


CREATE OR ALTER VIEW etl.vw_FactCompras AS
SELECT 
    dc.IdDetalleCompra AS IdDetalleCompraOrigen,
    c.IdCompra AS IdCompraOrigen,
    CAST(CONVERT(CHAR(8), c.FechaCompra, 112) AS INT) AS FechaKey,
    c.IdProveedor AS IdProveedorOrigen,
    dc.IdInsumo AS IdInsumoOrigen,
    c.Estado AS EstadoCompra,
    dc.Cantidad,
    dc.CostoUnitario,
    dc.Importe AS ImporteCompra
FROM dbo.DetalleCompra dc
JOIN dbo.Compra c ON c.IdCompra = dc.IdCompra
WHERE c.Estado IN (N'Recibida', N'Registrada');
GO


CREATE OR ALTER VIEW etl.vw_FactConsumoInsumos AS
SELECT 
    mov.IdMovimiento AS IdMovimientoOrigen,
    dp.IdDetallePedido AS IdDetallePedidoOrigen,
    p.IdPedido AS IdPedidoOrigen,
    CAST(CONVERT(CHAR(8), mov.FechaMovimiento, 112) AS INT) AS FechaKey,
    dp.IdProducto AS IdProductoOrigen,
    mov.IdInsumo AS IdInsumoOrigen,
    p.Estado AS EstadoPedido,
    dp.Cantidad AS CantidadProducto,
    mov.Cantidad AS CantidadInsumo,
    CAST(
        ROUND(mov.Cantidad * mov.CostoUnitario, 2)
        AS DECIMAL(14,2)
    ) AS CostoEstimado
FROM dbo.MovimientoInventario mov
JOIN dbo.DetallePedido dp ON mov.IdDetallePedido = dp.IdDetallePedido
JOIN dbo.Pedido p ON dp.IdPedido = p.IdPedido
WHERE mov.TipoMovimiento = N'Consumo'
  AND p.Estado = N'Entregado';
GO


CREATE OR ALTER VIEW etl.vw_DimFecha AS
WITH numeros AS (
    SELECT TOP (292)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS N
    FROM sys.all_objects
),
fechas AS (
    SELECT 
        DATEADD(DAY, CAST(N AS INT), CONVERT(DATE, '20260101', 112)) AS Fecha
    FROM numeros
),
fechas_final AS (
    SELECT 
        Fecha,
        (DATEDIFF(DAY, CONVERT(DATE, '19000101', 112), Fecha) % 7) + 1 AS NumeroDiaSemana
    FROM fechas
)
SELECT 
    CONVERT(INT, CONVERT(CHAR(8), Fecha, 112)) AS FechaKey,
    Fecha,
    CAST(YEAR(Fecha) AS SMALLINT) AS Anio,
    CAST(DATEPART(QUARTER, Fecha) AS TINYINT) AS Trimestre,
    CAST(MONTH(Fecha) AS TINYINT) AS Mes,
    CASE MONTH(Fecha)
        WHEN 1 THEN N'Enero'
        WHEN 2 THEN N'Febrero'
        WHEN 3 THEN N'Marzo'
        WHEN 4 THEN N'Abril'
        WHEN 5 THEN N'Mayo'
        WHEN 6 THEN N'Junio'
        WHEN 7 THEN N'Julio'
        WHEN 8 THEN N'Agosto'
        WHEN 9 THEN N'Septiembre'
        WHEN 10 THEN N'Octubre'
        WHEN 11 THEN N'Noviembre'
        ELSE N'Diciembre'
    END AS NombreMes,
    CAST(DAY(Fecha) AS TINYINT) AS Dia,
    CAST(NumeroDiaSemana AS TINYINT) AS NumeroDiaSemana,
    CASE NumeroDiaSemana
        WHEN 1 THEN N'Lunes'
        WHEN 2 THEN N'Martes'
        WHEN 3 THEN N'Miércoles'
        WHEN 4 THEN N'Jueves'
        WHEN 5 THEN N'Viernes'
        WHEN 6 THEN N'Sábado'
        ELSE N'Domingo'
    END AS NombreDia
FROM fechas_final;
GO
