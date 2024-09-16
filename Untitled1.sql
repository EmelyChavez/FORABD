--****************************************************
-- Administraci?n de bases de datos
-- Autor: Erick Varela
-- Contacto: evarela@uca.edu.sv
-- Version: 1.0
--****************************************************

--****************************************************
-- Funciones
--****************************************************
-- Sintaxis b?sica de las funciones
/*
CREATE OR REPLACE FUNCTION <nombre_funcion> 
	(param1 TYPE, param2 TYPE, ...)
RETURN TYPE
AS 
	-- Variable declaration area
BEGIN
	-- Function body
END;
*/

--****************************************************
-- 6.1  Crear una funci?n que reciba como par?metro un numero entero mayor a cero
--      La funci?n retornar? un n?mero aleatorio entre 1 y el n?mero ingresado.

-- Seleccionar un numero aleatorio en un rango de 1 a 10
SELECT round(dbms_random.VALUE() * (10 - 1)) + 1 aleatorio FROM dual;

CREATE OR REPLACE FUNCTION get_random_between
    (n1 INT)
RETURN INT
IS
    random_number INT;
BEGIN
    SELECT ROUND(dbms_random.VALUE() * (n1 - 1)) + 1 
    INTO random_number
    FROM dual;
    RETURN random_number;
END;

-- ejecutando una funci?n
SELECT get_random_between (15) FROM DUAL;

-- eliminando funcion 
DROP FUNCTION get_random_between;


--****************************************************
-- 6.2. Funciones escalares. 
--      Crear una funci?n que reciba el id de una factura 
--      y retorne el total de la factura

-- 	Creando la consulta que se necesita para poder realizar la tarea
SELECT SUM (p.precio_unidad * df.cantidad)
FROM FACTURA F, DETALLE_FACTURA DF, PRODUCTO P
WHERE f.id = df.id_factura
    AND P.id = df.id_producto
    AND F.id = 1
GROUP BY F.id;

-- Creando funci?n
CREATE OR REPLACE FUNCTION calculate_bill_total
(bill_id INT)
RETURN FLOAT
AS
    total FLOAT;
BEGIN
    SELECT SUM (p.precio_unidad * df.cantidad)
    INTO total
    FROM FACTURA F, DETALLE_FACTURA DF, PRODUCTO P
    WHERE f.id = df.id_factura
        AND P.id = df.id_producto
        AND F.id = bill_id
    GROUP BY F.id;
    RETURN total;
END;

-- ejecutando funci?n
SELECT calculate_bill_total (2) total FROM DUAL;

-- ejecutando funci?n
SELECT id, fecha, calculate_bill_total (id) total FROM FACTURA;

--****************************************************
-- 6.3. Funciones tipo tabla.
--      Crear una funci?n que retorne el detalle de cada factura, 
--      el resultado debe mostrar el nombre del cliente, 
--      del vendedor y el total de cada factura.
   
-- 	Creando la consulta que se necesita para poder realizar la tarea
SELECT F.id id_factura, F.fecha, E.nombre empleado, C.nombre cliente, 
    calculate_bill_total (F.id) total
FROM EMPLEADO E, FACTURA F, DETALLE_FACTURA DF, PRODUCTO P, CLIENTE C
WHERE E.id = F.id_empleado 
	AND F.id = DF.id_factura
	AND P.id = DF.id_producto
    AND C.id = f.id_cliente
ORDER BY F.id ASC;

/*
NOTA:  
En Oracle para crear funciones que retornen tablas es necesario
utilizar la estructura llamada "Pipelined Table Functions"
*/       
--  Creando un objeto para contener cada fila de la tabla 
CREATE OR REPLACE TYPE t_sales_row AS OBJECT(
    id_factura INT,
    fecha DATE,
    empleado VARCHAR2(40),
    cliente VARCHAR2(40),
    total FLOAT
);

-- Creando una colecci?n para contener los objetos de tipo fila
CREATE OR REPLACE TYPE t_sales_collection AS TABLE OF t_sales_row;

CREATE OR REPLACE FUNCTION GET_SALES_DETAIL
RETURN t_sales_collection
AS
    sales_detail t_sales_collection;
BEGIN
    SELECT t_sales_row(F.id, F.fecha, E.nombre, C.nombre, calculate_bill_total (F.id))
    BULK COLLECT INTO sales_detail
    FROM EMPLEADO E, FACTURA F, DETALLE_FACTURA DF, PRODUCTO P, CLIENTE C
    WHERE E.id = F.id_empleado 
        AND F.id = DF.id_factura
        AND P.id = DF.id_producto
        AND C.id = f.id_cliente
    ORDER BY F.id ASC;
    RETURN sales_detail;
END;

-- Ejecutando funci?n
SELECT * FROM TABLE(GET_SALES_DETAIL) ORDER BY id_factura ASC;

DROP TYPE t_sales_collection;
DROP TYPE t_sales_row;
DROP FUNCTION GET_SALES_DETAIL;

--****************************************************
-- Procedimientos almacenados
--****************************************************
-- Sintaxis b?sica de los procedimientos almacenados
/*
CREATE OR REPLACE PROCEDURE <nombre> 
	(param1 IN|OUT TYPE, param2 IN|OUT TYPE...)
IS 
	-- Variable declaration area
BEGIN
	-- Function body area
EXCEPTION 
	-- Exception management area
END;
*/

--****************************************************
--  6.4.    Crear un procedimiento almacenado que reciba como par?metro un numero entero mayor a cero. 
--          Debe mostrar en consola un n?mero aleatorio entre 1 y el n?mero ingresado.

-- Seleccionar un numero aleatorio en un rango de 1 a 10
SELECT round(dbms_random.VALUE() * (10 - 1)) + 1 aleatorio FROM dual;

-- Creando procedimiento almacenado
CREATE OR REPLACE PROCEDURE get_random_number
	(n1 IN INT)
IS 
	random_number INT;
BEGIN
	SELECT round(dbms_random.VALUE() * (n1 - 1)) + 1 INTO random_number FROM dual;
    DBMS_OUTPUT.PUT_LINE (random_number);
END;

-- Ejecutando procedimiento almacenado
SET SERVEROUTPUT ON;
EXEC get_random_number (10);

-- Eliminando procedimiento
DROP PROCEDURE get_random_number;


-- 6.5.     Crear un procedimiento almacenado con 3 par?metros, el primero (de entrada)
--          es un n?mero entre 1 y 12 que representa un mes del a?o, el segundo par?metro
--          (salida) almacenar? un id de empleado, y el tercer (salida) almacenar? el calculo de ventas. 
--          El procedimiento calcular? las ventas realizadas por cada empleado durante el mes definido en el primer par?metro
--          y retornar? el id del empleado con mayores ventas y el total ventido

-- Creando consulta que calcula ventas por empleado
SELECT E.id, E.nombre, SUM(calculate_bill_total (F.id)) total
FROM EMPLEADO E, FACTURA F 
WHERE E.id = F.id_empleado
    AND (SELECT EXTRACT(MONTH FROM f.fecha) FROM DUAL) = 11
GROUP BY E.id, E.nombre
ORDER BY total DESC
FETCH FIRST 1 ROWS ONLY;

-- Creando procedimiento
CREATE OR REPLACE PROCEDURE BEST_SELLER 
    (id_month IN INT, id_employee OUT INT, employee_sales OUT FLOAT)
IS 
BEGIN
    SELECT E.id, SUM(calculate_bill_total (F.id)) total
    INTO id_employee, employee_sales
    FROM EMPLEADO E, FACTURA F 
    WHERE E.id = F.id_empleado
    GROUP BY E.id, E.nombre
    ORDER BY total DESC
    FETCH FIRST 1 ROWS ONLY;
END;

SET SERVEROUTPUT ON;
DECLARE
    id_employee INT; 
    employee_sales FLOAT;
BEGIN
    BEST_SELLER (11, id_employee, employee_sales);
    DBMS_OUTPUT.PUT_LINE('El empleado con id: ' || id_employee || ', ha generado $' || employee_sales || ' en ganancias');
END;




