-- Universidad de La Laguna
-- Grado en Ingeniería Informática
-- Administración y Diseño de Bases de Datos
-- Práctica 1: Conceptos fundamentales de PostgreSQL
--
-- Este script recoge los comandos empleados durante la práctica.
-- Está pensado para ejecutarse desde psql como usuario con privilegios suficientes.

-- ============================================================
-- 1. Creación de la base de datos
-- ============================================================

CREATE DATABASE biblioteca;

\c biblioteca


-- ============================================================
-- 2. Creación de usuarios y roles
-- ============================================================

CREATE USER admin_biblio WITH PASSWORD 'admin123';

CREATE USER usuario_biblio WITH PASSWORD 'usuario123';

ALTER DATABASE biblioteca OWNER TO admin_biblio;

GRANT ALL PRIVILEGES ON DATABASE biblioteca TO admin_biblio;

CREATE ROLE lectores;

GRANT lectores TO usuario_biblio;

SELECT rolname
FROM pg_roles;

ALTER USER usuario_biblio WITH PASSWORD 'usuario456';


-- ============================================================
-- 3. Creación de tablas
-- ============================================================

CREATE TABLE autores (
    id_autor SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    nacionalidad VARCHAR(100)
);

CREATE TABLE libros (
    id_libro SERIAL PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    anio_publicacion INTEGER,
    id_autor INTEGER NOT NULL,
    FOREIGN KEY (id_autor)
        REFERENCES autores(id_autor)
);

CREATE TABLE prestamos (
    id_prestamo SERIAL PRIMARY KEY,
    id_libro INTEGER NOT NULL,
    fecha_prestamo DATE NOT NULL,
    fecha_devolucion DATE,
    usuario_prestatario VARCHAR(100) NOT NULL,
    FOREIGN KEY (id_libro)
        REFERENCES libros(id_libro)
        ON DELETE CASCADE
);

\dt
\d autores
\d libros
\d prestamos

-- Ahora que las tablas existen, se aplican los permisos de lectura.
GRANT SELECT ON ALL TABLES IN SCHEMA public TO lectores;

REVOKE DELETE ON ALL TABLES IN SCHEMA public FROM usuario_biblio;


-- ============================================================
-- 4. Inserción de datos
-- ============================================================

INSERT INTO autores (nombre, nacionalidad) VALUES
('George Orwell', 'Británica'),
('Gabriel García Márquez', 'Colombiana'),
('Miguel de Cervantes', 'Española'),
('Jane Austen', 'Británica'),
('Franz Kafka', 'Checa');

INSERT INTO libros (titulo, anio_publicacion, id_autor) VALUES
('1984', 1949,
    (SELECT id_autor FROM autores WHERE nombre = 'George Orwell')),
('Rebelión en la granja', 1945,
    (SELECT id_autor FROM autores WHERE nombre = 'George Orwell')),
('Cien años de soledad', 1967,
    (SELECT id_autor FROM autores WHERE nombre = 'Gabriel García Márquez')),
('El amor en los tiempos del cólera', 1985,
    (SELECT id_autor FROM autores WHERE nombre = 'Gabriel García Márquez')),
('Don Quijote de la Mancha', 1605,
    (SELECT id_autor FROM autores WHERE nombre = 'Miguel de Cervantes')),
('Orgullo y prejuicio', 1813,
    (SELECT id_autor FROM autores WHERE nombre = 'Jane Austen')),
('La metamorfosis', 1915,
    (SELECT id_autor FROM autores WHERE nombre = 'Franz Kafka')),
('El proceso', 1925,
    (SELECT id_autor FROM autores WHERE nombre = 'Franz Kafka'));

INSERT INTO prestamos (
    id_libro,
    fecha_prestamo,
    fecha_devolucion,
    usuario_prestatario
) VALUES
(
    (SELECT id_libro FROM libros WHERE titulo = '1984'),
    '2026-09-01',
    '2026-09-15',
    'Ana López'
),
(
    (SELECT id_libro FROM libros WHERE titulo = 'Cien años de soledad'),
    '2026-09-05',
    NULL,
    'Carlos Pérez'
),
(
    (SELECT id_libro FROM libros WHERE titulo = 'Don Quijote de la Mancha'),
    '2026-09-10',
    '2026-09-25',
    'Laura Martín'
),
(
    (SELECT id_libro FROM libros WHERE titulo = 'La metamorfosis'),
    '2026-09-15',
    NULL,
    'Pedro González'
),
(
    (SELECT id_libro FROM libros WHERE titulo = 'Orgullo y prejuicio'),
    '2026-09-20',
    NULL,
    'María Rodríguez'
);

SELECT * FROM autores;
SELECT * FROM libros;
SELECT * FROM prestamos;


-- ============================================================
-- 5. Consultas básicas
-- ============================================================

-- 5.a. Listar todos los libros con su autor correspondiente.
SELECT
    libros.titulo,
    autores.nombre AS autor
FROM libros
JOIN autores
    ON libros.id_autor = autores.id_autor;

-- 5.b. Mostrar los préstamos que aún no tienen fecha de devolución.
SELECT *
FROM prestamos
WHERE fecha_devolucion IS NULL;

-- 5.c. Obtener los autores que tienen más de un libro registrado.
SELECT
    autores.nombre,
    COUNT(libros.id_libro) AS numero_libros
FROM autores
JOIN libros
    ON autores.id_autor = libros.id_autor
GROUP BY autores.id_autor, autores.nombre
HAVING COUNT(libros.id_libro) > 1;


-- ============================================================
-- 6. Consultas con agregación
-- ============================================================

-- 6.a. Calcular el número total de préstamos realizados.
SELECT COUNT(*) AS total_prestamos
FROM prestamos;

-- 6.b. Obtener el número de libros prestados por cada usuario.
SELECT
    usuario_prestatario,
    COUNT(*) AS libros_prestados
FROM prestamos
GROUP BY usuario_prestatario;


-- ============================================================
-- 7. Modificación de datos
-- ============================================================

-- 7.a. Actualizar la fecha de devolución de un préstamo pendiente.
SELECT *
FROM prestamos
WHERE usuario_prestatario = 'Carlos Pérez';

UPDATE prestamos
SET fecha_devolucion = '2026-09-29'
WHERE usuario_prestatario = 'Carlos Pérez'
  AND fecha_devolucion IS NULL;

SELECT *
FROM prestamos
WHERE usuario_prestatario = 'Carlos Pérez';

-- 7.b. Eliminar un libro y comprobar ON DELETE CASCADE.
SELECT *
FROM libros
WHERE titulo = 'La metamorfosis';

SELECT *
FROM prestamos
WHERE id_libro = (
    SELECT id_libro
    FROM libros
    WHERE titulo = 'La metamorfosis'
);

DELETE FROM libros
WHERE titulo = 'La metamorfosis';

SELECT *
FROM libros
WHERE titulo = 'La metamorfosis';

-- En la ejecución realizada, La metamorfosis tenía id_libro = 8.
SELECT *
FROM prestamos
WHERE id_libro = 8;


-- ============================================================
-- 8. Creación de vistas
-- ============================================================

CREATE VIEW vista_libros_prestados AS
SELECT
    libros.titulo,
    autores.nombre AS autor,
    prestamos.usuario_prestatario AS prestatario
FROM prestamos
JOIN libros
    ON prestamos.id_libro = libros.id_libro
JOIN autores
    ON libros.id_autor = autores.id_autor;

SELECT *
FROM vista_libros_prestados;

REVOKE ALL ON vista_libros_prestados FROM PUBLIC;

GRANT SELECT ON vista_libros_prestados TO usuario_biblio;

\dp vista_libros_prestados


-- ============================================================
-- 9. Funciones y consultas avanzadas
-- ============================================================

-- 9.a. Función que recibe el nombre de un autor y devuelve sus libros.
CREATE OR REPLACE FUNCTION libros_por_autor(p_nombre TEXT)
RETURNS TABLE (
    id_libro INTEGER,
    titulo VARCHAR,
    anio_publicacion INTEGER
)
LANGUAGE SQL
AS $$
    SELECT
        l.id_libro,
        l.titulo,
        l.anio_publicacion
    FROM libros l
    JOIN autores a
        ON l.id_autor = a.id_autor
    WHERE a.nombre = p_nombre;
$$;

SELECT *
FROM libros_por_autor('George Orwell');

-- 9.b. Tres libros más prestados.
SELECT
    libros.titulo,
    COUNT(prestamos.id_prestamo) AS numero_prestamos
FROM libros
JOIN prestamos
    ON libros.id_libro = prestamos.id_libro
GROUP BY libros.id_libro, libros.titulo
ORDER BY numero_prestamos DESC, libros.titulo
LIMIT 3;


-- ============================================================
-- 10. Exportación e importación de datos
-- ============================================================

-- 10.a. Exportar libros a CSV.
-- Durante la práctica se utilizó /tmp porque psql se ejecutaba como
-- el usuario Linux postgres y no podía escribir directamente en /home/usuario.
\copy libros TO '/tmp/libros.csv' WITH (FORMAT CSV, HEADER true)

\! cat /tmp/libros.csv

-- Fuera de psql se ejecutó:
-- cp /tmp/libros.csv ~/libros.csv

-- 10.b. Importar autores adicionales desde CSV.
-- El archivo externo se creó fuera de psql con:
-- printf 'nombre,nacionalidad\nJulio Cortázar,Argentina\nVirginia Woolf,Británica\n' > /tmp/autores_adicionales.csv
-- cat /tmp/autores_adicionales.csv

\copy autores(nombre, nacionalidad) FROM '/tmp/autores_adicionales.csv' WITH (FORMAT CSV, HEADER true)

SELECT * FROM autores;
