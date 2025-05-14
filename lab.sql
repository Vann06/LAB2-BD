-- lab.sql


-------------------- 3 Funciones definidas por el usuario ---------------

-- funcion que retorne valor escalar
-- retorna el total de pagos realizados por un usuario
CREATE OR REPLACE FUNCTION total_pagos_usuarios(p_id_usuario)
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



-- actualizacion o eliminación con validaciones 




------------------------- 4 Vistas -------------------
-- vista simple

-- JOIN y GROUP BY

-- expresiones como CASE, COALESCE, etc.



------------------------- 2 triggers  ---------------


-- BEFORE


-- AFTER