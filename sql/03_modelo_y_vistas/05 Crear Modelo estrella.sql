
USE BD_RestaurantBueyGrill;
GO


CREATE TABLE dim.DimFecha (
    FechaKey INT PRIMARY KEY,
    Fecha DATE NOT NULL UNIQUE,
    Anio SMALLINT NOT NULL,
    Trimestre TINYINT NOT NULL,
    Mes TINYINT NOT NULL,
    NombreMes NVARCHAR(20) NOT NULL,
    Dia TINYINT NOT NULL,
    NumeroDiaSemana TINYINT NOT NULL,
    NombreDia NVARCHAR(15) NOT NULL
);


CREATE TABLE dim.DimProducto (
    ProductoKey INT IDENTITY(1,1) PRIMARY KEY,
    IdProductoOrigen INT NOT NULL UNIQUE,
    IdCategoriaOrigen INT NOT NULL,
    Categoria NVARCHAR(80) NOT NULL,
    NombreProducto NVARCHAR(100) NOT NULL,
    PrecioMenuConIGV DECIMAL(12,2) NOT NULL,
    Estado NVARCHAR(20) NOT NULL
);


CREATE TABLE dim.DimCliente (
    ClienteKey INT IDENTITY(1,1) PRIMARY KEY,
    IdClienteOrigen INT NOT NULL UNIQUE,
    NombreCliente NVARCHAR(195) NOT NULL,
    FechaRegistro DATE NULL
);


CREATE TABLE dim.DimEmpleado (
    EmpleadoKey INT IDENTITY(1,1) PRIMARY KEY,
    IdEmpleadoOrigen INT NOT NULL UNIQUE,
    NombreEmpleado NVARCHAR(190) NOT NULL,
    Rol NVARCHAR(70) NOT NULL
);


CREATE TABLE dim.DimProveedor (
    ProveedorKey INT IDENTITY(1,1) PRIMARY KEY,
    IdProveedorOrigen INT NOT NULL UNIQUE,
    Proveedor NVARCHAR(120) NOT NULL,
    Especialidad NVARCHAR(60) NOT NULL
);


CREATE TABLE dim.DimInsumo (
    InsumoKey INT IDENTITY(1,1) PRIMARY KEY,
    IdInsumoOrigen INT NOT NULL UNIQUE,
    Insumo NVARCHAR(120) NOT NULL,
    UnidadMedida NVARCHAR(16) NOT NULL
);


CREATE TABLE dim.DimMetodoPago (
    MetodoPagoKey INT IDENTITY(1,1) PRIMARY KEY,
    IdMetodoPagoOrigen INT NOT NULL UNIQUE,
    MetodoPago NVARCHAR(60) NOT NULL
);


CREATE TABLE fact.FactVentas (
    VentaDetalleKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    IdDetallePedidoOrigen INT NOT NULL UNIQUE,
    IdPedidoOrigen INT NOT NULL,
    IdVentaOrigen INT NOT NULL,
    FechaKey INT NOT NULL REFERENCES dim.DimFecha(FechaKey),
    ProductoKey INT NOT NULL REFERENCES dim.DimProducto(ProductoKey),
    ClienteKey INT NOT NULL REFERENCES dim.DimCliente(ClienteKey),
    EmpleadoKey INT NOT NULL REFERENCES dim.DimEmpleado(EmpleadoKey),
    MetodoPagoKey INT NOT NULL REFERENCES dim.DimMetodoPago(MetodoPagoKey),
    TipoPedido NVARCHAR(12) NOT NULL,
    EstadoPedido NVARCHAR(15) NOT NULL,
    EstadoVenta NVARCHAR(12) NOT NULL,
    Cantidad INT NOT NULL CHECK (Cantidad > 0),
    PrecioUnitarioConIGV DECIMAL(12,2) NOT NULL,
    ImporteSinIGV DECIMAL(14,2) NOT NULL,
    IGV DECIMAL(14,2) NOT NULL,
    ImporteConIGV DECIMAL(14,2) NOT NULL
);


CREATE TABLE fact.FactCompras (
    CompraDetalleKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    IdDetalleCompraOrigen INT NOT NULL UNIQUE,
    IdCompraOrigen INT NOT NULL,
    FechaKey INT NOT NULL REFERENCES dim.DimFecha(FechaKey),
    ProveedorKey INT NOT NULL REFERENCES dim.DimProveedor(ProveedorKey),
    InsumoKey INT NOT NULL REFERENCES dim.DimInsumo(InsumoKey),
    EstadoCompra NVARCHAR(14) NOT NULL,
    Cantidad DECIMAL(14,4) NOT NULL,
    CostoUnitario DECIMAL(14,4) NOT NULL,
    ImporteCompra DECIMAL(14,2) NOT NULL
);


CREATE TABLE fact.FactConsumoInsumos (
    ConsumoKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    IdMovimientoOrigen INT NOT NULL UNIQUE,
    IdDetallePedidoOrigen INT NOT NULL,
    IdPedidoOrigen INT NOT NULL,
    FechaKey INT NOT NULL REFERENCES dim.DimFecha(FechaKey),
    ProductoKey INT NOT NULL REFERENCES dim.DimProducto(ProductoKey),
    InsumoKey INT NOT NULL REFERENCES dim.DimInsumo(InsumoKey),
    EstadoPedido NVARCHAR(15) NOT NULL,
    CantidadProducto INT NOT NULL,
    CantidadInsumo DECIMAL(14,4) NOT NULL,
    CostoEstimado DECIMAL(14,2) NOT NULL
);

