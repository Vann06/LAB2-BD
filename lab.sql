-- lab.sql


-------------------- 3 Funciones definidas por el usuario ---------------

-- funcion que retorne valor escalar
-- retorna el total de pagos realizados por un usuario
CREATE OR REPLACE FUNCTION total_pagos_usuarios(p_id_usuario INT)
RETURNS NUMERIC(10,2) as $$
DECLARE
    total NUMERIC(10,2);
BEGIN 
    SELECT COALESCE(SUM(monto),0)
    INTO total
    FROM pagos 
    WHERE id_usuario = p_id_usuario;

    RETURN total;
END;
$$ LANGUAGE plpgsql;


-- funcion que retorne un conjunto de resultados
-- retorna las clases reservadas por un usuario
CREATE OR REPLACE FUNCTION clases_reservadas(p_id_usuario INT)
RETURNS TABLE(nombre_clase VARCHAR, fecha DATE, hora_inicio TIME, hora_fin TIME) as $$
BEGIN 
    RETURN QUERY 
    SELECT c.nombre, h.fecha, h.hora_inicio, h.hora_fin
    FROM reserva_clases rc
    JOIN horarios h ON rc.id_horario = h.id
    JOIN clases c ON h.id_clase = c.id
    WHERE rc.id_usuario = p_id_usuario;
END;
$$ LANGUAGE plpgsql;

-- funcion con multiples parametros o logica condicional 
-- verifica el estado de la ultima membresia de un usuario
CREATE OR REPLACE FUNCTION estado_membres(p_id_usuario INT)
RETURNS VARCHAR AS $$
DECLARE
    estado VARCHAR;
    fecha_fin DATE;
BEGIN 
    SELECT um.fecha_fin
    INTO fecha_fin
    FROM usuarios_membresias um
    WHERE um.id_usuario = p_id_usuario
    ORDER BY fecha_fin DESC
    LIMIT 1;

    IF fecha_fin IS NULL THEN
        RETURN 'SIN MEMBRESIA';
    END IF;

    IF fecha_fin < CURRENT_DATE THEN
        estado := 'VENCIDA';
    ELSIF fecha_fin >= CURRENT_DATE AND fecha_fin < CURRENT_DATE + INTERVAL '1 month' THEN
        estado := 'A PUNTO DE VENCER';
    ELSE
        estado := 'VIGENTE';
    END IF;

    RETURN estado;
END;
$$ LANGUAGE plpgsql;



-------------------- 2 Procedimientos almacenados ---------------


-- inserciones complejas
CREATE OR REPLACE PROCEDURE registrar_usuario_completo(
    p_nombre VARCHAR,
    p_correo VARCHAR,
    p_id_sede INT,
    p_telefono VARCHAR,
    p_fecha_nacimiento DATE,
    p_id_membresia INT,
    p_metodo_pago VARCHAR,
    OUT p_id_usuario INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_fecha_registro DATE:= CURRENT_DATE;
    v_fecha_inicio DATE:= CURRENT_DATE;
    v_duracion_dias INT;
    v_fecha_fin DATE;
    v_precio NUMERIC(10,2);
    v_id_metodo_pago INT;
BEGIN
    BEGIN
        INSERT INTO usuarios(nombre, correo, id_sede, telefono, fecha_nacimiento, fecha_registro)
        VALUES(p_nombre, p_correo, p_id_sede, p_telefono, p_fecha_nacimiento, v_fecha_registro)
        RETURNING id INTO p_id_usuario;

        SELECT duracion_dias, precio INTO v_duracion_dias, v_precio
        FROM membresias 
        WHERE id = p_id_membresia;

        v_fecha_fin := v_fecha_inicio + (v_duracion_dias || ' days')::INTERVAL;

        INSERT INTO usuarios_membresias(id_usuario, id_membresia, fecha_inicio, fecha_fin)
        VALUES(p_id_usuario, p_id_membresia, v_fecha_inicio, v_fecha_fin);

        SELECT id INTO v_id_metodo_pago
        FROM metodos_pagos
        WHERE nombre = p_metodo_pago;

        IF v_id_metodo_pago IS NULL THEN
                SELECT id INTO v_id_metodo_pago 
                FROM metodos_pagos
                WHERE nombre = 'Efectivo';
        END IF;

    INSERT INTO pagos(id_usuario, monto, fecha_pago, metodo_pago)
    VALUES(p_id_usuario, v_precio, v_fecha_registro, v_id_metodo_pago);

    COMMIT;

     RAISE NOTICE 'Usuario % registrado exitosamente con ID %', p_nombre, p_id_usuario;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error al registrar usuario: %', SQLERRM;
    END;
END;
$$;


-- actualizacion o eliminación con validaciones 

CREATE OR REPLACE PROCEDURE cancelar_reserva_clase(
    p_id_reserva INT, 
    p_id_usuario INT,
    OUT p_resultado VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_fecha_clase DATE;
    v_hora_inicio TIME;
    v_tiempo_actual TIMESTAMP := NOW();
    v_propietario_reserva INT;
    v_estado_membresia VARCHAR;
BEGIN
    SELECT rc.id_usuario, h.fecha, h.hora_inicio
    INTO v_propietario_reserva, v_fecha_clase, v_hora_inicio
    FROM reserva_clases rc
    JOIN horarios h ON rc.id_horario = h.id
    WHERE rc.id = p_id_reserva;

    IF v_propietario_reserva IS NULL THEN
        p_resultado := 'ERROR: LA RESERVA NO EXISTE';
        RETURN;
    END IF;

    IF v_propietario_reserva != p_id_usuario THEN
        p_resultado := 'ERROR: LA RESERVA NO COINCIDE CON EL USUARIO INDICADO';
        RETURN;
    END IF;

    IF (v_fecha_clase < CURRENT_DATE) OR 
       (v_fecha_clase = CURRENT_DATE AND v_hora_inicio <= CURRENT_TIME) THEN
        p_resultado := 'Error: No se puede cancelar una clase que ya pasó o está en curso';
        RETURN;
    END IF;

    IF (v_fecha_clase || ' ' || v_hora_inicio)::TIMESTAMP - v_tiempo_actual < INTERVAL '24 hours' THEN
        p_resultado := 'ERROR: Las cancelaciones deben hacerse con al menos 24 horas de anticipación';
        RETURN;
    END IF;
    
    SELECT estado_membres(p_id_usuario) INTO v_estado_membresia;
    
    IF v_estado_membresia != 'VIGENTE' AND v_estado_membresia != 'A PUNTO DE VENCER' THEN
        p_resultado := 'Error: No se puede cancelar la reserva porque la membresía está vencida';
        RETURN;
    END IF;

    BEGIN 
        DELETE FROM reserva_clases WHERE id = p_id_reserva;
        IF FOUND THEN
            p_resultado := 'Reserva cancelada exitosamente';
        ELSE
            p_resultado := 'Error: No se pudo cancelar la reserva';
        END IF;
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_resultado := 'Error: ' || SQLERRM;
    END;
END;
$$;



------------------------- 4 Vistas -------------------
-- vista simple
-- vista_usuarios con id, nombre, correo, sede y fecha_registro
CREATE OR REPLACE VIEW vista_usuarios AS
SELECT u.id, u.nombre, u.correo, s.nombre AS sede, u.fecha_registro
FROM usuarios u
LEFT JOIN sedes s ON u.id_sede = s.id;


-- JOIN y GROUP BY
-- contador de reservas por cada clase 
CREATE  OR REPLACE VIEW vista_reservas_por_clase AS
SELECT c.nombre AS clase, COUNT(rc.id) AS total_reservas
FROM reserva_clases rc
JOIN horarios h ON rc.id_horario = h.id
JOIN clases c ON h.id_clase = c.id
GROUP BY c.nombre
ORDER BY total_reservas DESC;


-- JOIN y GROUP BY
--Vista que muestra el historial de clases por usuario
CREATE OR REPLACE VIEW vista_historial_clases AS
SELECT u.id as id_usuario, u.nombre AS nombre_usuario, c.nombre AS clase, h.fecha, h.hora_inicio, h.hora_fin, t.nombre AS instructor, s.nombre AS sede
FROM 
    usuarios u 
JOIN reserva_clases rc ON u.id = rc.id_usuario
JOIN horarios h ON rc.id_horario = h.id
JOIN clases c ON h.id_clase = c.id
JOIN trabajadores t ON h.id_trabajador = t.id
JOIN sedes s ON h.id_sede = s.id
ORDER BY 
    u.id, h.fecha DESC, h.hora_inicio;


-- expresiones como CASE, COALESCE, etc.
--Vista que clasifica usuarios según su estado de membresía
CREATE OR REPLACE VIEW vista_estado_usuarios AS
SELECT 
    u.id, 
    u.nombre, 
    u.correo,
    CASE
        WHEN estado_membres(u.id) = 'VIGENTE' THEN 'Cliente Activo'
        WHEN estado_membres(u.id) = 'A PUNTO DE VENCER' THEN 'Requiere Renovacion'
        WHEN estado_membres(u.id) = 'VENCIDA' THEN 'Cliente Inactivo'
        ELSE 'Sin Membresia'
    END AS estado_cliente,
    COALESCE(m.nombre, 'Ninguna') AS tipo_membresia,
    COALESCE(TO_CHAR(um.fecha_fin, 'DD/MM/YYYY'), 'N/A') AS fecha_vencimiento
FROM 
    usuarios u
LEFT JOIN (
    SELECT um1.*
    FROM usuarios_membresias um1
    INNER JOIN (
        SELECT id_usuario, MAX(fecha_fin) as max_fecha_fin
        FROM usuarios_membresias
        GROUP BY id_usuario
    ) um2 ON um1.id_usuario = um2.id_usuario AND um1.fecha_fin = um2.max_fecha_fin
) um ON u.id = um.id_usuario
LEFT JOIN membresias m ON um.id_membresia = m.id;


------------------------- 2 triggers  ---------------


-- BEFORE
-- validar que existan cupos en una clase antes de insertar una reserva
CREATE OR REPLACE FUNCTION trigger_validar_cupos()
RETURNS TRIGGER AS $$
DECLARE
    cupo_actual INT;
    cupo_max INT;
BEGIN   
    SELECT COUNT(*) INTO cupo_actual
    FROM reserva_clases
    WHERE id_horario = NEW.id_horario;

    SELECT h.cupo_max INTO cupo_max
    FROM horarios h
    WHERE h.id = NEW.id_horario;

    IF cupo_actual >= cupo_max THEN
        RAISE EXCEPTION 'No hay cupos disponibles para la clase %', NEW.id_horario;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validar_cupos
BEFORE INSERT ON reserva_clases
FOR EACH ROW
EXECUTE FUNCTION trigger_validar_cupos();



-- AFTER
--Registra y actualiza estado de máquinas cuando una clase es muy reservada
CREATE OR REPLACE FUNCTION actualizar_estado_maquinas()
RETURNS TRIGGER AS $$
DECLARE v_id_clase INT; v_nombre_clase VARCHAR; v_conteo_reservas INT; v_mantenimiento INT:=10;
BEGIN 
    SELECT h.id_clase, c.nombre INTO v_id_clase, v_nombre_clase
    FROM horarios h
    JOIN clases c ON h.id_clase = c.id
    WHERE h.id = NEW.id_horario;

    SELECT COUNT(*) INTO v_conteo_reservas
    FROM reserva_clases rc
    JOIN horarios h ON rc.id_horario = h.id
    WHERE h.id_clase = v_id_clase;

    IF v_conteo_reservas >= v_mantenimiento THEN
        UPDATE maquinas
        SET estado = 2
        WHERE id_sede = (SELECT id_sede FROM horarios WHERE id = NEW.id_horario)
        AND estado = 1
        AND id IN(
            SELECT id FROM maquinas 
            WHERE id_sede = (SELECT id_sede FROM horarios WHERE id = NEW.id_horario)
            AND estado = 1
            LIMIT 1
        );

        RAISE NOTICE 'MANTENIMIENTO PROGRAMADO: La clase % ha alcanzado % reservas. Se ha programado mantenimiento para máquinas en la sede %',
                    v_nombre_clase, v_conteo_reservas, (SELECT id_sede FROM horarios WHERE id = NEW.id_horario);
    END IF;

    RETURN NULL;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_estado_maquinas
AFTER INSERT ON reserva_clases
FOR EACH ROW
EXECUTE FUNCTION actualizar_estado_maquinas();
