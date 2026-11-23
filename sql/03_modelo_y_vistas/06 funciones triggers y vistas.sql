USE [BD_RestaurantBueyGrill];
GO


CREATE OR ALTER FUNCTION dbo.fn_RecetaDetalle
(
    @IdProducto INT,
    @IdVariante INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT x.IdInsumo,CAST(SUM(x.Cantidad) AS DECIMAL(14,4)) AS CantidadPorUnidad
    FROM (
        SELECT IdInsumo,Cantidad FROM dbo.ProductoInsumo WHERE IdProducto=@IdProducto
        UNION ALL
        SELECT IdInsumo,Cantidad FROM dbo.VarianteInsumo WHERE IdVariante=@IdVariante
    ) x
    GROUP BY x.IdInsumo
);
GO


CREATE OR ALTER FUNCTION dbo.fn_TotalPedido(@IdPedido INT)
RETURNS DECIMAL(14,2)
AS
BEGIN
    DECLARE @Total DECIMAL(14,2);
    SELECT @Total=ISNULL(SUM(Importe),0) FROM dbo.DetallePedido WHERE IdPedido=@IdPedido;
    RETURN ISNULL(@Total,0);
END;
GO


CREATE OR ALTER FUNCTION dbo.fn_StockDisponible(@IdInsumo INT)
RETURNS DECIMAL(16,4)
AS
BEGIN
    DECLARE @Stock DECIMAL(16,4);
    SELECT @Stock=Stock FROM dbo.Insumo WHERE IdInsumo=@IdInsumo;
    RETURN @Stock;
END;
GO


CREATE OR ALTER FUNCTION dbo.fn_CostoReceta(@IdProducto INT,@IdVariante INT)
RETURNS DECIMAL(14,2)
AS
BEGIN
    DECLARE @Costo DECIMAL(14,2);
    SELECT @Costo=CAST(ROUND(SUM(r.CantidadPorUnidad * i.CostoReferencial),2) AS DECIMAL(14,2))
    FROM dbo.fn_RecetaDetalle(@IdProducto,@IdVariante) r
    JOIN dbo.Insumo i ON i.IdInsumo=r.IdInsumo;
    RETURN ISNULL(@Costo,0);
END;
GO


CREATE OR ALTER TRIGGER dbo.trg_Movimiento_ActualizarStock
    ON dbo.MovimientoInventario
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM inserted) RETURN;
    IF EXISTS(
        SELECT 1 FROM inserted m JOIN dbo.DetalleCompra d ON d.IdDetalleCompra=m.IdDetalleCompra
        JOIN dbo.Compra c ON c.IdCompra=d.IdCompra
        WHERE m.TipoMovimiento=N'Entrada' AND (c.Estado<>N'Recibida' OR m.FechaMovimiento<>c.FechaRecepcion)
    )
    BEGIN
        THROW 51001,N'Entrada inválida: la compra debe estar recibida y la fecha debe coincidir.',1;
    END;
    IF EXISTS(
        SELECT 1 FROM inserted m JOIN dbo.DetallePedido d ON d.IdDetallePedido=m.IdDetallePedido
        JOIN dbo.Pedido p ON p.IdPedido=d.IdPedido
        WHERE m.TipoMovimiento=N'Consumo' AND (p.Estado<>N'Entregado' OR m.FechaMovimiento<>p.FechaEntrega)
    )
    BEGIN
        THROW 51002,N'Consumo inválido: el pedido debe estar entregado.',1;
    END;
    IF EXISTS(
        SELECT 1 FROM inserted x WHERE x.TipoMovimiento=N'Inicial'
        AND EXISTS(SELECT 1 FROM dbo.MovimientoInventario y
            WHERE y.IdInsumo=x.IdInsumo AND y.IdMovimiento<>x.IdMovimiento)
    )
    BEGIN
        THROW 51003,N'El movimiento Inicial solo se admite en insumos sin historial.',1;
    END;
    ;WITH delta AS (
        SELECT IdInsumo,CAST(SUM(CASE WHEN TipoMovimiento=N'Consumo' THEN -Cantidad ELSE Cantidad END) AS DECIMAL(16,4)) AS Cambio
        FROM inserted GROUP BY IdInsumo
    )
    SELECT i.IdInsumo INTO #SaldosInvalidos
    FROM dbo.Insumo i WITH(UPDLOCK,HOLDLOCK)
    JOIN delta d ON d.IdInsumo=i.IdInsumo
    WHERE i.Stock+d.Cambio < 0;
    IF EXISTS(SELECT 1 FROM #SaldosInvalidos)
    BEGIN
        THROW 51004,N'Stock insuficiente: no se permite inventario negativo.',1;
    END;
    ;WITH delta AS (
        SELECT IdInsumo,CAST(SUM(CASE WHEN TipoMovimiento=N'Consumo' THEN -Cantidad ELSE Cantidad END) AS DECIMAL(16,4)) AS Cambio
        FROM inserted GROUP BY IdInsumo
    )
    UPDATE i SET i.Stock=i.Stock+d.Cambio
    FROM dbo.Insumo i JOIN delta d ON d.IdInsumo=i.IdInsumo;
END;
GO


CREATE OR ALTER TRIGGER dbo.trg_Movimiento_NoModificar
    ON dbo.MovimientoInventario
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM deleted)
    BEGIN
        THROW 51005,N'Los movimientos de inventario históricos no se actualizan ni eliminan.',1;
    END;
END;
GO


CREATE OR ALTER TRIGGER dbo.trg_Insumo_NoStockDirecto
    ON dbo.Insumo
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(Stock) AND TRIGGER_NESTLEVEL()=1
    BEGIN
        THROW 51006,N'Actualice el stock exclusivamente mediante movimientos de inventario.',1;
    END;
END;
GO


CREATE OR ALTER TRIGGER dbo.trg_DetalleCompra_ValidarYTotalizar
    ON dbo.DetalleCompra
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(
        SELECT 1 FROM (
            SELECT IdCompra FROM inserted UNION SELECT IdCompra FROM deleted
        ) x JOIN dbo.Compra c ON c.IdCompra=x.IdCompra WHERE c.Estado<>N'Registrada'
    )
    BEGIN
        THROW 51007,N'No se pueden editar líneas de compras recibidas o anuladas.',1;
    END;
    IF EXISTS(
        SELECT 1 FROM inserted x JOIN dbo.Compra c ON c.IdCompra=x.IdCompra
        LEFT JOIN dbo.ProveedorInsumo pi ON pi.IdProveedor=c.IdProveedor AND pi.IdInsumo=x.IdInsumo
        WHERE pi.IdProveedor IS NULL OR ABS(x.Importe-ROUND(x.Cantidad*x.CostoUnitario,2))>0.01
    )
    BEGIN
        THROW 51008,N'Detalle de compra: proveedor/insumo o importe inconsistente.',1;
    END;
    ;WITH afectados AS (SELECT IdCompra FROM inserted UNION SELECT IdCompra FROM deleted)
    UPDATE c SET Total=ISNULL(x.TotalCalculado,0)
    FROM dbo.Compra c JOIN afectados a ON a.IdCompra=c.IdCompra
    OUTER APPLY (SELECT CAST(SUM(d.Importe) AS DECIMAL(14,2)) AS TotalCalculado
        FROM dbo.DetalleCompra d WHERE d.IdCompra=c.IdCompra) x;
END;
GO


CREATE OR ALTER TRIGGER dbo.trg_Compra_Recepcionar
    ON dbo.Compra
AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM inserted i LEFT JOIN deleted d ON d.IdCompra=i.IdCompra
        WHERE d.IdCompra IS NULL AND i.Estado<>N'Registrada')
    BEGIN
        THROW 51009,N'Las compras nuevas deben registrarse en estado Registrada.',1;
    END;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.IdCompra=i.IdCompra
        WHERE d.Estado IN(N'Recibida',N'Anulada') AND
        (i.Estado<>d.Estado OR i.Total<>d.Total OR i.FechaCompra<>d.FechaCompra OR
            i.IdProveedor<>d.IdProveedor OR ISNULL(i.FechaRecepcion,CONVERT(DATETIME2(0),'19000101'))<>ISNULL(d.FechaRecepcion,CONVERT(DATETIME2(0),'19000101'))))
    BEGIN
        THROW 51010,N'Una compra recibida o anulada no admite modificaciones.',1;
    END;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.IdCompra=i.IdCompra
        WHERE i.Estado<>d.Estado AND NOT
        (d.Estado=N'Registrada' AND i.Estado IN(N'Recibida',N'Anulada')))
    BEGIN
        THROW 51011,N'Transición de estado de compra no permitida.',1;
    END;
    IF EXISTS(
        SELECT 1 FROM inserted i JOIN deleted d ON d.IdCompra=i.IdCompra
        WHERE d.Estado=N'Registrada' AND i.Estado=N'Recibida'
        AND (i.FechaRecepcion IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.DetalleCompra WHERE IdCompra=i.IdCompra)
            OR ABS(i.Total-ISNULL((SELECT SUM(Importe) FROM dbo.DetalleCompra WHERE IdCompra=i.IdCompra),0))>0.01)
    )
    BEGIN
        THROW 51012,N'No puede recibirse una compra sin detalles, fecha o total válido.',1;
    END;
    INSERT dbo.MovimientoInventario(IdInsumo,IdDetallePedido,IdDetalleCompra,FechaMovimiento,TipoMovimiento,Cantidad,CostoUnitario)
    SELECT d.IdInsumo,NULL,d.IdDetalleCompra,i.FechaRecepcion,N'Entrada',d.Cantidad,d.CostoUnitario
    FROM inserted i JOIN deleted old ON old.IdCompra=i.IdCompra
    JOIN dbo.DetalleCompra d ON d.IdCompra=i.IdCompra
    WHERE old.Estado=N'Registrada' AND i.Estado=N'Recibida';
END;
GO


CREATE OR ALTER TRIGGER dbo.trg_Pedido_TransicionesYConsumo
    ON dbo.Pedido
AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM inserted i LEFT JOIN deleted d ON d.IdPedido=i.IdPedido
        WHERE d.IdPedido IS NULL AND i.Estado<>N'Pendiente')
    BEGIN
        THROW 51013,N'Los pedidos nuevos deben iniciar pendientes.',1;
    END;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.IdPedido=i.IdPedido
        WHERE d.Estado IN(N'Entregado',N'Cancelado') AND
        (i.Estado<>d.Estado OR i.Total<>d.Total OR i.FechaPedido<>d.FechaPedido OR
            ISNULL(i.FechaEntrega,CONVERT(DATETIME2(0),'19000101'))<>ISNULL(d.FechaEntrega,CONVERT(DATETIME2(0),'19000101'))))
    BEGIN
        THROW 51014,N'Un pedido entregado o cancelado no puede modificarse.',1;
    END;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.IdPedido=i.IdPedido
        WHERE i.Estado<>d.Estado AND NOT
        ((d.Estado=N'Pendiente' AND i.Estado IN(N'Preparando',N'Cancelado',N'Entregado')) OR
            (d.Estado=N'Preparando' AND i.Estado IN(N'Listo',N'Entregado',N'Cancelado')) OR
            (d.Estado=N'Listo' AND i.Estado IN(N'Entregado',N'Cancelado'))))
    BEGIN
        THROW 51015,N'Transición de pedido no permitida.',1;
    END;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.IdPedido=i.IdPedido
        WHERE i.Estado=N'Entregado' AND d.Estado<>N'Entregado'
        AND (NOT EXISTS(SELECT 1 FROM dbo.DetallePedido dp WHERE dp.IdPedido=i.IdPedido) OR
            ABS(i.Total-ISNULL((SELECT SUM(Importe) FROM dbo.DetallePedido dp WHERE dp.IdPedido=i.IdPedido),0))>0.01))
    BEGIN
        THROW 51016,N'No puede entregarse un pedido sin líneas o con total incorrecto.',1;
    END;
    INSERT dbo.MovimientoInventario(IdInsumo,IdDetallePedido,IdDetalleCompra,FechaMovimiento,TipoMovimiento,Cantidad,CostoUnitario)
    SELECT r.IdInsumo,dp.IdDetallePedido,NULL,i.FechaEntrega,N'Consumo',
    CAST(r.CantidadPorUnidad*dp.Cantidad AS DECIMAL(14,4)),ins.CostoReferencial
    FROM inserted i JOIN deleted old ON old.IdPedido=i.IdPedido
    JOIN dbo.DetallePedido dp ON dp.IdPedido=i.IdPedido
    CROSS APPLY dbo.fn_RecetaDetalle(dp.IdProducto,dp.IdVariante) r
    JOIN dbo.Insumo ins ON ins.IdInsumo=r.IdInsumo
    WHERE old.Estado<>N'Entregado' AND i.Estado=N'Entregado';
END;
GO


CREATE OR ALTER TRIGGER dbo.trg_DetallePedido_ValidarYTotalizar
    ON dbo.DetallePedido
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM (SELECT IdPedido FROM inserted UNION SELECT IdPedido FROM deleted)x
        JOIN dbo.Pedido p ON p.IdPedido=x.IdPedido WHERE p.Estado IN(N'Entregado',N'Cancelado'))
    BEGIN
        THROW 51017,N'No puede editar líneas de un pedido entregado o cancelado.',1;
    END;
    IF EXISTS(SELECT 1 FROM inserted d JOIN dbo.Producto p ON p.IdProducto=d.IdProducto
        WHERE ABS(d.PrecioUnitario-p.Precio)>0.01 OR ABS(d.Importe-ROUND(d.Cantidad*d.PrecioUnitario,2))>0.01)
    BEGIN
        THROW 51018,N'Precio unitario o importe distinto del menú original.',1;
    END;
    IF EXISTS(SELECT 1 FROM inserted d JOIN dbo.Producto p ON p.IdProducto=d.IdProducto
        WHERE p.Estado NOT IN(N'Activo',N'Disponible'))
    BEGIN
        THROW 51019,N'El producto indicado no está disponible.',1;
    END;
    ;WITH afectados AS (SELECT IdPedido FROM inserted UNION SELECT IdPedido FROM deleted)
    UPDATE p SET Total=ISNULL(x.TotalCalculado,0)
    FROM dbo.Pedido p JOIN afectados a ON a.IdPedido=p.IdPedido
    OUTER APPLY (SELECT CAST(SUM(Importe) AS DECIMAL(14,2)) TotalCalculado
        FROM dbo.DetallePedido d WHERE d.IdPedido=p.IdPedido) x;
END;
GO


CREATE OR ALTER TRIGGER dbo.trg_Venta_ValidarPago
    ON dbo.Venta
AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM inserted v JOIN dbo.Pedido p ON p.IdPedido=v.IdPedido
        JOIN dbo.MetodoPago m ON m.IdMetodoPago=v.IdMetodoPago
        WHERE p.Estado<>N'Entregado' OR v.Estado<>N'Pagada' OR m.Activo<>1 OR
        v.FechaVenta<p.FechaEntrega OR ABS(v.Total-p.Total)>0.01 OR
        ABS(v.SubtotalSinIGV-ROUND(v.Total/CAST(1.18 AS DECIMAL(5,2)),2))>0.01)
    BEGIN
        THROW 51020,N'Venta inválida: pedido, pago, fecha o IGV inconsistente.',1;
    END;
    IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.IdVenta=i.IdVenta)
    BEGIN
        THROW 51021,N'No se editan ventas ya registradas: consulte el procedimiento.',1;
    END;
END;
GO


CREATE OR ALTER PROCEDURE dbo.sp_RegistrarCompra
    @IdProveedor INT,
    @IdEmpleado INT,
    @FechaCompra DATETIME2(0),
    @Lineas dbo.TVP_LineasCompra READONLY,
    @IdCompra INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;SET XACT_ABORT ON;
    IF NOT EXISTS(SELECT 1 FROM @Lineas) THROW 51100,N'La compra requiere insumos.',1;
    IF EXISTS(SELECT 1 FROM @Lineas GROUP BY IdInsumo HAVING COUNT(*)>1)
    THROW 51101,N'Reúna cantidades del mismo insumo en una sola línea.',1;
    IF EXISTS(SELECT 1 FROM @Lineas l LEFT JOIN dbo.ProveedorInsumo pi
        ON pi.IdProveedor=@IdProveedor AND pi.IdInsumo=l.IdInsumo WHERE pi.IdProveedor IS NULL)
    THROW 51102,N'El proveedor no suministra uno de los insumos.',1;
    BEGIN TRY
        BEGIN TRAN;
        INSERT dbo.Compra(IdProveedor,IdEmpleado,FechaCompra,FechaRecepcion,Estado,Total)
        VALUES(@IdProveedor,@IdEmpleado,@FechaCompra,NULL,N'Registrada',0);
        SET @IdCompra=CONVERT(INT,SCOPE_IDENTITY());
        INSERT dbo.DetalleCompra(IdCompra,IdInsumo,Cantidad,CostoUnitario,Importe)
        SELECT @IdCompra,IdInsumo,Cantidad,CostoUnitario,
        CAST(ROUND(Cantidad*CostoUnitario,2) AS DECIMAL(14,2)) FROM @Lineas;
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO


CREATE OR ALTER PROCEDURE dbo.sp_RecibirCompra
    @IdCompra INT,
    @FechaRecepcion DATETIME2(0)=NULL
AS
BEGIN
    SET NOCOUNT ON;SET XACT_ABORT ON;
    DECLARE @Fecha DATETIME2(0)=ISNULL(@FechaRecepcion,CAST(SYSDATETIME() AS DATETIME2(0)));
    BEGIN TRY
        BEGIN TRAN;
        UPDATE dbo.Compra SET Estado=N'Recibida',FechaRecepcion=@Fecha
        WHERE IdCompra=@IdCompra AND Estado=N'Registrada' AND FechaCompra<=@Fecha;
        IF @@ROWCOUNT<>1 THROW 51103,N'La compra no existe, no está registrada o la fecha es inválida.',1;
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO


CREATE OR ALTER PROCEDURE dbo.sp_RegistrarPedido
    @IdCliente INT=NULL,
    @IdEmpleado INT,
    @IdRepartidor INT=NULL,
    @IdMesa INT=NULL,
    @DireccionEntrega NVARCHAR(250)=NULL,
    @TipoPedido NVARCHAR(12),
    @FechaPedido DATETIME2(0),
    @Lineas dbo.TVP_LineasPedido READONLY,
    @IdPedido INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;SET XACT_ABORT ON;
    IF NOT EXISTS(SELECT 1 FROM @Lineas) THROW 51104,N'El pedido requiere al menos un producto.',1;
    IF EXISTS(SELECT 1 FROM @Lineas GROUP BY IdProducto,IdVariante HAVING COUNT(*)>1)
    THROW 51105,N'Consolide el mismo producto/variante en una línea.',1;
    IF EXISTS(SELECT 1 FROM @Lineas l LEFT JOIN dbo.Producto p ON p.IdProducto=l.IdProducto
        WHERE p.IdProducto IS NULL OR p.Estado NOT IN (N'Activo',N'Disponible'))
    THROW 51106,N'Algún producto no existe o no está disponible.',1;
    IF EXISTS(SELECT 1 FROM @Lineas l LEFT JOIN dbo.VarianteProducto v ON
        v.IdVariante=l.IdVariante AND v.IdProducto=l.IdProducto
        WHERE l.IdVariante IS NOT NULL AND v.IdVariante IS NULL)
    THROW 51107,N'La variante seleccionada no pertenece al producto.',1;
    IF EXISTS(SELECT 1 FROM @Lineas l WHERE NOT EXISTS
        (SELECT 1 FROM dbo.fn_RecetaDetalle(l.IdProducto,l.IdVariante)))
    THROW 51108,N'Falta receta para alguno de los productos.',1;
    BEGIN TRY
        BEGIN TRAN;
        INSERT dbo.Pedido(IdCliente,IdEmpleado,IdRepartidor,IdMesa,DireccionEntrega,FechaPedido,FechaEntrega,TipoPedido,Estado,FechaUltimoEstado,Total)
        VALUES(@IdCliente,@IdEmpleado,@IdRepartidor,@IdMesa,@DireccionEntrega,@FechaPedido,NULL,@TipoPedido,N'Pendiente',@FechaPedido,0);
        SET @IdPedido=CONVERT(INT,SCOPE_IDENTITY());
        INSERT dbo.DetallePedido(IdPedido,IdProducto,IdVariante,Cantidad,PrecioUnitario,Importe)
        SELECT @IdPedido,l.IdProducto,l.IdVariante,l.Cantidad,p.Precio,
        CAST(l.Cantidad*p.Precio AS DECIMAL(14,2))
        FROM @Lineas l JOIN dbo.Producto p ON p.IdProducto=l.IdProducto;
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO


CREATE OR ALTER PROCEDURE dbo.sp_CambiarEstadoPedido
    @IdPedido INT,
    @NuevoEstado NVARCHAR(15),
    @FechaEvento DATETIME2(0)=NULL
AS
BEGIN
    SET NOCOUNT ON;SET XACT_ABORT ON;
    IF @NuevoEstado NOT IN(N'Preparando',N'Listo',N'Cancelado',N'Entregado')
    THROW 51109,N'Estado solicitado no admitido.',1;
    DECLARE @Fecha DATETIME2(0)=ISNULL(@FechaEvento,CAST(SYSDATETIME() AS DATETIME2(0)));
    BEGIN TRY
        BEGIN TRAN;
        UPDATE dbo.Pedido SET Estado=@NuevoEstado,FechaUltimoEstado=@Fecha,
        FechaEntrega=CASE WHEN @NuevoEstado=N'Entregado' THEN @Fecha ELSE NULL END
        WHERE IdPedido=@IdPedido AND FechaPedido<=@Fecha AND
        ((Estado=N'Pendiente' AND @NuevoEstado IN(N'Preparando',N'Cancelado',N'Entregado')) OR
            (Estado=N'Preparando' AND @NuevoEstado IN(N'Listo',N'Cancelado',N'Entregado')) OR
            (Estado=N'Listo' AND @NuevoEstado IN(N'Entregado',N'Cancelado')));
        IF @@ROWCOUNT<>1 THROW 51110,N'Transición de pedido no permitida o fecha inválida.',1;
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO


CREATE OR ALTER PROCEDURE dbo.sp_RegistrarVenta
    @IdPedido INT,
    @IdMetodoPago INT,
    @FechaPago DATETIME2(0)=NULL,
    @IdVenta INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;SET XACT_ABORT ON;
    DECLARE @Fecha DATETIME2(0)=ISNULL(@FechaPago,CAST(SYSDATETIME() AS DATETIME2(0)));
    BEGIN TRY
        BEGIN TRAN;
        DECLARE @Total DECIMAL(14,2),@Subtotal DECIMAL(14,2);
        SELECT @Total=Total FROM dbo.Pedido WITH(UPDLOCK,HOLDLOCK)
        WHERE IdPedido=@IdPedido AND Estado=N'Entregado' AND FechaEntrega<=@Fecha;
        IF @Total IS NULL THROW 51111,N'El pedido no está entregado o la fecha no corresponde.',1;
        IF EXISTS(SELECT 1 FROM dbo.Venta WHERE IdPedido=@IdPedido)
        THROW 51112,N'Ya existe una venta para este pedido.',1;
        IF NOT EXISTS(SELECT 1 FROM dbo.MetodoPago WHERE IdMetodoPago=@IdMetodoPago AND Activo=1)
        THROW 51113,N'Método de pago no válido o inactivo.',1;
        SET @Subtotal=ROUND(@Total/CAST(1.18 AS DECIMAL(5,2)),2);
        INSERT dbo.Venta(IdPedido,IdMetodoPago,FechaVenta,SubtotalSinIGV,IGV,Total,Estado)
        VALUES(@IdPedido,@IdMetodoPago,@Fecha,@Subtotal,@Total-@Subtotal,@Total,N'Pagada');
        SET @IdVenta=CONVERT(INT,SCOPE_IDENTITY());
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO


CREATE OR ALTER PROCEDURE dbo.sp_ConsultarStockBajo
AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdInsumo,Nombre,UnidadMedida,Stock,StockMinimo,
    CAST(StockMinimo-Stock AS DECIMAL(16,4)) AS Faltante
    FROM dbo.Insumo WHERE Stock<StockMinimo ORDER BY Faltante DESC;
END;
GO


CREATE OR ALTER VIEW dbo.vw_MenuProductos
AS
SELECT p.IdProducto,p.Nombre AS Producto,c.Nombre AS Categoria,p.Descripcion,p.Precio AS PrecioConIGV,p.Estado,
dbo.fn_CostoReceta(p.IdProducto,NULL) AS CostoRecetaBaseEstimado
FROM dbo.Producto p JOIN dbo.Categoria c ON c.IdCategoria=p.IdCategoria;
GO


CREATE OR ALTER VIEW dbo.vw_PedidosOperacionales
AS
SELECT p.IdPedido,p.FechaPedido,p.FechaEntrega,p.TipoPedido,p.Estado AS EstadoPedido,
p.Total AS TotalConIGV,p.IdMesa,p.IdEmpleado,p.IdCliente,
CONCAT(e.Nombres,N' ',e.Apellidos) AS Empleado,
CASE WHEN cl.IdCliente IS NULL THEN N'Consumidor no identificado'
ELSE CONCAT(cl.Nombres,N' ',cl.Apellidos) END AS Cliente
FROM dbo.Pedido p JOIN dbo.Empleado e ON e.IdEmpleado=p.IdEmpleado
LEFT JOIN dbo.Cliente cl ON cl.IdCliente=p.IdCliente;
GO


CREATE OR ALTER VIEW dbo.vw_VentasPagadas
AS
SELECT v.IdVenta,v.IdPedido,v.FechaVenta,v.SubtotalSinIGV,v.IGV,v.Total AS TotalConIGV,
m.Nombre AS MetodoPago,p.TipoPedido,p.IdEmpleado,p.IdCliente
FROM dbo.Venta v JOIN dbo.MetodoPago m ON m.IdMetodoPago=v.IdMetodoPago
JOIN dbo.Pedido p ON p.IdPedido=v.IdPedido
WHERE v.Estado=N'Pagada' AND p.Estado=N'Entregado';
GO


CREATE OR ALTER VIEW dbo.vw_VentasMensuales
AS
SELECT YEAR(v.FechaVenta) AS Anio,MONTH(v.FechaVenta) AS Mes,
COUNT_BIG(*) AS CantidadVentas,SUM(v.Total) AS IngresoBrutoConIGV,
SUM(v.SubtotalSinIGV) AS VentaNetaSinIGV
FROM dbo.Venta v JOIN dbo.Pedido p ON p.IdPedido=v.IdPedido
WHERE v.Estado=N'Pagada' AND p.Estado=N'Entregado'
GROUP BY YEAR(v.FechaVenta),MONTH(v.FechaVenta);
GO


CREATE OR ALTER VIEW dbo.vw_ComprasPorProveedor
AS
SELECT c.IdCompra,c.FechaCompra,c.FechaRecepcion,c.Estado,
c.Total,p.IdProveedor,p.RazonSocial AS Proveedor
FROM dbo.Compra c JOIN dbo.Proveedor p ON p.IdProveedor=c.IdProveedor;
GO


CREATE OR ALTER VIEW dbo.vw_StockInsumos
AS
SELECT i.IdInsumo,i.Nombre AS Insumo,i.UnidadMedida,i.Stock,i.StockMinimo,
CASE WHEN i.Stock<i.StockMinimo THEN N'Reponer' ELSE N'Suficiente' END AS Semaforo,
i.CostoReferencial,CAST(i.Stock*i.CostoReferencial AS DECIMAL(18,2)) AS ValorEstimado
FROM dbo.Insumo i;
GO


CREATE OR ALTER VIEW dbo.vw_ConsumoPorProducto
AS
SELECT mov.IdMovimiento,p.IdPedido,d.IdDetallePedido,d.IdProducto,prod.Nombre AS Producto,
mov.IdInsumo,ins.Nombre AS Insumo,ins.UnidadMedida,mov.FechaMovimiento,
mov.Cantidad AS Consumo,mov.CostoUnitario,
CAST(ROUND(mov.Cantidad*mov.CostoUnitario,2) AS DECIMAL(14,2)) AS CostoEstimado
FROM dbo.MovimientoInventario mov
JOIN dbo.DetallePedido d ON d.IdDetallePedido=mov.IdDetallePedido
JOIN dbo.Pedido p ON p.IdPedido=d.IdPedido
JOIN dbo.Producto prod ON prod.IdProducto=d.IdProducto
JOIN dbo.Insumo ins ON ins.IdInsumo=mov.IdInsumo
WHERE mov.TipoMovimiento=N'Consumo' AND p.Estado=N'Entregado';
GO


CREATE OR ALTER VIEW dbo.vw_ClientesFrecuentes
AS
SELECT cl.IdCliente,CONCAT(cl.Nombres,N' ',cl.Apellidos) AS Cliente,
COUNT_BIG(*) AS NumeroPedidosPagados,SUM(v.Total) AS TotalGastado
FROM dbo.Cliente cl JOIN dbo.Pedido p ON p.IdCliente=cl.IdCliente
JOIN dbo.Venta v ON v.IdPedido=p.IdPedido
WHERE p.Estado=N'Entregado' AND v.Estado=N'Pagada'
GROUP BY cl.IdCliente,cl.Nombres,cl.Apellidos;
GO

