-- Scripts de clase - Abril 30 de 2025
-- Curso de Tópicos Avanzados de base de datos - UPB 202510
-- Juan Dario Rodas - juand.rodasm@upb.edu.co

-- Proyecto: Analisis de Temperatura en Antioquia para el año 2025
-- Motor de Base de datos: PostgreSQL 17.x
-- Version: Relacional

-- ***********************************
-- Abastecimiento de imagen en Docker
-- ***********************************
 
-- Descargar la imagen
docker pull postgres:latest

-- Crear el contenedor
docker run --name postgres-tadb -e POSTGRES_PASSWORD=unaClav3 -d -p 5432:5432 postgres:latest

-- ****************************************
-- Creación de base de datos y usuarios
-- ****************************************

-- Con usuario Root:

-- crear el esquema la base de datos
create database analisistemperatura_db;

-- Conectarse a la base de datos
\c analisistemperatura_db;

-- crear el usuario con el que se realizarán las acciones
create user analisistemperatura_usr with encrypted password 'unaClav3';

-- asignación de privilegios para el usuario
-- ==========================================

-- Privilegios para establecer conexiones
grant connect on database analisistemperatura_db to analisistemperatura_usr;

-- privilegios para crear tablas temporales
grant temporary on database analisistemperatura_db to analisistemperatura_usr;

-- Privilegios de uso en el esquema
grant usage on schema public to analisistemperatura_usr;

-- privilegios para crear objetos
grant create on schema public to analisistemperatura_usr;

-- Privilegios sobre tablas existentes
grant select, insert, update, delete, trigger on all tables in schema public to analisistemperatura_usr;

-- privilegios sobre secuencias existentes
grant usage, select on all sequences in schema public to analisistemperatura_usr;

-- privilegios sobre funciones existentes
grant execute on all functions in schema public to analisistemperatura_usr;

-- privilegios sobre procedimientos existentes
grant execute on all procedures in schema public to analisistemperatura_usr;

-- privilegios sobre futuras tablas y secuencias
alter default privileges in schema public grant select, insert, update, delete, trigger on tables to analisistemperatura_usr;

alter default privileges in schema public grant select, usage on sequences to analisistemperatura_usr;

-- privilegios sobre futuras funciones y procedimientos
alter default privileges in schema public grant execute on routines to analisistemperatura_usr;

--Privilegios de consulta sobre el esquema information_schema
grant usage on schema information_schema to analisistemperatura_usr;

-- =========================================
-- Para validar los privilegios sobre tablas
-- =========================================
SELECT grantee, table_schema, table_name, privilege_type
FROM information_schema.table_privileges
WHERE grantee = 'analisistemperatura_usr';

-- Para validar los privilegios sobre los esquemas
SELECT 
    n.nspname AS schema_name,
    CASE WHEN has_schema_privilege('analisistemperatura_usr', n.oid, 'CREATE') THEN 'CREATE' ELSE NULL END AS create_privilege,
    CASE WHEN has_schema_privilege('analisistemperatura_usr', n.oid, 'USAGE') THEN 'USAGE' ELSE NULL END AS usage_privilege
FROM 
    pg_catalog.pg_namespace n
WHERE 
    n.nspname NOT LIKE 'pg_%'
    AND n.nspname != 'information_schema';


-- Para validar los atributos del usuario
SELECT rolname, rolsuper, rolinherit, rolcreaterole, rolcreatedb, rolcanlogin
FROM pg_roles
WHERE rolname = 'analisistemperatura_usr';

-- Para validar privilegios a nivel de base de datos
SELECT grantee, privilege_type
FROM information_schema.usage_privileges
WHERE object_type = 'DATABASE' AND object_name = 'analisistemperatura_db';

-- Para validar privilegios sobre rutinas
SELECT grantee, routine_schema, routine_name, privilege_type
FROM information_schema.routine_privileges
WHERE grantee = 'analisistemperatura_usr';

-- Para validar privilegios sobre secuencias
select grantee, object_schema, object_name, 
object_type, privilege_type 
FROM information_schema.usage_privileges
WHERE grantee = 'analisistemperatura_usr'
AND object_type = 'SEQUENCE';

-- =====================================
-- Cargue de datos iniciales 
-- =====================================

-- Tabla Provisional
create table datos_provisionales (
CodigoEstacion text,
CodigoSensor text,
FechaObservacion text,
ValorObservado float,
NombreEstacion text,
Departamento text,
Municipio text,
ZonaHidrografica text,
Latitud float,
Longitud float, 
DescripcionSensor text,
UnidadMedida text
);

-- =====================================
-- Creación de tablas del modelo
-- =====================================

-- Tabla: Departamentos
create table departamentos
(
    id              integer generated always as identity constraint departamentos_pk primary key,
    nombre          varchar(100) not null constraint nombre_departamento_uk unique
);

comment on table departamentos is 'Departamentos de Colombia';
comment on column departamentos.id is 'Id del departamento';
comment on column departamentos.nombre is 'Nombre del departamento';


-- Tabla: zonas
create table zonas
(
    id              integer generated always as identity constraint zonas_pk primary key,
    nombre          varchar(100) not null constraint nombre_zona_uk unique
);

comment on table zonas is 'Zonas Hidrográficas de Colombia';
comment on column zonas.id is 'Id de la zona';
comment on column zonas.nombre is 'Nombre de la zona';

-- Tabla: Municipios
create table municipios
(
    id              integer generated always as identity constraint municipios_pk primary key,
    nombre          varchar(100) not null,
    departamento_id integer not null constraint municipios_departamentos_fk references departamentos,
    zona_id         integer not null constraint municipios_zonas_fk references zonas (id),
    constraint nombre_municipio_en_departamento_uk unique (nombre, departamento_id)
);

comment on table municipios is 'Municipios de Colombia ubicados en departamentos y zonas hidrográficas';
comment on column municipios.id is 'Id del municipio';
comment on column municipios.nombre is 'nombre del municipio';
comment on column municipios.departamento_id is 'Id del departamento al que pertenece el municipio';
comment on column municipios.zona_id is 'Id de la zona hidrográfica donde está ubicado el municipio';

-- Tabla: Estaciones
create table estaciones
(
    id              varchar(10) not null constraint estaciones_pk primary key,
    nombre          varchar(100) not null,
    municipio_id    integer not null constraint estaciones_municipios_fk references municipios,
    latitud         float not null,
    longitud        float not null,
    constraint ubicacion_estacion_uk unique (latitud,longitud)
);

comment on table estaciones is 'Estaciones de Medición de Temperatura';
comment on column estaciones.id is 'Id de la estación';
comment on column estaciones.nombre is 'nombre de la estación';
comment on column estaciones.municipio_id is 'Id del municipio donde está la estación';
comment on column estaciones.latitud is 'Latitud donde está ubicada la estación';
comment on column estaciones.longitud is 'Longitud donde está ubicada la estación';

-- Tabla: Sensores
create table sensores
(
    id              varchar(4) not null constraint sensores_pk primary key,
    nombre          varchar(100) not null constraint nombre_sensor_uk unique
);

comment on table sensores is 'Sensores de temperatura utilizados para las observaciones de temperatura';
comment on column sensores.id is 'Id del sensor';
comment on column sensores.nombre is 'Nombre del sensor';

-- Tabla: Observaciones
create table observaciones
(
    id              integer generated always as identity constraint observaciones_pk primary key,
    estacion_id     varchar(10) not null constraint observaciones_estaciones_fk references estaciones,
    sensor_id       varchar(4) not null constraint observaciones_sensores_fk references sensores,
    valor           float not null,
    unidad_medida   varchar(4) not null,
    fecha           timestamp without time zone not null 
);

comment on table observaciones is 'Observaciones de temperatura realizadas por las estaciones';
comment on column observaciones.id is 'Id de la observación';
comment on column observaciones.estacion_id is 'Id de la estación que hizo la observación';
comment on column observaciones.sensor_id is 'Id del sensor con el que se hizo la observación';
comment on column observaciones.valor is 'valor de temperatura obtenido en la observación';
comment on column observaciones.unidad_medida is 'Unidad de medida de la temperatura observada';
comment on column observaciones.fecha is 'fecha en la que se realizó la la observación de temperatura';

-- ===========================================
-- Cargue de datos desde la tabla provisional 
-- ===========================================

-- Departamentos
insert into departamentos (nombre)
select distinct departamento from datos_provisionales;

-- Devolver el Id generado a la tabla provisional
alter table datos_provisionales add column departamento_id int;

update datos_provisionales
set departamento_id =
    (select distinct id from departamentos where lower(nombre) = lower(departamento))
where departamento_id is null;

-- Zonas 
insert into zonas (nombre)
select distinct ZonaHidrografica from datos_provisionales;

-- Devolver el Id generado a la tabla provisional
alter table datos_provisionales add column zona_id int;

update datos_provisionales
set zona_id =
    (select distinct id from zonas where lower(nombre) = lower(ZonaHidrografica))
where zona_id is null;

-- Municipios
insert into municipios (nombre, departamento_id, zona_id)
select distinct municipio, departamento_id, zona_id
from datos_provisionales
order by zona_id, municipio;

-- Devolver el Id generado a la tabla provisional
alter table datos_provisionales add column municipio_id int;

update datos_provisionales dp
set municipio_id =
    (select distinct id
     from municipios m
     where lower(nombre) = lower(dp.municipio)
     and m.zona_id = dp.zona_id
     and m.departamento_id = dp.departamento_id)
where municipio_id is null;

-- Estaciones

-- Ejecutamos ajuste con criterio para resolver problema de calidad de datos
-- para las estaciones ubicadas en el aeropuerto Enrique Olaya Herrera
update datos_provisionales
set
    latitud = 6.2246389,
    longitud = -75.588225,
    nombreestacion = 'AEROPUERTO OLAYA HERRERA'
where upper(nombreestacion) like '%OLAYA HERRERA%';

update datos_provisionales
set
    latitud = 6.1686111,
    longitud = -75.426111111,
    nombreestacion = 'AEROPUERTO J.M. CORDOVA'
where upper(nombreestacion) like 'AEROPUERTO%CORDOVA';

insert into estaciones (id, nombre, municipio_id, latitud, longitud)
select distinct
    codigoestacion,
    nombreestacion,
    municipio_id,
    latitud,
    longitud
from datos_provisionales;

-- Sensores
insert into sensores (id, nombre)
select distinct codigosensor, descripcionsensor
from datos_provisionales;

-- Observaciones
insert into observaciones (estacion_id, sensor_id, valor, unidad_medida, fecha)
select distinct
    codigoestacion,
    codigosensor,
    valorobservado,
    unidadmedida,
    to_timestamp(fechaobservacion::text, 'MM/DD/YYYY HH:MI:SS AM')
from datos_provisionales;

-- ===========================================
-- Creación de Vistas
-- ===========================================
-- vista: v_ubicacion_observacion
create or replace view v_ubicacion_observacion as
(
    select distinct
        o.id observacion_id,
        o.estacion_id,
        e.nombre estacion_nombre,
        e.municipio_id,
        m.nombre municipio_nombre,
        m.zona_id,
        zh.nombre zona_nombre,
        m.departamento_id,
        d.nombre departamento_nombre
    from observaciones o
        inner join estaciones e on o.estacion_id = e.id
        inner join municipios m on e.municipio_id = m.id
        inner join zonas zh on m.zona_id = zh.id
        inner join departamentos d on m.departamento_id = d.id
);

-- vista: v_ubicacion_estacion
create or replace view v_ubicacion_estacion as
(
    select distinct
        e.id estacion_id,
        e.nombre estacion_nombre,
        e.municipio_id,
        m.nombre municipio_nombre,
        m.zona_id,
        zh.nombre zona_nombre,
        m.departamento_id,
        d.nombre departamento_nombre
    from estaciones e
        inner join municipios m on e.municipio_id = m.id
        inner join zonas zh on m.zona_id = zh.id
        inner join departamentos d on m.departamento_id = d.id
);



-- ===========================================
-- ZONA DE PELIGRO - BORRADO DE OBJETOS
-- ===========================================

-- Borrado de tablas

drop table observaciones;
drop table sensores;
drop table estaciones;
drop table municipios;
drop table zonas_hidrograficas;
drop table departamentos;
drop table datos_provisionales;