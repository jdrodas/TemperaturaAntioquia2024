-- Scripts de clase - Abril 30 de 2025
-- Curso de Tópicos Avanzados de base de datos - UPB 202510
-- Juan Dario Rodas - juand.rodasm@upb.edu.co

-- Proyecto: Analisis de Temperatura en Antioquia para el año 2025
-- Motor de Base de datos: PostgreSQL 17.x
-- Version: Relacional

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
