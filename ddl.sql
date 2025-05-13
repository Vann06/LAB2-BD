-- ddl.sql

-- Tabla de sedes
CREATE TABLE sedes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion TEXT NOT NULL,
    telefono VARCHAR(15)
);

-- Tabla de usuarios
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    id_sede INT REFERENCES sedes(id),
    telefono VARCHAR(15),
    fecha_nacimiento DATE NOT NULL,
    fecha_registro DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Tabla de roles
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nombre_rol VARCHAR(100) NOT NULL,
    descripcion TEXT
);

-- Tabla de trabajadores
CREATE TABLE trabajadores (
    id SERIAL PRIMARY KEY,
    id_sede INT REFERENCES sedes(id),
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(15),
    id_rol INT REFERENCES roles(id)
);

-- Tabla de membresias
CREATE TABLE membresias (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio NUMERIC(10, 2) NOT NULL CHECK (precio > 0),
    duracion_dias INT NOT NULL CHECK (duracion_dias > 0)
);

-- Tabla intermedia de usuarios y membresías
CREATE TABLE usuarios_membresias (
    id SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL REFERENCES usuarios(id),
    id_membresia INT NOT NULL REFERENCES membresias(id),
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    CHECK (fecha_fin > fecha_inicio)
);

-- Tabla de clases
CREATE TABLE clases (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT
);

-- Tabla de horarios
CREATE TABLE horarios (
    id SERIAL PRIMARY KEY,
    id_sede INT REFERENCES sedes(id),
    id_clase INT REFERENCES clases(id),
    id_trabajador INT REFERENCES trabajadores(id),
    fecha DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    cupo_max INT NOT NULL CHECK (cupo_max > 0),
    CHECK (hora_fin > hora_inicio)
);

-- Tabla de reservas de clases
CREATE TABLE reserva_clases (
    id SERIAL PRIMARY KEY,
    id_usuario INT REFERENCES usuarios(id),
    id_horario INT REFERENCES horarios(id),
    fecha_reserva TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (id_usuario, id_horario)
);

-- Tabla de metodos de pago
CREATE TABLE metodos_pagos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

-- Tabla de pagos
CREATE TABLE pagos (
    id SERIAL PRIMARY KEY,
    id_usuario INT REFERENCES usuarios(id),
    monto NUMERIC(10, 2) NOT NULL CHECK (monto > 0),
    fecha_pago TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metodo_pago INT REFERENCES metodos_pagos(id)
);

-- Tabla de estados de maquinas
CREATE TABLE estados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

-- Tabla de maquinas
CREATE TABLE maquinas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    id_sede INT REFERENCES sedes(id),
    estado INT REFERENCES estados(id),
    precio NUMERIC(10, 2) NOT NULL CHECK (precio > 0)
);
