/*1-Crear una función que retorne una tabla con toda la información de los pasajeros,
además, la tabla debe incluir cuantas reservan ha realizado cada pasajero entre dos
fechas que serán ingresadas como parámetros de la función. La función también debe
incluir el porcentaje de reservas de cada pasajero con respecto a todas las reservas
acumuladas entre las dos fechas.*/

CREATE OR REPLACE TYPE t_passenger_row AS OBJECT(
    id_pasajero INT,
    pasajero_nombre VARCHAR2(50),
    pasajero_identificacion VARCHAR2(64),
	pasajero_fecha_nacimiento DATE,
	pasajero_email VARCHAR2(50),
	pasajero_clave VARCHAR2(32),
	pasajero_id_pais INT,
	pasajero_puntos_viajero_frecuente INT,
    total_reservas INT,
    porcentaje_reservas FLOAT
);

CREATE OR REPLACE TYPE t_passenger_collection AS TABLE OF t_passenger_row;

CREATE OR REPLACE FUNCTION get_passenger_info (
    fecha_inicio IN DATE,
    fecha_fin IN DATE
) 
RETURN t_passenger_collection
IS
    passenger_info t_passenger_collection;
    total_reservas NUMBER;
BEGIN

    SELECT COUNT(*)
    INTO total_reservas
    FROM RESERVA
    WHERE fecha_reserva BETWEEN fecha_inicio AND fecha_fin;
    
    SELECT t_passenger_row(
        p.id,                         
        p.nombre,                     
        p.identificacion,
        p.fecha_nacimiento,
        p.email,
        p.clave,
        p.id_pais,
        p.puntos_viajero_frecuente,
        COUNT(r.id),                  
        ROUND((COUNT(r.id) * 100) / total_reservas, 2)  
    )
    BULK COLLECT INTO passenger_info
    FROM PASAJERO p
    LEFT JOIN RESERVA r ON p.id = r.id_pasajero 
    AND r.fecha_reserva BETWEEN fecha_inicio AND fecha_fin
    GROUP BY
        p.id,                         
        p.nombre,                     
        p.identificacion,
        p.fecha_nacimiento,
        p.email,
        p.clave,
        p.id_pais,
        p.puntos_viajero_frecuente 
        ORDER BY p.id; 
    RETURN passenger_info;
END;

SELECT * FROM TABLE (get_passenger_info(TO_DATE('2023-04-05', 'YYYY-MM-DD'), TO_DATE('2023-04-18', 'YYYY-MM-DD')));

/*2-Crear una función (y solo una) que calcule los puntos de viajero frecuente 
generados por cada una de las reservas registradas en la tabla reserva. 
La función no recibe ningún parámetro y debe retornar una tabla con el detalle 
de las reservas actuales, la tabla retornada debe mostrar el detalle de la reserva, 
los puntos calculados por cada criterio, y el total de puntos acumulados por todos 
los criterios. La siguiente tabla detalla los criterios.*/
CREATE OR REPLACE TYPE t_booking_row AS OBJECT(
    id_reserva INT,
	reserva_costo FLOAT,
	fecha_reserva DATE,
	reserva_id_pasajero INT,
	reserva_id_viaje INT,
	reserva_id_clase INT,
    puntos_costo_reserva INT,
    puntos_clase_reservada INT,
    puntos_servicios_extra INT,
    puntos_total INT
);

CREATE OR REPLACE TYPE t_booking_collection AS TABLE OF t_booking_row;


CREATE OR REPLACE FUNCTION get_booking_info 
RETURN t_booking_collection
IS
    booking_info t_booking_collection;
BEGIN
    booking_info := t_booking_collection();

    SELECT t_booking_row(
        r.id,                        
        r.costo,                     
        r.fecha_reserva,             
        r.id_pasajero,              
        r.id_viaje,                  
        r.id_clase,                  

        CASE 
            WHEN r.costo < 60 THEN 2
            WHEN r.costo BETWEEN 60 AND 80 THEN 3
            ELSE 5
        END,

        CASE 
            /* por la tilde en la base de datos que esta en el ecampus causaba problema 
            porque esta como 'Econ mica, por esa razon se la quite y actualice el campo en 
            la base como 'Economica' sin tilde para poder probar*/
            WHEN c.clase = 'Economica' THEN 5
            WHEN c.clase = 'Ejecutiva' THEN 6
            WHEN c.clase = 'Primera clase' THEN 7
        END,

        NVL(e.total_extra, 0) * 5, -- esta funcion fue utilizada para evaluar si es que existe un campo que no tiene valor se reemplaza con 0

        (
            CASE 
                WHEN r.costo < 60 THEN 2
                WHEN r.costo BETWEEN 60 AND 80 THEN 3
                ELSE 5
            END +
            CASE 
                WHEN c.clase = 'Economica' THEN 5
                WHEN c.clase = 'Ejecutiva' THEN 6
                WHEN c.clase = 'Primera clase' THEN 7
            END +
            NVL(e.total_extra, 0) * 5 -- esta funcion fue utilizada para evaluar si es que existe un campo que no tiene valor se reemplaza con 0
        ) 
    )
    BULK COLLECT INTO booking_info
    FROM RESERVA r
    LEFT JOIN CLASE c ON r.id_clase = c.id
    LEFT JOIN (

        SELECT id_reserva, COUNT(*) AS total_extra
        FROM EXTRA
        GROUP BY id_reserva
    ) e ON e.id_reserva = r.id
    ORDER BY r.id;

    RETURN booking_info;
END;
SELECT * FROM TABLE(get_booking_info());
