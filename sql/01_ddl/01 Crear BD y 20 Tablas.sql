
USE master;
GO

CREATE DATABASE BD_RestaurantBueyGrill;
GO

USE BD_RestaurantBueyGrill;
GO


CREATE TABLE dbo.Rol (
    IdRol INT IDENTITY(1000,1) PRIMARY KEY,
    Nombre NVARCHAR(70) NOT NULL UNIQUE,
    Descripcion NVARCHAR(150) NULL,
    Estado BIT NOT NULL DEFAULT 1
);


CREATE TABLE dbo.Empleado (
    IdEmpleado INT IDENTITY(1,1) PRIMARY KEY,
    IdRol INT NOT NULL REFERENCES dbo.Rol(IdRol),
    Nombres NVARCHAR(90) NOT NULL,
    Apellidos NVARCHAR(90) NOT NULL,
    TipoDocumento NVARCHAR(20) NOT NULL DEFAULT N'DNI'
        CHECK (TipoDocumento IN (N'DNI', N'CE', N'PASAPORTE')),
    NumeroDocumento NVARCHAR(20) NOT NULL UNIQUE,
    Telefono NVARCHAR(20) NULL,
    Correo NVARCHAR(100) NULL,
    FechaIngreso DATE NOT NULL,
    Estado NVARCHAR(20) NOT NULL
        CHECK (Estado IN (N'Activo', N'Inactivo', N'Suspendido')),
    TurnoHabitual NVARCHAR(20) NULL
        CHECK (TurnoHabitual IN (N'Apertura', N'Intermedio', N'Cierre'))
);


CREATE TABLE dbo.Cliente (
    IdCliente INT IDENTITY(1,1) PRIMARY KEY,
    Nombres NVARCHAR(90) NOT NULL,
    Apellidos NVARCHAR(100) NOT NULL,
    NumeroDocumento CHAR(8) NOT NULL UNIQUE,
    Telefono CHAR(9) NOT NULL UNIQUE,
    Correo NVARCHAR(120) NOT NULL UNIQUE,
    FechaRegistro DATETIME2(0) NOT NULL
);


CREATE TABLE dbo.Mesa (
    IdMesa INT IDENTITY(1,1) PRIMARY KEY,
    Zona NVARCHAR(50) NOT NULL
        CHECK (Zona IN (N'Piso 1', N'Piso 2')),
    NumeroMesa INT NOT NULL UNIQUE,
    Capacidad INT NOT NULL CHECK (Capacidad BETWEEN 2 AND 8)
);


CREATE TABLE dbo.Reserva (
    IdReserva INT IDENTITY(1,1) PRIMARY KEY,
    IdCliente INT NOT NULL REFERENCES dbo.Cliente(IdCliente),
    IdMesa INT NOT NULL REFERENCES dbo.Mesa(IdMesa),
    FechaReserva DATETIME2(0) NOT NULL,
    CantidadPersonas INT NOT NULL CHECK (CantidadPersonas > 0),
    Estado NVARCHAR(18) NOT NULL
        CHECK (Estado IN (N'Atendida', N'Cancelada', N'Confirmada'))
);


CREATE TABLE dbo.Categoria (
    IdCategoria INT IDENTITY(1000,1) PRIMARY KEY,
    Nombre NVARCHAR(80) NOT NULL UNIQUE,
    Descripcion NVARCHAR(150) NULL,
    Estado BIT NOT NULL
);


CREATE TABLE dbo.Producto (
    IdProducto INT IDENTITY(1000,1) PRIMARY KEY,
    IdCategoria INT NOT NULL REFERENCES dbo.Categoria(IdCategoria),
    Nombre NVARCHAR(100) NOT NULL,
    Descripcion NVARCHAR(250) NULL,
    Precio DECIMAL(12,2) NOT NULL CHECK (Precio >= 0),
    Estado NVARCHAR(20) NOT NULL
);


CREATE TABLE dbo.Proveedor (
    IdProveedor INT IDENTITY(1,1) PRIMARY KEY,
    RazonSocial NVARCHAR(120) NOT NULL,
    RUC CHAR(11) NOT NULL UNIQUE,
    Telefono CHAR(9) NOT NULL UNIQUE,
    Correo NVARCHAR(130) NOT NULL UNIQUE,
    Direccion NVARCHAR(160) NOT NULL,
    Especialidad NVARCHAR(60) NOT NULL
);


CREATE TABLE dbo.Insumo (
    IdInsumo INT IDENTITY(2000,1) PRIMARY KEY,
    Nombre NVARCHAR(120) NOT NULL UNIQUE,
    UnidadMedida NVARCHAR(16) NOT NULL,
    Stock DECIMAL(16,4) NOT NULL CHECK (Stock >= 0),
    StockMinimo DECIMAL(16,4) NOT NULL CHECK (StockMinimo >= 0),
    CostoReferencial DECIMAL(14,4) NOT NULL CHECK (CostoReferencial >= 0),
    Estado NVARCHAR(15) NOT NULL
);


CREATE TABLE dbo.ProductoInsumo (
    IdProductoInsumo INT IDENTITY(1,1) PRIMARY KEY,
    IdProducto INT NOT NULL REFERENCES dbo.Producto(IdProducto),
    IdInsumo INT NOT NULL REFERENCES dbo.Insumo(IdInsumo),
    Cantidad DECIMAL(14,4) NOT NULL CHECK (Cantidad > 0),
    UNIQUE (IdProducto, IdInsumo)
);


CREATE TABLE dbo.VarianteProducto (
    IdVariante INT IDENTITY(1,1) PRIMARY KEY,
    IdProducto INT NOT NULL REFERENCES dbo.Producto(IdProducto),
    Nombre NVARCHAR(60) NOT NULL,
    UNIQUE (IdProducto, Nombre),
    UNIQUE (IdVariante, IdProducto)
);


CREATE TABLE dbo.VarianteInsumo (
    IdVarianteInsumo INT IDENTITY(1,1) PRIMARY KEY,
    IdVariante INT NOT NULL REFERENCES dbo.VarianteProducto(IdVariante),
    IdInsumo INT NOT NULL REFERENCES dbo.Insumo(IdInsumo),
    Cantidad DECIMAL(14,4) NOT NULL CHECK (Cantidad > 0),
    UNIQUE (IdVariante, IdInsumo)
);


CREATE TABLE dbo.ProveedorInsumo (
    IdProveedor INT NOT NULL REFERENCES dbo.Proveedor(IdProveedor),
    IdInsumo INT NOT NULL REFERENCES dbo.Insumo(IdInsumo),
    PRIMARY KEY (IdProveedor, IdInsumo)
);


CREATE TABLE dbo.Compra (
    IdCompra INT IDENTITY(1,1) PRIMARY KEY,
    IdProveedor INT NOT NULL REFERENCES dbo.Proveedor(IdProveedor),
    IdEmpleado INT NOT NULL REFERENCES dbo.Empleado(IdEmpleado),
    FechaCompra DATETIME2(0) NOT NULL,
    FechaRecepcion DATETIME2(0) NULL,
    Estado NVARCHAR(14) NOT NULL
        CHECK (Estado IN (N'Registrada', N'Recibida', N'Anulada')),
    Total DECIMAL(14,2) NOT NULL CHECK (Total >= 0),
    CHECK (FechaRecepcion IS NULL OR FechaRecepcion >= FechaCompra)
);


CREATE TABLE dbo.DetalleCompra (
    IdDetalleCompra INT IDENTITY(1,1) PRIMARY KEY,
    IdCompra INT NOT NULL REFERENCES dbo.Compra(IdCompra),
    IdInsumo INT NOT NULL REFERENCES dbo.Insumo(IdInsumo),
    Cantidad DECIMAL(14,4) NOT NULL CHECK (Cantidad > 0),
    CostoUnitario DECIMAL(14,4) NOT NULL CHECK (CostoUnitario >= 0),
    Importe DECIMAL(14,2) NOT NULL CHECK (Importe >= 0)
);


CREATE TABLE dbo.MetodoPago (
    IdMetodoPago INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(60) NOT NULL UNIQUE,
    Activo BIT NOT NULL DEFAULT 1
);


CREATE TABLE dbo.Pedido (
    IdPedido INT IDENTITY(1,1) PRIMARY KEY,
    IdCliente INT NULL REFERENCES dbo.Cliente(IdCliente),
    IdEmpleado INT NOT NULL REFERENCES dbo.Empleado(IdEmpleado),
    IdRepartidor INT NULL REFERENCES dbo.Empleado(IdEmpleado),
    IdMesa INT NULL REFERENCES dbo.Mesa(IdMesa),
    DireccionEntrega NVARCHAR(250) NULL,
    FechaPedido DATETIME2(0) NOT NULL,
    FechaEntrega DATETIME2(0) NULL,
    TipoPedido NVARCHAR(12) NOT NULL
        CHECK (TipoPedido IN (N'Salon', N'Delivery', N'Recojo')),
    Estado NVARCHAR(15) NOT NULL
        CHECK (Estado IN (N'Entregado', N'Cancelado', N'Pendiente', N'Preparando', N'Listo')),
    FechaUltimoEstado DATETIME2(0) NULL,
    Total DECIMAL(12,2) NOT NULL CHECK (Total >= 0),

    CHECK (
        (TipoPedido = N'Salon'
            AND IdMesa IS NOT NULL
            AND DireccionEntrega IS NULL
            AND IdRepartidor IS NULL)
        OR
        (TipoPedido = N'Delivery'
            AND IdMesa IS NULL
            AND DireccionEntrega IS NOT NULL
            AND IdRepartidor IS NOT NULL
            AND IdCliente IS NOT NULL)
        OR
        (TipoPedido = N'Recojo'
            AND IdMesa IS NULL
            AND DireccionEntrega IS NULL
            AND IdRepartidor IS NULL)
    ),

    CHECK (
        (Estado = N'Entregado'
            AND FechaEntrega IS NOT NULL
            AND FechaEntrega >= FechaPedido)
        OR
        (Estado <> N'Entregado'
            AND FechaEntrega IS NULL)
    )
);


CREATE TABLE dbo.DetallePedido (
    IdDetallePedido INT IDENTITY(1,1) PRIMARY KEY,
    IdPedido INT NOT NULL REFERENCES dbo.Pedido(IdPedido),
    IdProducto INT NOT NULL REFERENCES dbo.Producto(IdProducto),
    IdVariante INT NULL,
    Cantidad INT NOT NULL CHECK (Cantidad > 0),
    PrecioUnitario DECIMAL(12,2) NOT NULL CHECK (PrecioUnitario >= 0),
    Importe DECIMAL(14,2) NOT NULL CHECK (Importe >= 0),
    FOREIGN KEY (IdVariante, IdProducto)
        REFERENCES dbo.VarianteProducto(IdVariante, IdProducto)
);


CREATE TABLE dbo.Venta (
    IdVenta INT IDENTITY(1,1) PRIMARY KEY,
    IdPedido INT NOT NULL UNIQUE REFERENCES dbo.Pedido(IdPedido),
    IdMetodoPago INT NOT NULL REFERENCES dbo.MetodoPago(IdMetodoPago),
    FechaVenta DATETIME2(0) NOT NULL,
    SubtotalSinIGV DECIMAL(14,2) NOT NULL CHECK (SubtotalSinIGV >= 0),
    IGV DECIMAL(14,2) NOT NULL CHECK (IGV >= 0),
    Total DECIMAL(14,2) NOT NULL CHECK (Total >= 0),
    Estado NVARCHAR(12) NOT NULL
        CHECK (Estado IN (N'Pagada', N'Anulada')),
    CHECK (ABS(Total - (SubtotalSinIGV + IGV)) <= 0.01)
);


CREATE TABLE dbo.MovimientoInventario (
    IdMovimiento INT IDENTITY(1,1) PRIMARY KEY,
    IdInsumo INT NOT NULL REFERENCES dbo.Insumo(IdInsumo),
    IdDetallePedido INT NULL REFERENCES dbo.DetallePedido(IdDetallePedido),
    IdDetalleCompra INT NULL REFERENCES dbo.DetalleCompra(IdDetalleCompra),
    FechaMovimiento DATETIME2(0) NOT NULL,
    TipoMovimiento NVARCHAR(12) NOT NULL
        CHECK (TipoMovimiento IN (N'Inicial', N'Entrada', N'Consumo')),
    Cantidad DECIMAL(14,4) NOT NULL CHECK (Cantidad > 0),
    CostoUnitario DECIMAL(14,4) NOT NULL CHECK (CostoUnitario >= 0),

    CHECK (
        (TipoMovimiento = N'Inicial'
            AND IdDetallePedido IS NULL
            AND IdDetalleCompra IS NULL)
        OR
        (TipoMovimiento = N'Entrada'
            AND IdDetalleCompra IS NOT NULL
            AND IdDetallePedido IS NULL)
        OR
        (TipoMovimiento = N'Consumo'
            AND IdDetallePedido IS NOT NULL
            AND IdDetalleCompra IS NULL)
    )
);
GO
