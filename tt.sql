create or replace TRIGGER check_estacion_plato
BEFORE INSERT ON DETALLE_PLATO
FOR EACH ROW
DECLARE
    v_estacion_plato VARCHAR2(25);
    v_fecha_factura DATE;
    v_estacion_factura VARCHAR2(25);
BEGIN
    -- Obtener la estación del plato
    SELECT m.estacion
    INTO v_estacion_plato
    FROM PLATO p
    JOIN MENU m ON p.id_menu = m.id
    WHERE p.id = :NEW.id_plato;

    -- Obtener la fecha de la factura
    SELECT f.fecha
    INTO v_fecha_factura
    FROM FACTURA f
    WHERE f.id = :NEW.id_factura;

    -- Determinar la estación basada en la fecha de la factura
    SELECT CASE
               WHEN (EXTRACT(MONTH FROM v_fecha_factura) = 12 AND EXTRACT(DAY FROM v_fecha_factura) >= 22)
                    OR (EXTRACT(MONTH FROM v_fecha_factura) = 1)
                    OR (EXTRACT(MONTH FROM v_fecha_factura) = 2)
                    OR (EXTRACT(MONTH FROM v_fecha_factura) = 3 AND EXTRACT(DAY FROM v_fecha_factura) <= 20) THEN 'invierno'
               WHEN (EXTRACT(MONTH FROM v_fecha_factura) = 3 AND EXTRACT(DAY FROM v_fecha_factura) >= 21)
                    OR (EXTRACT(MONTH FROM v_fecha_factura) = 4)
                    OR (EXTRACT(MONTH FROM v_fecha_factura) = 5)
                    OR (EXTRACT(MONTH FROM v_fecha_factura) = 6 AND EXTRACT(DAY FROM v_fecha_factura) <= 21) THEN 'primavera'
               WHEN (EXTRACT(MONTH FROM v_fecha_factura) = 6 AND EXTRACT(DAY FROM v_fecha_factura) >= 22)
                    OR (EXTRACT(MONTH FROM v_fecha_factura) = 7)
                    OR (EXTRACT(MONTH FROM v_fecha_factura) = 8)
                    OR (EXTRACT(MONTH FROM v_fecha_factura) = 9 AND EXTRACT(DAY FROM v_fecha_factura) <= 23) THEN 'verano'
               ELSE 'Otoño'
           END
    INTO v_estacion_factura
    FROM DUAL;

    -- Verificar que la estación del plato y la estación de la factura coincidan
    IF v_estacion_plato != v_estacion_factura THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Error: El plato pertenece a la estación ''' || v_estacion_plato || '''. ' ||
            'La factura está en la estación ''' || v_estacion_factura || '''.'
        );
    END IF;
END;


INSERT INTO FACTURA VALUES (32, TO_DATE('05/07/2022', 'DD/MM/YYYY'),
3, 2);

INSERT INTO DETALLE_PLATO VALUES (32, 1);
SELECT * FROM DETALLE_PLATO