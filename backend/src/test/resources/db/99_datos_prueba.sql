-- Catálogos mínimos para los tests de integración. Corre último: después del
-- esquema y de las migraciones (que ya cargan los ciclos productivos).
-- Sin datos reales: nada de animales, personas ni contraseñas.

set search_path to public;

insert into establecimiento (id_establecimiento, cuig, nombre, es_propio, activo)
overriding system value values
    (10, 'PC269', 'Santa Ana', true, true);

-- VISUAL tiene que ser el id 1: el trigger chk_identificacion_visual() lo compara con 1
insert into tipo_identificacion (id_tipo_ident, codigo, descripcion, ambito, es_oficial)
overriding system value values
    (1, 'VISUAL', 'Caravana visual', 'ESTABLECIMIENTO', false),
    (2, 'RFID', 'Boton RFID', 'NACIONAL', true),
    (3, 'FUEGO', 'Marca a fuego', 'ESTABLECIMIENTO', false),
    (4, 'SENASA', 'Numero SENASA (15 digitos)', 'NACIONAL', true),
    (5, 'ADICIONAL', 'Numero adicional / interno', 'ESTABLECIMIENTO', false);

insert into categoria (id_categoria, codigo, nombre, sexo, orden, activo)
overriding system value values
    (6, 'TERNERA', 'Ternera', 'H', 10, true),
    (1, 'TERNERO', 'Ternero', 'M', 90, true),
    (4, 'TORITO', 'Torito', 'M', 100, true);
