# Sistema de Gestión de Gimnasio

![PostgreSQL Logo](https://upload.wikimedia.org/wikipedia/commons/thumb/2/29/Postgresql_elephant.svg/1200px-Postgresql_elephant.svg.png)

Un sistema de base de datos PostgreSQL completo diseñado para la gestión de gimnasios, que incluye membresías de usuarios, reservas de clases, seguimiento de equipos y procesamiento de pagos.

## Descripción General del Proyecto

Este sistema de base de datos proporciona una solución completa para la gestión de operaciones de gimnasio, incluyendo:

- Gestión de usuarios y membresías
- Programación y reserva de clases
- Gestión de personal e instructores
- Seguimiento del mantenimiento de equipos
- Procesamiento de pagos e informes
- Soporte para múltiples ubicaciones (sucursales)

El sistema implementa características avanzadas de PostgreSQL como procedimientos almacenados, funciones definidas por el usuario, vistas y disparadores para garantizar la integridad de los datos y el cumplimiento de la lógica de negocio.

## Estructura de la Base de Datos

![Modelo Relacional](https://www.postgresqltutorial.com/wp-content/uploads/2018/03/PostgreSQL-Sample-Database.png)

### Tablas Principales

- **sedes**: Ubicaciones/sucursales del gimnasio
- **usuarios**: Miembros/clientes del gimnasio
- **trabajadores**: Personal e instructores
- **roles**: Roles y permisos del personal
- **membresias**: Planes de membresía y precios
- **clases**: Tipos de clases disponibles
- **horarios**: Horario de clases con control de capacidad
- **reserva_clases**: Reservas de clases
- **maquinas**: Inventario de equipos del gimnasio
- **estados**: Seguimiento del estado de los equipos
- **pagos**: Registros de pagos
- **metodos_pagos**: Métodos de pago

### Relaciones del Esquema

La base de datos implementa un esquema relacional con:
- Relaciones uno a muchos (por ejemplo, usuarios a reservas)
- Relaciones muchos a muchos (por ejemplo, usuarios a membresías)
- Restricciones de clave foránea para mantener la integridad referencial
- Restricciones de verificación para hacer cumplir las reglas de negocio

## Características y Funcionalidades

![PostgreSQL Functions](https://www.postgresql.org/media/img/about/press/elephant.png)

### Funciones

1. **total_pagos_usuarios**: Devuelve el total de pagos realizados por un usuario específico
2. **clases_reservadas**: Devuelve todas las reservas de clases para un usuario específico
3. **estado_membres**: Verifica el estado de la membresía (VIGENTE, A PUNTO DE VENCER, VENCIDA, SIN MEMBRESIA)

### Procedimientos Almacenados

1. **registrar_usuario_completo**: Procedimiento complejo para registrar nuevos miembros con membresía y pago en una sola transacción
2. **cancelar_reserva_clase**: Procesa cancelaciones de clases con validación exhaustiva (restricciones de tiempo, estado de membresía)

### Vistas

1. **vista_usuarios**: Vista simple que muestra usuarios con su sucursal asociada
2. **vista_reservas_por_clase**: Muestra la popularidad de las clases mediante el recuento de reservas
3. **vista_historial_clases**: Historial detallado de clases para cada usuario
4. **vista_estado_usuarios**: Muestra el estado de membresía del usuario con descripción formateada

### Disparadores (Triggers)

1. **trigger_validar_cupos**: Disparador BEFORE que valida la capacidad de las clases
2. **actualizar_estado_maquinas**: Disparador AFTER que programa el mantenimiento del equipo según la popularidad de las clases

## Implementación Técnica

- **Control de Transacciones**: Operaciones que cumplen con ACID con un manejo adecuado de errores
- **Validación de Datos**: Validación de entrada y cumplimiento de reglas de negocio
- **Manejo de Errores**: Mensajes de error completos y manejo de excepciones
- **Diseño Escalable**: Soporte para múltiples ubicaciones de gimnasio y expansión futura

## Instalación y Configuración

![PostgreSQL Installation](https://miro.medium.com/max/4800/1*oNwwfLHGSZZK_tFJfTY7iA.webp)

1. Crear una nueva base de datos PostgreSQL
2. Ejecutar el script DDL para crear el esquema de la base de datos:
   ```sql
   psql -U tu_usuario -d tu_base_de_datos -f ddl.sql
   ```
3. Importar datos iniciales:
   ```sql
   psql -U tu_usuario -d tu_base_de_datos -f data.sql
   ```
4. Configurar funciones, procedimientos, vistas y disparadores:
   ```sql
   psql -U tu_usuario -d tu_base_de_datos -f lab.sql
   ```

## Ejemplos de Uso

### Registrar un Nuevo Usuario con Membresía

```sql
DO $$
DECLARE
  v_id_usuario INT;
BEGIN
  CALL registrar_usuario_completo(
    'Ana Gómez', 
    'ana.gomez@example.com',
    1, -- id_sede
    '5551234567',
    '1990-05-15', -- fecha_nacimiento
    2, -- id_membresia
    'Tarjeta de crédito', -- metodo_pago
    v_id_usuario
  );
  RAISE NOTICE 'Usuario registrado con ID: %', v_id_usuario;
END $$;
```

### Verificar el Estado de Membresía

```sql
SELECT id, nombre, estado_membres(id) FROM usuarios;
```

### Obtener Datos de Reservas de Clases

```sql
SELECT * FROM vista_reservas_por_clase;
```

## Consideraciones de Rendimiento

- Índices en columnas consultadas con frecuencia
- Vistas optimizadas usando JOINs apropiados
- Control de transacciones para operaciones multi-tabla
- Normalización adecuada de la base de datos

## Licencia

Este proyecto ha sido creado con fines educativos.

---

*Esta documentación es parte del proyecto de Laboratorio de Bases de Datos en la Universidad del Valle de Guatemala.*
